const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { db, logger } = require("./firebase");

/**
 * STRATEGY: Orphan athlete cleanup
 *
 * Fires whenever a `users/{uid}` doc is created, updated, or deleted. We
 * compare the `linked_athletes` array before and after — for every athleteId
 * that was removed (or the whole user disappeared), we check if any other
 * user still references that athlete. If none, we:
 *   1. Revoke Strava's OAuth via the deauthorize endpoint
 *   2. Recursively delete `athletes/{athleteId}` and all subcollections
 *
 * This is the single backend cleanup path. The client's `disconnect()` just
 * does `arrayRemove([athleteId])` on the user doc and trusts this trigger.
 */
exports.cleanupOrphanedAthletes = onDocumentWritten(
  {
    document: "users/{userId}",
    region: "europe-west3",
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    const beforeAthletes = new Set(
      (before?.linked_athletes || []).map(String)
    );
    const afterAthletes = new Set((after?.linked_athletes || []).map(String));

    const removed = [];
    for (const athleteId of beforeAthletes) {
      if (!afterAthletes.has(athleteId)) removed.push(athleteId);
    }
    if (removed.length === 0) return;

    logger.info("ORPHAN_CHECK_START", {
      userId: event.params.userId,
      removed,
    });

    for (const athleteId of removed) {
      try {
        const stillLinked = await db
          .collection("users")
          .where("linked_athletes", "array-contains", athleteId)
          .limit(1)
          .get();

        if (!stillLinked.empty) {
          logger.info("ORPHAN_SKIP_STILL_LINKED", { athleteId });
          continue;
        }

        await purgeAthlete(athleteId);
        logger.info("ORPHAN_PURGED", { athleteId });
      } catch (e) {
        logger.error("ORPHAN_CLEANUP_FAILED", {
          athleteId,
          error: e.message,
        });
      }
    }
  }
);

async function purgeAthlete(athleteId) {
  const athleteRef = db.collection("athletes").doc(athleteId);
  const oauthRef = db.collection("athlete_oauth").doc(athleteId);

  // 1. Revoke Strava OAuth — best-effort, do not block on failure.
  const oauthSnap = await oauthRef.get();
  if (oauthSnap.exists) {
    const accessToken = oauthSnap.data().access_token;
    if (accessToken) {
      try {
        await fetch("https://www.strava.com/oauth/deauthorize", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ access_token: accessToken }),
        });
      } catch (e) {
        logger.warn("STRAVA_DEAUTH_FAILED", {
          athleteId,
          error: e.message,
        });
      }
    }
    await oauthRef.delete();
  }

  // 2. Recursively delete the athlete subtree (profile + subcollections).
  await db.recursiveDelete(athleteRef);
}
