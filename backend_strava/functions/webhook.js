const { onRequest } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");
const { getValidAccessToken, saveActivityToBatch } = require("./common");

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

      switch (objectType) {
        case 'activity':
          switch (aspectType) {
            case 'create':
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
                if (activity.errors) throw new Error(`Activity fetch errors: ${JSON.stringify(activity.errors)}`);

                // Save to Firestore using shared batch helper
                await saveActivityToBatch(activity, userId);

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
              break;

            case 'update':
              // This happens when a user renames an activity in Strava
              logger.info(`UPDATED ACTIVITY: ${activityId} for athlete ${athleteId}`);
              
              try {
                const usersSnapshot = await db.collection("users")
                  .where("strava_auth.athlete_id", "==", athleteId)
                  .limit(1)
                  .get();

                if (!usersSnapshot.empty) {
                  const userId = usersSnapshot.docs[0].id;
                  const userToken = await getValidAccessToken(userId);

                  // Fetch full activity details (Strava webhooks don't send all data, just what changed)
                  const response = await fetch(`https://www.strava.com/api/v3/activities/${activityId}`, {
                    headers: { "Authorization": `Bearer ${userToken}` }
                  });
                  const activity = await response.json();
                  
                  if (response.ok) {
                    await saveActivityToBatch(activity, userId);
                    logger.info(`SUCCESSFULLY_UPDATED_BATCH: ${activityId}`);
                  }
                }
              } catch (error) {
                logger.error("WEBHOOK_UPDATE_FAILED", error);
              }
              break;

            case 'delete':
              logger.info(`DELETED ACTIVITY: ${activityId} for athlete ${athleteId}`);
              try {
                const usersSnapshot = await db.collection("users")
                  .where("strava_auth.athlete_id", "==", athleteId)
                  .limit(1)
                  .get();

                if (!usersSnapshot.empty) {
                  const userId = usersSnapshot.docs[0].id;
                  await saveActivityToBatch({ id: activityId, isDeleted: true }, userId);
                  logger.info(`SUCCESSFULLY_DELETED_BATCH: ${activityId}`);
                }
              } catch (error) {
                logger.error("WEBHOOK_DELETE_FAILED", error);
              }
              break;
              
            default:
              logger.info(`UNKNOWN_ACTIVITY_ASPECT: ${aspectType}`);
              break;
          }
          break;

        case 'athlete':
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
                
                // Clean up activities (Batches)
                const batchesSnapshot = await userRef.collection("activity_batches").get();
                const batch = db.batch();
                batchesSnapshot.forEach(doc => batch.delete(doc.ref));
                
                batch.update(userRef, {
                  strava_auth: admin.firestore.FieldValue.delete(),
                  strava_connected: false,
                  strava_deauthorized_on_strava_at: admin.firestore.FieldValue.serverTimestamp()
                });

                await batch.commit();
                logger.info(`CLEANUP_SUCCESS_FOR_WEBHOOK_DEAUTH: ${userId}`);
              } else {
                logger.warn(`Deauth webhook received for athlete ${athleteId} but no matching user found.`);
              }
            } catch (error) {
              logger.error("CLEANUP_FAILED_FOR_WEBHOOK_DEAUTH", error);
            }
          }
          break;

        default:
          logger.info(`UNKNOWN_OBJECT_TYPE: ${objectType}`);
          break;
      }
      
      return res.status(200).send("EVENT_RECEIVED");
    }

    return res.status(405).send("Method Not Allowed");
  }
);
