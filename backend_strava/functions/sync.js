const { onRequest } = require("firebase-functions/v2/https");
const { db, logger } = require("./firebase");
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
 * STRATEGY: Full History Sync
 * Fetches ALL activities from Strava for the user.
 * Uses pagination to retrieve everything.
 * WARNING: heavy operation. 
 */
exports.syncFullHistory = onRequest(
  { 
    secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"],
    timeoutSeconds: 540, // Increase timeout for long syncs (max 540s for Gen 2)
    memory: "512MiB" 
  },
  async (req, res) => {
    const userId = req.query.state;

    if (!userId) {
      return res.status(400).send("Missing user identification");
    }

    try {
      const userToken = await getValidAccessToken(userId);

      // 1. Fetch Athlete Profile First
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

      // 2. Paginated Fetch of ALL Activities
      let page = 1;
      const perPage = 100; // Max per page usually 200, stick to 100 for safety
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

      logger.info("FULL_SYNC_SUCCESSFUL", { userId, totalActivities: allActivitiesSaved });
      return res.status(200).send(`FULL_SYNC_SUCCESSFUL: ${allActivitiesSaved} activities processed.`);

    } catch (error) {
      logger.error("FULL_SYNC_FAILED", error);
      return res.status(500).send(`Full Sync failed: ${error.message}`);
    }
  }
);
