const { onRequest } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");
const { getValidAccessToken, saveActivityToBatch, checkStravaResponse, isBikeActivity } = require("./common");

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
        case 'activity': {
          // 1. Find ALL users linked to this athlete
          const usersSnapshot = await db.collection("users")
            .where("strava_auth.athlete_id", "==", athleteId)
            .get();

          if (usersSnapshot.empty) {
            logger.info("EVENT_RECEIVED_BUT_NO_USER_FOUND", { athleteId });
            return res.status(200).send("EVENT_RECEIVED_NO_USER");
          }

          // 2. Handle based on aspect
          switch (aspectType) {
            case 'create':
              logger.info(`CREATE ACTIVITY: ${activityId} for athlete ${athleteId}`);
              try {
                // Fetch activity details ONCE using the first user's token
                const firstUserId = usersSnapshot.docs[0].id;
                const userToken = await getValidAccessToken(firstUserId);
                const response = await fetch(`https://www.strava.com/api/v3/activities/${activityId}`, {
                  headers: { "Authorization": `Bearer ${userToken}` }
                });
                checkStravaResponse(response, "Strava Activity API");
                const activity = await response.json();

                // Save to EVERY user's batches (delegates bike-only filtering and conversion logic)
                for (const userDoc of usersSnapshot.docs) {
                  const userId = userDoc.id;
                  await saveActivityToBatch(activity, userId);

                  // Send FCM Notification
                  const fcmToken = userDoc.data().fcm_token;
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
                    }).catch(err => logger.error("FCM_SEND_FAILED", { userId, error: err.message }));
                  }
                }
                logger.info(`SUCCESSFULLY_PROCESSED_CREATE: ${activityId} for ${usersSnapshot.size} users`);
              } catch (error) {
                logger.error("WEBHOOK_CREATE_FAILED", { activityId, error: error.message });
              }
              break;

            case 'update':
              logger.info(`UPDATE ACTIVITY: ${activityId} for athlete ${athleteId}`);
              try {
                const firstUserId = usersSnapshot.docs[0].id;
                const userToken = await getValidAccessToken(firstUserId);
                const response = await fetch(`https://www.strava.com/api/v3/activities/${activityId}`, {
                  headers: { "Authorization": `Bearer ${userToken}` }
                });
                checkStravaResponse(response, "Strava Activity API");
                const activity = await response.json();

                for (const userDoc of usersSnapshot.docs) {
                  await saveActivityToBatch(activity, userDoc.id);
                }
                logger.info(`SUCCESSFULLY_PROCESSED_UPDATE: ${activityId} for ${usersSnapshot.size} users`);
              } catch (error) {
                logger.error("WEBHOOK_UPDATE_FAILED", { activityId, error: error.message });
              }
              break;

            case 'delete':
              logger.info(`DELETE ACTIVITY: ${activityId} for athlete ${athleteId}`);
              try {
                for (const userDoc of usersSnapshot.docs) {
                  await saveActivityToBatch({ id: activityId, isDeleted: true }, userDoc.id);
                }
                logger.info(`SUCCESSFULLY_DELETED: ${activityId} for ${usersSnapshot.size} users`);
              } catch (error) {
                logger.error("WEBHOOK_DELETE_FAILED", { activityId, error: error.message });
              }
              break;

            default:
              logger.info(`UNKNOWN_ACTIVITY_ASPECT: ${aspectType}`);
              break;
          }
          break;
        }

        case 'athlete':
          if (aspectType === 'update' && event.updates && event.updates.authorized === "false") {
            logger.info(`ATHLETE_DEAUTHORIZED_ON_STRAVA: ${athleteId}`);
            try {
              const usersSnapshot = await db.collection("users")
                .where("strava_auth.athlete_id", "==", athleteId)
                .get();

              for (const userDoc of usersSnapshot.docs) {
                const userId = userDoc.id;
                const userRef = userDoc.ref;
                
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
