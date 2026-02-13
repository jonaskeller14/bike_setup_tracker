const { onRequest } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");

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
