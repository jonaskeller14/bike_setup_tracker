const { onRequest } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");
const { getValidAccessToken, saveAthleteAndGear, saveActivity } = require("./common");

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

      if (!athleteResponse.ok) {
        throw new Error(`Strava Athlete API failed: ${athleteResponse.statusText}`);
      }

      const athlete = await athleteResponse.json();
      
      const batch = db.batch();
      
      // 1.1 Save Athlete Profile & Gear
      const gearCount = await saveAthleteAndGear(athlete, userId, batch);

      // 2. Fetch last 50 activities
      const response = await fetch("https://www.strava.com/api/v3/athlete/activities?per_page=50", {
        headers: { "Authorization": `Bearer ${userToken}` }
      });
      
      if (!response.ok) {
        throw new Error(`Strava Activities API failed: ${response.statusText}`);
      }

      const activities = await response.json();
      
      // 2.1 Save Activities
      for (const activity of activities) {
        await saveActivity(activity, userId, batch);
      }

      await batch.commit();

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

    if (!athleteResponse.ok) {
      throw new Error(`Strava Athlete API failed: ${athleteResponse.statusText}`);
    }

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

    // Reset batch for activities
    batch = db.batch();
    let operationCount = 0;

    while (keepFetching) {
      const response = await fetch(`https://www.strava.com/api/v3/athlete/activities?page=${page}&per_page=${perPage}`, {
        headers: { "Authorization": `Bearer ${userToken}` }
      });

      if (!response.ok) {
        throw new Error(`Strava Activities API failed on page ${page}: ${response.statusText}`);
      }

      const activities = await response.json();

      if (activities.length === 0) {
        keepFetching = false;
        break;
      }

      for (const activity of activities) {
        await saveActivity(activity, userId, batch);
        operationCount++;
        allActivitiesSaved++;

        // Commit every ~450 writes to avoid the 500 limit
        if (operationCount >= 450) {
          await batch.commit();
          batch = db.batch(); // New batch
          operationCount = 0;
        }
      }

      logger.info(`SYNC_FULL_PAGE_DONE`, { userId, page, count: activities.length });
      page++;
    }

    // Commit any remaining operations
    if (operationCount > 0) {
      await batch.commit();
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
