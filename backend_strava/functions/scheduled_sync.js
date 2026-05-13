const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFunctions } = require("firebase-admin/functions");
const { db, logger, admin } = require("./firebase");
const { syncFullHistory } = require("./sync");
const { StravaRateLimitError, athleteHasActiveEntitlement } = require("./common");

/**
 * STRATEGY: Hourly task enqueuer for the weekly full sync.
 * Runs every hour. Picks athletes whose sync_day == today and haven't been
 * synced in the last 20h. Each gets staggered into the Cloud Tasks queue so
 * we don't burn through Strava's 15-minute rate limit.
 *
 * Entitlement gate: skip athletes whose linked devices are all unsubscribed.
 */
exports.enqueueWeeklySyncs = onSchedule(
  {
    schedule: "0 * * * *", // Hourly
    timeZone: "Europe/Berlin",
  },
  async () => {
    const now = new Date();
    const todayDow = now.getDay();
    const cutoffDate = new Date(now.getTime() - 20 * 60 * 60 * 1000);

    logger.info("ENQUEUE_SYNC_START", { dayOfWeek: todayDow, cutoff: cutoffDate.toISOString() });

    try {
      const athletesSnapshot = await db
        .collection("athletes")
        .where("sync_day", "==", todayDow)
        .where("strava_sync_last_full", "<", cutoffDate)
        .limit(4)
        .get();

      if (athletesSnapshot.empty) {
        logger.info("ENQUEUE_SYNC_NO_PENDING_ATHLETES", { dayOfWeek: todayDow });
        return;
      }

      logger.info("ENQUEUE_SYNC_BATCH_FOUND", {
        count: athletesSnapshot.size,
      });

      const queue = getFunctions().taskQueue(
        "projects/bike-setup-tracker-strava/locations/europe-west3/functions/scheduledSyncWorker"
      );

      let delaySeconds = 0;
      for (const doc of athletesSnapshot.docs) {
        const athleteId = doc.id;

        // Skip athletes whose linked devices are all unsubscribed.
        const isPaid = await athleteHasActiveEntitlement(athleteId);
        if (!isPaid) {
          logger.info("ENQUEUE_SYNC_SKIPPED_NO_ENTITLEMENT", { athleteId });
          // Stamp the last_full so we don't re-evaluate this athlete every
          // hour — they re-enter the queue once someone subscribes.
          await doc.ref.update({
            strava_sync_last_full: admin.firestore.FieldValue.serverTimestamp(),
          });
          continue;
        }

        await queue.enqueue(
          { athleteId },
          { scheduleDelaySeconds: delaySeconds }
        );

        logger.info("ENQUEUED_TASK_FOR_ATHLETE", { athleteId, delaySeconds });
        delaySeconds += 90;
      }
    } catch (error) {
      logger.error("ENQUEUE_SYNC_FATAL", error);
    }
  }
);

exports.scheduledSyncWorker = onTaskDispatched(
  {
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 60,
    },
    rateLimits: {
      maxConcurrentDispatches: 1, // Stay safe with Strava rate limits
    },
    region: "europe-west3",
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (req) => {
    const athleteId = req.data.athleteId;
    if (!athleteId) {
      logger.error("TASK_MISSING_ATHLETEID");
      return;
    }

    try {
      logger.info("WORKER_START_ATHLETE", { athleteId });
      await syncFullHistory(athleteId);
      logger.info("WORKER_SUCCESS_ATHLETE", { athleteId });
    } catch (error) {
      if (error instanceof StravaRateLimitError) {
        logger.warn("WORKER_RATE_LIMITED", {
          athleteId,
          isDailyLimit: error.isDailyLimitHit,
          usage: `${error.usage15min}/${error.limit15min} (15min), ${error.usageDaily}/${error.limitDaily} (daily)`,
        });
        throw error; // let task queue back off and retry
      }
      logger.error("WORKER_FAILED_ATHLETE", {
        athleteId,
        error: error.message,
      });
      // Stamp last_full so this athlete doesn't get re-tried every hour
      // forever — they'll re-enter the queue at the next weekly slot.
      await db
        .collection("athletes")
        .doc(athleteId)
        .update({
          strava_sync_last_full: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  }
);
