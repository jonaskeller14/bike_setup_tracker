const { onRequest } = require("firebase-functions/v2/https");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFunctions } = require("firebase-admin/functions");
const { db, logger, admin } = require("./firebase");
const {
  getValidAccessToken,
  saveActivityToBatch,
  checkStravaResponse,
  athleteHasActiveEntitlement,
} = require("./common");

/**
 * STRATEGY: Webhook Listener
 * Receives the event, dedupes via Cloud Tasks taskName, and enqueues a
 * background worker. Keeps response time < 100ms so Strava doesn't retry.
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

    // 2. EVENT (POST): Enqueue to background worker.
    if (req.method === "POST") {
      const event = req.body;
      const activityId = event.object_id;
      const athleteId = event.owner_id;
      const aspectType = event.aspect_type;
      const eventTime = event.event_time;

      // Cloud Tasks dedupes by taskName for ~1 hour — handles Strava retries.
      const taskName = `${athleteId}_${activityId}_${aspectType}_${eventTime || 'notime'}`;

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
 * STRATEGY: Background worker for webhook events.
 * Enforces the entitlement gate: if no device linked to this athlete has an
 * active subscription, we drop the event — we don't store data we're not
 * being paid to sync.
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
    const athleteId = String(event.owner_id);

    logger.info("WORKER_PROCESSING_EVENT", {
      objectType,
      activityId,
      aspectType,
      athleteId,
    });

    try {
      if (objectType === "athlete") {
        await handleAthleteEvent(event);
        return;
      }

      if (objectType !== "activity") {
        logger.info("WORKER_SKIPPED_TYPE", { objectType });
        return;
      }

      // ENTITLEMENT GATE — drop activities for athletes whose linked devices
      // are all unsubscribed. Saves Firestore writes + Strava API calls.
      const isPaid = await athleteHasActiveEntitlement(athleteId);
      if (!isPaid) {
        logger.info("WORKER_DROPPED_NO_ENTITLEMENT", { athleteId, activityId });
        return;
      }

      // ATHLETE EXISTS CHECK — needed to call Strava (OAuth lives here).
      const athleteSnap = await db
        .collection("athletes")
        .doc(athleteId)
        .get();
      if (!athleteSnap.exists) {
        logger.warn("WORKER_ATHLETE_NOT_FOUND", { athleteId });
        return;
      }

      switch (aspectType) {
        case "create":
        case "update": {
          const token = await getValidAccessToken(athleteId);
          const response = await fetch(
            `https://www.strava.com/api/v3/activities/${activityId}`,
            { headers: { Authorization: `Bearer ${token}` } }
          );
          checkStravaResponse(response, "Strava Activity API");
          const activity = await response.json();

          const result = await saveActivityToBatch(activity, athleteId);

          if (result.wasCreated) {
            await sendImportNotifications(activity, athleteId);
          }
          break;
        }

        case "delete": {
          await saveActivityToBatch(
            { id: activityId, isDeleted: true },
            athleteId
          );
          break;
        }
      }

      logger.info("WORKER_SUCCESS", { activityId, aspectType });
    } catch (error) {
      logger.error("WEBHOOK_WORKER_FAILED", {
        activityId,
        error: error.message,
      });
      throw error; // let Cloud Tasks retry per its config
    }
  }
);

/**
 * Strava-side deauthorization event. The user revoked our app in their
 * Strava settings. We delete the athlete subtree and remove this athleteId
 * from every linked user — the user-doc trigger picks up the change for
 * each device and tears down listeners.
 */
async function handleAthleteEvent(event) {
  const athleteId = String(event.owner_id);
  const aspectType = event.aspect_type;
  const updates = event.updates || {};

  if (aspectType !== "update" || updates.authorized !== "false") {
    return;
  }

  logger.info("ATHLETE_DEAUTHORIZED_ON_STRAVA", { athleteId });

  try {
    // 1. Remove this athleteId from every user that links to it.
    const usersSnap = await db
      .collection("users")
      .where("linked_athletes", "array-contains", athleteId)
      .get();
    const batch = db.batch();
    for (const userDoc of usersSnap.docs) {
      batch.update(userDoc.ref, {
        linked_athletes: admin.firestore.FieldValue.arrayRemove(athleteId),
      });
    }
    await batch.commit();

    // 2. Recursively delete the athlete subtree + the server-only OAuth doc.
    const athleteRef = db.collection("athletes").doc(athleteId);
    await Promise.all([
      db.recursiveDelete(athleteRef),
      db.collection("athlete_oauth").doc(athleteId).delete().catch(() => {}),
    ]);

    logger.info("ATHLETE_FULLY_PURGED", { athleteId, devices: usersSnap.size });
  } catch (error) {
    logger.error("ATHLETE_DEAUTH_CLEANUP_FAILED", {
      athleteId,
      error: error.message,
    });
  }
}

/**
 * Sends FCM notifications to every device linked to this athlete that has
 * notifications enabled.
 */
async function sendImportNotifications(activity, athleteId) {
  const usersSnap = await db
    .collection("users")
    .where("linked_athletes", "array-contains", String(athleteId))
    .get();

  const tokenToUserIds = new Map();
  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();
    if (data.fcm_token && data.enable_strava_notifications !== false) {
      const token = data.fcm_token;
      if (!tokenToUserIds.has(token)) tokenToUserIds.set(token, new Set());
      tokenToUserIds.get(token).add(userDoc.id);
    }
  }

  await Promise.all(
    Array.from(tokenToUserIds.keys()).map(async (token) => {
      try {
        await admin.messaging().send({
          token,
          notification: {
            title: "New Activity!",
            body: `We imported your ride: ${activity.name}`,
          },
          data: {
            type: "strava_sync",
            activityId: String(activity.id),
          },
        });
      } catch (err) {
        const isStale =
          err.code === "messaging/registration-token-not-registered" ||
          err.code === "messaging/invalid-argument";
        if (isStale) {
          const cleanup = db.batch();
          for (const uid of tokenToUserIds.get(token)) {
            cleanup.update(db.collection("users").doc(uid), {
              fcm_token: admin.firestore.FieldValue.delete(),
            });
          }
          await cleanup.commit();
        }
      }
    })
  );
}
