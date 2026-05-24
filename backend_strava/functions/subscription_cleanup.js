const { onSchedule } = require("firebase-functions/v2/scheduler");
const { db, logger, admin } = require("./firebase");

const GRACE_DAYS = 7;

/**
 * STRATEGY: Post-expiry cleanup of athlete links
 *
 * Once a user's Strava entitlement has been expired for GRACE_DAYS, remove
 * every athleteId from their `linked_athletes` array. The existing
 * `cleanupOrphanedAthletes` trigger then handles Strava OAuth deauth and
 * recursive deletion of the `athletes/{id}` subtree.
 *
 * Local device data is already wiped client-side at the moment of expiry
 * (see StravaService._checkEntitlementExpiry). This cron purely cleans up
 * server-side state once we are confident the user is not coming back.
 *
 * Schedule: 03:30 Europe/Berlin daily. Offset from the top of the hour to
 * avoid contending with `enqueueWeeklySyncs` (runs at :00 hourly).
 */
exports.cleanupExpiredSubscriptions = onSchedule(
  {
    schedule: "30 3 * * *",
    timeZone: "Europe/Berlin",
  },
  async () => {
    const now = new Date();
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(now.getTime() - GRACE_DAYS * 24 * 60 * 60 * 1000)
    );

    logger.info("EXPIRY_CLEANUP_START", {
      cutoff: cutoff.toDate().toISOString(),
      graceDays: GRACE_DAYS,
    });

    try {
      const snap = await db
        .collection("users")
        .where("entitlement.strava.expiresAt", "<", cutoff)
        .get();

      let usersUnlinked = 0;
      let athleteLinksRemoved = 0;

      for (const doc of snap.docs) {
        const linkedAthletes = doc.data().linked_athletes || [];
        if (linkedAthletes.length === 0) continue;

        await doc.ref.update({
          linked_athletes: admin.firestore.FieldValue.arrayRemove(
            ...linkedAthletes
          ),
        });
        usersUnlinked += 1;
        athleteLinksRemoved += linkedAthletes.length;

        logger.info("EXPIRY_CLEANUP_UNLINKED", {
          userId: doc.id,
          athleteIds: linkedAthletes,
        });
      }

      logger.info("EXPIRY_CLEANUP_DONE", {
        usersChecked: snap.size,
        usersUnlinked,
        athleteLinksRemoved,
      });
    } catch (e) {
      logger.error("EXPIRY_CLEANUP_FATAL", { error: e.message });
    }
  }
);
