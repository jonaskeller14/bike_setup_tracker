const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");
const {
  getValidAccessToken,
  saveAthleteAndGear,
  saveActivityToBatch,
  checkStravaResponse,
  isBikeActivity,
  getTTLTimestamp,
  getAthleteIdForCaller,
  requireActiveStravaEntitlement,
} = require("./common");

/**
 * STRATEGY: Manual Recent Sync
 * Fetches the last 50 activities for the caller's active athlete. Used as
 * "force refresh" if webhooks miss something.
 *
 * Optional request param: `athleteId` — for the future trainer view, where
 * the user explicitly picks which of their linked athletes to sync. Defaults
 * to the first linked athlete.
 */
/**
 * Internal: fetches athlete profile + gear and the last 50 activities, then
 * upserts them. Used by the syncActivities callable AND by exchangeToken when
 * the athlete already has fresh data (avoids re-pulling the entire history).
 */
async function syncRecent(athleteId) {
  athleteId = String(athleteId);
  const token = await getValidAccessToken(athleteId);

  // Athlete profile + gear
  const athleteResponse = await fetch(
    "https://www.strava.com/api/v3/athlete",
    { headers: { Authorization: `Bearer ${token}` } }
  );
  checkStravaResponse(athleteResponse, "Strava Athlete API");
  const athlete = await athleteResponse.json();

  const profileBatch = db.batch();
  const gearCount = await saveAthleteAndGear(athlete, profileBatch);
  await profileBatch.commit();

  // Last 50 activities
  const response = await fetch(
    "https://www.strava.com/api/v3/athlete/activities?per_page=50",
    { headers: { Authorization: `Bearer ${token}` } }
  );
  checkStravaResponse(response, "Strava Activities API");
  const activities = await response.json();

  for (const activity of activities) {
    await saveActivityToBatch(activity, athleteId);
  }

  await db.collection("athletes").doc(athleteId).update({
    strava_sync_last_recent: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { activityCount: activities.length, gearCount };
}

exports.syncActivities = onCall(
  {
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    enforceAppCheck: true,
    memory: "512MiB",
  },
  async (request) => {
    const userId = request.auth ? request.auth.uid : null;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    try {
      await requireActiveStravaEntitlement(userId);
    } catch (error) {
      throw new HttpsError("permission-denied", error.message);
    }

    const athleteId = await getAthleteIdForCaller(
      userId,
      request.data?.athleteId
    );

    try {
      const result = await syncRecent(athleteId);
      logger.info("MANUAL_SYNC_SUCCESSFUL", {
        userId,
        athleteId,
        count: result.activityCount,
        gearCount: result.gearCount,
      });
      return `SYNC_SUCCESSFUL: ${result.activityCount} activities, ${result.gearCount} gear items processed.`;
    } catch (error) {
      logger.error("MANUAL_SYNC_FAILED", {
        userId,
        athleteId,
        error: error.message,
      });
      throw new HttpsError("internal", `Sync failed: ${error.message}`);
    }
  }
);

/**
 * Core logic for full history sync — called from `exchangeToken` (after
 * first OAuth) and from the scheduled weekly sync worker, and exposed as a
 * callable for an explicit "Full Sync" button.
 *
 * Now keyed by athleteId rather than userId.
 */
async function syncFullHistory(athleteId) {
  athleteId = String(athleteId);
  const athleteRef = db.collection("athletes").doc(athleteId);

  try {
    await athleteRef.update({
      strava_sync_status: "syncing",
      strava_sync_error: "",
    });

    const token = await getValidAccessToken(athleteId);

    // Athlete profile + gear.
    const athleteResponse = await fetch(
      "https://www.strava.com/api/v3/athlete",
      { headers: { Authorization: `Bearer ${token}` } }
    );
    checkStravaResponse(athleteResponse, "Strava Athlete API");
    const athlete = await athleteResponse.json();

    let batch = db.batch();
    const gearCount = await saveAthleteAndGear(athlete, batch);
    await batch.commit();

    // Wipe old batches before repopulating.
    const oldBatches = await athleteRef.collection("activity_batches").get();
    if (!oldBatches.empty) {
      const deleteBatch = db.batch();
      oldBatches.forEach((doc) => deleteBatch.delete(doc.ref));
      await deleteBatch.commit();
    }

    // Paginated fetch of every activity.
    let page = 1;
    const perPage = 100;
    let allActivitiesSaved = 0;
    let keepFetching = true;
    let currentBatchActivities = [];

    while (keepFetching) {
      const response = await fetch(
        `https://www.strava.com/api/v3/athlete/activities?page=${page}&per_page=${perPage}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      checkStravaResponse(response, `Strava Activities API (page ${page})`);
      const activities = await response.json();
      if (activities.length === 0) {
        keepFetching = false;
        break;
      }

      for (const activity of activities) {
        if (!isBikeActivity(activity)) continue;

        // Transform to local format
        let startLat = null;
        let startLon = null;
        if (
          activity.start_latlng &&
          Array.isArray(activity.start_latlng) &&
          activity.start_latlng.length === 2
        ) {
          startLat = activity.start_latlng[0];
          startLon = activity.start_latlng[1];
        }

        currentBatchActivities.push({
          id: activity.id,
          lastModified: admin.firestore.Timestamp.now(),
          name: activity.name,
          athleteId: activity.athlete ? activity.athlete.id : null,
          sportType: activity.sport_type || activity.type,
          startDate: activity.start_date,
          startDateLocal: activity.start_date_local,
          gearId: activity.gear_id || null,
          startLat: startLat,
          startLon: startLon,
          distance: activity.distance,
          totalElevationGain: activity.total_elevation_gain,
          movingTime: activity.moving_time,
          elapsedTime: activity.elapsed_time,
          workoutType: activity.workout_type ?? null,
        });

        allActivitiesSaved++;

        // When we have 500, write a batch doc
        if (currentBatchActivities.length >= 500) {
          await writeBatchDoc(athleteId, currentBatchActivities, allActivitiesSaved);
          currentBatchActivities = [];
        }
      }

      logger.info("SYNC_FULL_PAGE_DONE", {
        athleteId,
        page,
        count: activities.length,
      });
      page++;
    }

    // Commit any remaining operations
    if (currentBatchActivities.length > 0) {
      await writeBatchDoc(athleteId, currentBatchActivities, allActivitiesSaved);
    }

    await athleteRef.update({
      strava_sync_status: "idle",
      strava_sync_last_full: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("FULL_SYNC_SUCCESSFUL", {
      athleteId,
      totalActivities: allActivitiesSaved,
      gearCount,
    });
    return allActivitiesSaved;
  } catch (error) {
    logger.error("FULL_SYNC_FAILED", { athleteId, error: error.message });
    await athleteRef.update({
      strava_sync_status: "error",
      strava_sync_error: error.message,
    });
    throw error;
  }
}

async function writeBatchDoc(athleteId, activitiesRaw, totalCountSoFar) {
  const batchNum = Math.ceil(totalCountSoFar / 500);
  const batchId = `batch_${String(batchNum).padStart(3, "0")}`;

  const activityIds = activitiesRaw.map((a) => a.id);
  const activitiesMap = {};
  activitiesRaw.forEach((a) => {
    activitiesMap[String(a.id)] = a;
  });

  const batchData = {
    id: batchId,
    athleteId,
    lastModified: admin.firestore.FieldValue.serverTimestamp(),
    activityIds,
    activities: activitiesMap,
    expiresAt: getTTLTimestamp(),
  };

  await db
    .collection("athletes")
    .doc(athleteId)
    .collection("activity_batches")
    .doc(batchId)
    .set(batchData);

  logger.info("BATCH_WRITE_SUCCESS", {
    athleteId,
    batchId,
    count: activitiesRaw.length,
  });
}

/**
 * STRATEGY: Full History Sync (callable)
 * Heavyweight — fetches every activity from Strava. Used when the user hits
 * the "Full Sync" button (not currently wired in the UI but kept for parity).
 */
exports.syncFullHistoryCloud = onCall(
  {
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 540,
    memory: "512MiB",
    enforceAppCheck: true,
  },
  async (request) => {
    const userId = request.auth ? request.auth.uid : null;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    try {
      await requireActiveStravaEntitlement(userId);
    } catch (error) {
      throw new HttpsError("permission-denied", error.message);
    }
    const athleteId = await getAthleteIdForCaller(
      userId,
      request.data?.athleteId
    );

    try {
      const count = await syncFullHistory(athleteId);
      return `FULL_SYNC_SUCCESSFUL: ${count} activities processed.`;
    } catch (error) {
      throw new HttpsError("internal", `Full Sync failed: ${error.message}`);
    }
  }
);

module.exports = {
  syncActivities: exports.syncActivities,
  syncFullHistory,
  syncFullHistoryCloud: exports.syncFullHistoryCloud,
  syncRecent,
};
