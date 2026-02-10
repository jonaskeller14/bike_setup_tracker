const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");

/**
 * firestore-admin allows this backend to communicate with your Firestore database.
 * - admin.initializeApp(): Connects the backend to your project.
 * - db: The 'database' object we use to read/write tokens and activities.
 */
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

// GLOBAL CONFIG: Set to europe-west3 as requested. maxInstances = 1 (Free Tier)
setGlobalOptions({ maxInstances: 1, region: "europe-west3" });

/**
 * STRATEGY: OAuth Token Exchange
 * Strava redirects the user here after they click 'Authorize' in the app.
 * We get a 'code' and a 'state' (which is our app-specific userId).
 */
exports.exchangeToken = onRequest(
  { secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"] },
  async (req, res) => {
    const code = req.query.code;
    const userId = req.query.state; // We passed the app's internal userId in 'state'

    if (!code || !userId) {
      logger.error("MISSING_CODE_OR_USERID", { code, userId });
      return res.status(400).send("Missing code or user identification");
    }

    try {
      // 1. Exchange the temporary 'code' for a permanent 'access_token'
      const response = await fetch("https://www.strava.com/api/v3/oauth/token", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: process.env.STRAVA_CLIENT_ID,
          client_secret: process.env.STRAVA_CLIENT_SECRET,
          code: code,
          grant_type: "authorization_code",
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(`Strava Token Exchange failed: ${JSON.stringify(data)}`);
      }

      // 2. Store tokens securely in Firestore
      // We index by app-specific userId so the app can easily find its tokens
      await db.collection("users").doc(userId).set({
        strava_auth: {
          access_token: data.access_token,
          refresh_token: data.refresh_token,
          expires_at: data.expires_at,
          athlete_id: data.athlete.id,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        strava_connected: true
      }, { merge: true });

      logger.info("STRAVA_AUTH_SUCCESSFUL", { userId });

      // 3. Redirect back to the App using Deep Linking
      const redirectUrl = `bike-setup-tracker://strava-auth?success=true`;
      return res.redirect(redirectUrl);

    } catch (error) {
      logger.error("AUTH_ERROR", error);
      return res.redirect(`bike-setup-tracker://strava-auth?success=false&error=auth_failed`);
    }
  }
);

/**
 * Helper: Refreshes Strava access token if expired.
 */
async function getValidAccessToken(userId) {
  const userRef = db.collection("users").doc(userId);
  const doc = await userRef.get();
  if (!doc.exists) throw new Error("User not found");

  const auth = doc.data().strava_auth;
  const now = Math.floor(Date.now() / 1000);

  if (auth.expires_at < now + 60) {
    logger.info("REFRESHING_TOKEN", { userId });
    const response = await fetch("https://www.strava.com/api/v3/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: process.env.STRAVA_CLIENT_ID,
        client_secret: process.env.STRAVA_CLIENT_SECRET,
        refresh_token: auth.refresh_token,
        grant_type: "refresh_token",
      }),
    });
    const data = await response.json();
    if (!response.ok) throw new Error("Refresh failed");

    const newAuth = {
      ...auth,
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: data.expires_at,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    await userRef.update({ strava_auth: newAuth });
    return data.access_token;
  }
  return auth.access_token;
}

/**
 * STRATEGY: Deauthorization
 * Wipes user's Strava data from Firestore and tells Strava to revoke access.
 */
exports.deauthorizeUser = onRequest(
  async (req, res) => {
    const userId = req.query.state; // We expect the userId in query params

    if (!userId) {
      return res.status(400).send("Missing user identification");
    }

    try {
      const userRef = db.collection("users").doc(userId);
      const doc = await userRef.get();
      
      if (!doc.exists || !doc.data().strava_auth) {
        return res.status(200).send("Already disconnected");
      }

      const accessToken = doc.data().strava_auth.access_token;

      // 1. Tell Strava to revoke access
      await fetch("https://www.strava.com/oauth/deauthorize", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ access_token: accessToken }),
      });

      // 2. Clean up Firestore
      // Delete activities subcollection
      const activitiesSnapshot = await userRef.collection("activities").get();
      const batch = db.batch();
      activitiesSnapshot.forEach(doc => batch.delete(doc.ref));
      
      // Update user doc to remove Strava fields
      batch.update(userRef, {
        strava_auth: admin.firestore.FieldValue.delete(),
        strava_connected: false,
        strava_deauthorized_at: admin.firestore.FieldValue.serverTimestamp()
      });

      await batch.commit();

      logger.info("USER_DEAUTHORIZED", { userId });
      return res.status(200).send("DEAUTHORIZED_SUCCESSFUL");

    } catch (error) {
      logger.error("DEAUTHORIZE_ERROR", error);
      return res.status(500).send("Deauthorization failed");
    }
  }
);

/**
 * STRATEGY: Webhook Listener
 * Strava calls this endpoint whenever an activity is created, updated, or deleted.
 * Calls FCM and fetches details when a new activity is created.
 */
exports.stravaWebhook = onRequest(
  { secrets: ["STRAVA_VERIFY_TOKEN", "STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"] }, 
  async (req, res) => {
    
    // 1. HANDSHAKE (GET): Strava verifies this endpoint is alive.
    if (req.method === "GET") {
      const mode = req.query["hub.mode"];
      const token = req.query["hub.verify_token"];
      const challenge = req.query["hub.challenge"];

      if (mode === "subscribe" && token === process.env.STRAVA_VERIFY_TOKEN) {
        logger.info("WEBHOOK_VERIFIED");
        return res.status(200).json({ "hub.challenge": challenge });
      }
      return res.status(403).send("Verification failed");
    }

    // 2. EVENT HANDLING (POST): Real activity updates from Strava.
    if (req.method === "POST") {
      const event = req.body;
      logger.info("Strava Event received:", event);
      
      const objectType = event.object_type; // e.g. 'activity'
      const aspectType = event.aspect_type; // 'create', 'update', or 'delete'
      const activityId = event.object_id;
      const athleteId = event.owner_id;

      if (objectType === 'activity') {
        if (aspectType === 'create') {
          // TODO: 1. Find userId by athleteId in Firestore
          // TODO: 2. Fetch full activity details from Strava API
          // TODO: 3. Save to Firestore under the user's activities
          logger.info(`NEW ACTIVITY: ${activityId} for athlete ${athleteId}`);

          try {
            // Find user by athleteId
            const usersSnapshot = await db.collection("users")
              .where("strava_auth.athlete_id", "==", athleteId)
              .limit(1)
              .get();

            if (usersSnapshot.empty) {
              logger.error("ATHLETE_NOT_LINKED", { athleteId });
              return res.status(200).send("NOT_LINKED");
            }

            const userId = usersSnapshot.docs[0].id;
            const userToken = await getValidAccessToken(userId);

            // Fetch full activity details
            const response = await fetch(`https://www.strava.com/api/v3/activities/${activityId}`, {
              headers: { "Authorization": `Bearer ${userToken}` }
            });
            const activity = await response.json();

            if (!response.ok) throw new Error("Activity fetch failed");

            // Save "clean" data for the app
            const cleanActivity = {
              id: activity.id,
              name: activity.name,
              distance: activity.distance,
              moving_time: activity.moving_time,
              total_elevation_gain: activity.total_elevation_gain,
              type: activity.type,
              start_date: activity.start_date,
              synced_at: admin.firestore.FieldValue.serverTimestamp(),
            };

            await db.collection("users").doc(userId)
              .collection("activities").doc(String(activityId)).set(cleanActivity);

            // Send FCM Notification to wake up the phone
            const fcmToken = usersSnapshot.docs[0].data().fcm_token;
            if (fcmToken) {
              await admin.messaging().send({
                token: fcmToken,
                notification: {
                  title: "New Activity!",
                  body: `We imported your ride: ${activity.name}`,
                },
                data: {
                  type: "strava_sync",
                  activityId: String(activityId),
                }
              });
            }

            logger.info(`SUCCESSFULLY_SYNCED: ${activityId} for user ${userId}`);

          } catch (error) {
            logger.error("WEBHOOK_PROCESSING_FAILED", error);
          }
        } 
        else if (aspectType === 'update') {
          // This happens when a user renames an activity or changes privacy settings
          // TODO: 1. Find existing activity in Firestore
          // TODO: 2. Update specific fields (from event.updates) or re-fetch entirely
          logger.info(`UPDATED ACTIVITY: ${activityId}. Changes:`, event.updates);
        } 
        else if (aspectType === 'delete') {
          // TODO: 1. Remove activity from Firestore to keep app in sync
          logger.info(`DELETED ACTIVITY: ${activityId}`);
        }
      } 
      else if (objectType === 'athlete') {
        if (aspectType === 'update' && event.updates && event.updates.authorized === "false") {
          logger.info(`ATHLETE_DEAUTHORIZED_ON_STRAVA: ${athleteId}`);
          try {
            // Find user by athleteId
            const usersSnapshot = await db.collection("users")
              .where("strava_auth.athlete_id", "==", athleteId)
              .limit(1)
              .get();

            if (!usersSnapshot.empty) {
              const userId = usersSnapshot.docs[0].id;
              const userRef = db.collection("users").doc(userId);
              
              const activitiesSnapshot = await userRef.collection("activities").get();
              const batch = db.batch();
              activitiesSnapshot.forEach(doc => batch.delete(doc.ref));
              
              batch.update(userRef, {
                strava_auth: admin.firestore.FieldValue.delete(),
                strava_connected: false,
                strava_deauthorized_on_strava_at: admin.firestore.FieldValue.serverTimestamp()
              });

              await batch.commit();
              logger.info(`CLEANUP_SUCCESS_FOR_WEBHOOK_DEAUTH: ${userId}`);
            }
          } catch (error) {
            logger.error("CLEANUP_FAILED_FOR_WEBHOOK_DEAUTH", error);
          }
        }
      }
      
      return res.status(200).send("EVENT_RECEIVED");
    }

    res.status(405).send("Method Not Allowed");
  }
);