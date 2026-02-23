const { onRequest } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");
const { getValidAccessToken, saveAthleteAndGear, saveActivityToBatch, checkStravaResponse } = require("./common");

/**
 * STRATEGY: Manual Sync (Recent)
 * Allows the app to request a manual fetch of the last 50 activities.
 * Useful if webhooks fail or user wants an immediate refresh.
 */
exports.syncActivities = onRequest(
  { secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"] },
  async (req, res) => {
    const userId = req.query.state; // We expect the userId in query params

    if (!userId) {
      return res.status(400).send("Missing user identification");
    }

    try {
      const userToken = await getValidAccessToken(userId);

      // 1. Fetch Athlete Profile (includes gear summary)
      const athleteResponse = await fetch("https://www.strava.com/api/v3/athlete", {
        headers: { "Authorization": `Bearer ${userToken}` }
      });

      checkStravaResponse(athleteResponse, "Strava Athlete API");

      const athlete = await athleteResponse.json();
      
      const batch = db.batch();
      
      // 1.1 Save Athlete Profile & Gear
      const gearCount = await saveAthleteAndGear(athlete, userId, batch);

      // 2. Fetch last 50 activities
      const response = await fetch("https://www.strava.com/api/v3/athlete/activities?per_page=50", {
        headers: { "Authorization": `Bearer ${userToken}` }
      });
      
      checkStravaResponse(response, "Strava Activities API");

      const activities = await response.json();
      
      // 2.1 Save Activities to Batches
      for (const activity of activities) {
        await saveActivityToBatch(activity, userId); // Individual processing for manual recent sync
      }

      await batch.commit();

      // 3. Mark last recent sync time
      await db.collection("users").doc(userId).update({
        strava_sync_last_recent: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info("MANUAL_SYNC_SUCCESSFUL", { userId, count: activities.length, gearCount });
      return res.status(200).send(`SYNC_SUCCESSFUL: ${activities.length} activities, ${gearCount} gear items processed.`);

    } catch (error) {
      logger.error("MANUAL_SYNC_FAILED", error);
      return res.status(500).send(`Sync failed: ${error.message}`);
    }
  }
);

/**
 * Core logic for full history sync.
 * Can be called internally or via request.
 */
async function syncFullHistory(userId) {
  const userRef = db.collection("users").doc(userId);
  
  try {
    // 1. Set status to syncing
    await userRef.update({ 
      strava_sync_status: "syncing",
      strava_sync_error: "" 
    });

    const userToken = await getValidAccessToken(userId);

    // 2. Fetch Athlete Profile First
    const athleteResponse = await fetch("https://www.strava.com/api/v3/athlete", {
      headers: { "Authorization": `Bearer ${userToken}` }
    });

    checkStravaResponse(athleteResponse, "Strava Athlete API");

    const athlete = await athleteResponse.json();
    
    // Save Athlete & Gear immediately in a small batch
    let batch = db.batch();
    const gearCount = await saveAthleteAndGear(athlete, userId, batch);
    await batch.commit();

    // 3. Paginated Fetch of ALL Activities
    let page = 1;
    const perPage = 100; 
    let allActivitiesSaved = 0;
    let keepFetching = true;
    let currentBatchActivities = [];

    // Clear old batches for clean migration (as requested: overwrite/repopulate)
    const oldBatches = await userRef.collection("activity_batches").get();
    if (!oldBatches.empty) {
      const deleteBatch = db.batch();
      oldBatches.forEach(doc => deleteBatch.delete(doc.ref));
      await deleteBatch.commit();
    }

    while (keepFetching) {
      const response = await fetch(`https://www.strava.com/api/v3/athlete/activities?page=${page}&per_page=${perPage}`, {
        headers: { "Authorization": `Bearer ${userToken}` }
      });

      checkStravaResponse(response, `Strava Activities API (page ${page})`);

      const activities = await response.json();

      if (activities.length === 0) {
        keepFetching = false;
        break;
      }

      for (const activity of activities) {
        // Transform to local format
        let startLat = null;
        let startLon = null;
        if (activity.start_latlng && Array.isArray(activity.start_latlng) && activity.start_latlng.length === 2) {
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
        });

        allActivitiesSaved++;

        // When we have 500, write a batch doc
        if (currentBatchActivities.length >= 500) {
          await writeBatchDoc(userId, currentBatchActivities, allActivitiesSaved);
          currentBatchActivities = [];
        }
      }

      logger.info(`SYNC_FULL_PAGE_DONE`, { userId, page, count: activities.length });
      page++;
    }

    // Commit any remaining operations
    if (currentBatchActivities.length > 0) {
      await writeBatchDoc(userId, currentBatchActivities, allActivitiesSaved);
    }

    // 4. Success -> Reset status
    await userRef.update({ 
      strava_sync_status: "idle",
      strava_sync_last_full: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info("FULL_SYNC_SUCCESSFUL", { userId, totalActivities: allActivitiesSaved });
    return allActivitiesSaved;

  } catch (error) {
    logger.error("FULL_SYNC_FAILED", { userId, error: error.message });
    
    // 5. Error -> Update status
    await userRef.update({ 
      strava_sync_status: "error",
      strava_sync_error: error.message 
    });
    
    throw error;
  }
}

/**
 * Internal Helper: Writes a single chunk of activities to Firestore as a batch.
 */
async function writeBatchDoc(userId, activitiesRaw, totalCountSoFar) {
  const batchNum = Math.ceil(totalCountSoFar / 500);
  const batchId = `batch_${String(batchNum).padStart(3, '0')}`;
  
  const activityIds = activitiesRaw.map(a => a.id);
  const activitiesMap = {};
  activitiesRaw.forEach(a => {
    activitiesMap[String(a.id)] = a;
  });

  const batchData = {
    id: batchId,
    userId,
    lastModified: admin.firestore.FieldValue.serverTimestamp(),
    activityIds,
    activities: activitiesMap
  };

  await db.collection("users").doc(userId)
    .collection("activity_batches").doc(batchId)
    .set(batchData);
  
  logger.info("BATCH_WRITE_SUCCESS", { userId, batchId, count: activitiesRaw.length });
}

/**
 * STRATEGY: Full History Sync
 * Fetches ALL activities from Strava for the user.
 * Uses pagination to retrieve everything.
 * WARNING: heavy operation. 
 */
const syncFullHistoryCloud = onRequest(
  { 
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 540, 
    memory: "512MiB" 
  },
  async (req, res) => {
    const userId = req.query.state;

    if (!userId) {
      return res.status(400).send("Missing user identification");
    }

    try {
      const count = await syncFullHistory(userId);
      return res.status(200).send(`FULL_SYNC_SUCCESSFUL: ${count} activities processed.`);
    } catch (error) {
      return res.status(500).send(`Full Sync failed: ${error.message}`);
    }
  }
);

module.exports = {
  syncActivities: exports.syncActivities, // Preserve existing export
  syncFullHistory,
  syncFullHistoryCloud,
};
