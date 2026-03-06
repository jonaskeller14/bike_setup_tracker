const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFunctions } = require("firebase-admin/functions");
const { db, logger, admin } = require("./firebase");
const { syncFullHistory } = require("./sync");
const { StravaRateLimitError } = require("./common");

/**
 * STRATEGY: Hourly Task Enqueuer
 * Runs every hour. Puts users into a Task Queue instead of waiting locally.
 */
exports.enqueueWeeklySyncs = onSchedule(
  {
    schedule: "0 * * * *", // Hourly
    timeZone: "Europe/Berlin",
  },
  async () => {
    const now = new Date();
    const todayDow = now.getDay();
    // We want users who haven't synced in the last 20 hours
    const cutoffDate = new Date(now.getTime() - 20 * 60 * 60 * 1000);

    logger.info("ENQUEUE_SYNC_START", { dayOfWeek: todayDow, cutoff: cutoffDate.toISOString() });

    try {
      // Find a batch of users scheduled for today who haven't synced yet
      const usersSnapshot = await db.collection("users")
        .where("sync_day", "==", todayDow)
        .where("strava_connected", "==", true)
        .where("strava_sync_last_full", "<", cutoffDate)
        .limit(4) 
        .get();

      if (usersSnapshot.empty) {
        logger.info("ENQUEUE_SYNC_NO_PENDING_USERS", { dayOfWeek: todayDow });
        return;
      }

      logger.info("ENQUEUE_SYNC_BATCH_FOUND", { count: usersSnapshot.size });

      let delaySeconds = 0;
      const queue = getFunctions().taskQueue(`locations/europe-west3/functions/syncWorker`);

      // 2. Queue the tasks
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        await queue.enqueue(
          { userId },
          { scheduleDelaySeconds: delaySeconds }
        );

        logger.info("ENQUEUED_TASK_FOR_USER", { userId, delaySeconds });
        delaySeconds += 90; // Next sync runs 90s later
      }

    } catch (error) {
      logger.error("ENQUEUE_SYNC_FATAL", { error: error.message });
    }
  }
);

/**
 * STRATEGY: Cloud Task Worker for Sync
 * Executes when a task is dispatched from the queue.
 */
exports.syncWorker = onTaskDispatched(
  {
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 60,
    },
    rateLimits: {
      maxConcurrentDispatches: 1, // Stay safe with Strava rate limits
    },
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (req) => {
    const userId = req.data.userId;

    if (!userId) {
      logger.error("TASK_MISSING_USERID");
      return;
    }

    try {
      logger.info("WORKER_START_USER", { userId });
      await syncFullHistory(userId);
      logger.info("WORKER_SUCCESS_USER", { userId });
    } catch (error) {
      if (error instanceof StravaRateLimitError) {
        logger.warn("WORKER_RATE_LIMITED", {
          userId,
          isDailyLimit: error.isDailyLimitHit,
          usage: `${error.usage15min}/${error.limit15min} (15min), ${error.usageDaily}/${error.limitDaily} (daily)`,
        });

        // Let the Task Queue backoff and retry later
        throw error;
      } else {
        logger.error("WORKER_FAILED_USER", { userId, error: error.message });
        
        // Mark as synced even if failed so we don't retry a broken user every hour forever
        await db.collection("users").doc(userId).update({
          strava_sync_last_full: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
  }
);
