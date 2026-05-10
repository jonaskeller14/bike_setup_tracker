const { onRequest } = require("firebase-functions/v2/https");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFunctions } = require("firebase-admin/functions");
const { db, logger, admin } = require("./firebase");
const { getValidAccessToken, saveActivityToBatch, checkStravaResponse, isBikeActivity, getTTLTimestamp } = require("./common");

/**
 * STRATEGY: Webhook Listener
 * Receives the event, checks for duplicates, and enqueues a background task.
 * This keeps the response time < 100ms and prevents Strava from retrying.
 */
exports.stravaWebhook = onRequest(
  { secrets: ["STRAVA_VERIFY_TOKEN"] }, 
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

    // 2. EVENT HANDLING (POST): Enqueue to background worker
    if (req.method === "POST") {
      const event = req.body;
      const activityId = event.object_id;
      const athleteId = event.owner_id;
      const aspectType = event.aspect_type;
      const eventTime = event.event_time;

      // NATIVE IDEMPOTENCY: Cloud Tasks avoids duplicates automatically if we provide a taskName.
      // Task names expire after ~1 hour, which is perfect for catching webhook retries.
      const taskName = `${athleteId}_${activityId}_${aspectType}_${eventTime || 'notime'}`;
      
      // Use the fully qualified resource name to ensure the SDK finds the 2nd gen queue in europe-west3
      const queue = getFunctions().taskQueue("projects/bike-setup-tracker-strava/locations/europe-west3/functions/webhookWorker");
      
      try {
        await queue.enqueue({ event }, { taskName });
        logger.info("EVENT_ENQUEUED", { taskName, queue: "stravaSyncWorker" });
      } catch (e) {
        // Error code 6 is ALREADY_EXISTS in Cloud Tasks
        if (e.code === 6 || e.message?.includes("ALREADY_EXISTS")) {
          logger.info("DUPLICATE_EVENT_REJECTED_BY_QUEUE", { taskName });
          return res.status(200).send("EVENT_ALREADY_QUEUED");
        }
        logger.error("ENQUEUE_FAILED", e);
        throw e;
      }

      return res.status(200).send("EVENT_RECEIVED");
    }

    return res.status(405).send("Method Not Allowed");
  }
);

/**
 * STRATEGY: Background Worker for Webhook Events
 * Handles fetching, syncing, and notifications.
 */
exports.webhookWorker = onTaskDispatched(
  {
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 60,
    },
    rateLimits: {
      maxConcurrentDispatches: 5,
    },
    region: "europe-west3",
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  async (req) => {
    const { event } = req.data;
    const objectType = event.object_type; 
    const aspectType = event.aspect_type;
    const activityId = event.object_id;
    const athleteId = event.owner_id;

    logger.info("WORKER_PROCESSING_EVENT", { activityId, aspectType });

    try {
      if (objectType === 'activity') {
        // 1. Find ALL users linked to this athlete
        const usersSnapshot = await db.collection("users")
          .where("strava_auth.athlete_id", "==", athleteId)
          .get();

        if (usersSnapshot.empty) {
          logger.info("WORKER_NO_USER_FOUND", { athleteId });
          return;
        }

        switch (aspectType) {
          case 'create': {
            // Fetch activity details
            const firstUserId = usersSnapshot.docs[0].id;
            const userToken = await getValidAccessToken(firstUserId);
            const response = await fetch(`https://www.strava.com/api/v3/activities/${activityId}`, {
              headers: { "Authorization": `Bearer ${userToken}` }
            });
            checkStravaResponse(response, "Strava Activity API");
            const activity = await response.json();

            // Sync for every user and collect FCM tokens
            // Import for every user
            let anyImported = false;
            const syncPromises = usersSnapshot.docs.map(async (userDoc) => {
              const result = await saveActivityToBatch(activity, userDoc.id);
              if (result.wasCreated) anyImported = true;
            });
            await Promise.all(syncPromises);

            // Send notifications if newly imported
            if (anyImported) {
              await sendImportNotifications(activity, usersSnapshot);
            }
            break;
          }

          case 'update': {
            const firstUserId = usersSnapshot.docs[0].id;
            const userToken = await getValidAccessToken(firstUserId);
            const response = await fetch(`https://www.strava.com/api/v3/activities/${activityId}`, {
              headers: { "Authorization": `Bearer ${userToken}` }
            });
            checkStravaResponse(response, "Strava Activity API");
            const activity = await response.json();
            
            let anyImported = false;
            for (const userDoc of usersSnapshot.docs) {
              const result = await saveActivityToBatch(activity, userDoc.id);
              if (result.wasCreated) anyImported = true;
            }

            if (anyImported) {
              await sendImportNotifications(activity, usersSnapshot);
            }
            break;
          }

          case 'delete': {
            for (const userDoc of usersSnapshot.docs) {
              await saveActivityToBatch({ id: activityId, isDeleted: true }, userDoc.id);
            }
            break;
          }
        }
      } else if (objectType === 'athlete') {
        await handleAthleteEvent(event);
      } else {
        logger.info("WORKER_SKIPPED_TYPE", { objectType });
      }

      logger.info("WORKER_SUCCESS", { activityId, aspectType });
    } catch (error) {
      logger.error("WEBHOOK_WORKER_FAILED", { activityId, error: error.message });
      throw error; // Let Cloud Task retry based on config
    }
  }
);

/**
 * Handle athlete events (like deauthorization)
 */
async function handleAthleteEvent(event) {
  const athleteId = event.owner_id;
  const aspectType = event.aspect_type;

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
          strava_deauthorized_on_strava_at: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: getTTLTimestamp()
        });

        await batch.commit();
        logger.info(`CLEANUP_SUCCESS_FOR_WEBHOOK_DEAUTH: ${userId}`);
      }
    } catch (error) {
      logger.error("CLEANUP_FAILED_FOR_WEBHOOK_DEAUTH", error);
    }
  }
}

/**
 * Sends notifications to all users who have an FCM token.
 */
async function sendImportNotifications(activity, usersSnapshot) {
  const tokenToUserIds = new Map();
  usersSnapshot.docs.forEach(userDoc => {
    const userData = userDoc.data();
    if (userData.fcm_token && userData.enable_strava_notifications !== false) {
      const token = userData.fcm_token;
      if (!tokenToUserIds.has(token)) tokenToUserIds.set(token, new Set());
      tokenToUserIds.get(token).add(userDoc.id);
    }
  });

  const notificationPromises = Array.from(tokenToUserIds.keys()).map(async (token) => {
    try {
      await admin.messaging().send({
        token: token,
        notification: {
          title: "New Activity!",
          body: `We imported your ride: ${activity.name}`,
        },
        data: { type: "strava_sync", activityId: String(activity.id) }
      });
    } catch (err) {
      const isStale = err.code === "messaging/registration-token-not-registered" || err.code === "messaging/invalid-argument";
      if (isStale) {
        const affectedUserIds = Array.from(tokenToUserIds.get(token));
        const cleanupBatch = db.batch();
        affectedUserIds.forEach(uid => cleanupBatch.update(db.collection("users").doc(uid), { fcm_token: admin.firestore.FieldValue.delete() }));
        await cleanupBatch.commit();
      }
    }
  });
  await Promise.all(notificationPromises);
}
