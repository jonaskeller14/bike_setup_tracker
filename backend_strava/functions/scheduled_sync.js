const { onSchedule } = require("firebase-functions/v2/scheduler");
const { db, logger, admin } = require("./firebase");
const { syncFullHistory } = require("./sync");
const { StravaRateLimitError } = require("./common");

/**
 * STRATEGY: Hourly Worker-Pool Sync
 * Runs every hour at the start of the hour (0 * * * *).
 * 
 * Each run:
 * 1. Finds up to 4 users whose assigned sync_day is today.
 * 2. ONLY picks users who haven't synced in the last 20 hours.
 * 3. Processes them sequentially with a 90s delay.
 * 
 * Capacity: 4 users/hour * 24h = 96 users/day (~670 users/week).
 * Strava Usage: ~1,000 requests/day (perfectly flat load).
 */
exports.scheduledWeeklySync = onSchedule(
  {
    schedule: "0 * * * *", // Hourly
    timeZone: "Europe/Berlin",
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 900, // 15 minutes — safe headroom for 4 users @ 90s delay
    memory: "512MiB",
  },
  async () => {
    const now = new Date();
    const todayDow = now.getDay(); // 0=Sun, 1=Mon, ..., 6=Sat
    
    // We want users who haven't synced in the last 20 hours
    const cutoffDate = new Date(now.getTime() - 20 * 60 * 60 * 1000);

    logger.info("SCHEDULED_SYNC_START", { dayOfWeek: todayDow, cutoff: cutoffDate.toISOString() });

    try {
      // 1. Find a batch of users scheduled for today who haven't synced yet
      const usersSnapshot = await db.collection("users")
        .where("sync_day", "==", todayDow)
        .where("strava_connected", "==", true)
        .where("strava_sync_last_full", "<", cutoffDate)
        .limit(4) 
        .get();

      if (usersSnapshot.empty) {
        logger.info("SCHEDULED_SYNC_NO_PENDING_USERS", { dayOfWeek: todayDow });
        return;
      }

      const batchCount = usersSnapshot.size;
      logger.info("SCHEDULED_SYNC_BATCH_FOUND", { count: batchCount });

      let successCount = 0;
      let failCount = 0;

      // 2. Process the batch sequentially
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        try {
          logger.info("SCHEDULED_SYNC_USER_START", { userId });
          await syncFullHistory(userId);
          successCount++;
          logger.info("SCHEDULED_SYNC_USER_SUCCESS", { userId });
        } catch (error) {
          if (error instanceof StravaRateLimitError) {
              logger.warn("SCHEDULED_SYNC_RATE_LIMITED", {
                userId,
                isDailyLimit: error.isDailyLimitHit,
                usage: `${error.usage15min}/${error.limit15min} (15min), ${error.usageDaily}/${error.limitDaily} (daily)`,
              });

              // If rate limit is hit, stop this batch. 
              // The next hour's run will pick up where we left off.
              break;
          } else {
            failCount++;
            logger.error("SCHEDULED_SYNC_USER_FAILED", { userId, error: error.message });
            
            // Mark as synced even if failed so we don't retry a broken user every hour forever
            // We'll try them again next week.
            await db.collection("users").doc(userId).update({
              strava_sync_last_full: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }

        // 3. Delay to stay safe within 15min window (only if not the last user)
        if (usersSnapshot.docs.indexOf(userDoc) < usersSnapshot.docs.length - 1) {
          await sleep(90_000);
        }
      }

      logger.info("SCHEDULED_SYNC_BATCH_COMPLETE", {
        successCount,
        failCount,
      });
    } catch (error) {
      logger.error("SCHEDULED_SYNC_FATAL", { error: error.message });
    }
  }
);

/**
 * Helper: Delay execution.
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
