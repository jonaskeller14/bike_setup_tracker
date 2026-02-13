const { db, logger, admin } = require("./firebase");

/**
 * Helper: Refreshes Strava access token if expired.
 */
async function getValidAccessToken(userId) {
  const userRef = db.collection("users").doc(userId);
  const doc = await userRef.get();
  if (!doc.exists) throw new Error("User not found");

  const auth = doc.data().strava_auth;
  const now = Math.floor(Date.now() / 1000);

  if (auth.expires_at < now + 60) {
    logger.info("REFRESHING_TOKEN", { userId });
    const response = await fetch("https://www.strava.com/api/v3/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: process.env.STRAVA_CLIENT_ID,
        client_secret: process.env.STRAVA_CLIENT_SECRET,
        refresh_token: auth.refresh_token,
        grant_type: "refresh_token",
      }),
    });
    const data = await response.json();
    if (!response.ok) throw new Error("Refresh failed");

    const newAuth = {
      ...auth,
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: data.expires_at,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    await userRef.update({ strava_auth: newAuth });
    return data.access_token;
  }
  return auth.access_token;
}

/**
 * Helper: Saves Athlete and Gear (Bikes) to Firestore.
 * Used by both syncActivities (recent) and syncFullHistory.
 */
async function saveAthleteAndGear(athlete, userId, batch) {
  const userRef = db.collection("users").doc(userId);

  // 1. Save Athlete Profile
  // Path: users/{userId}/athletes/athlete
  const athleteRef = userRef.collection("athletes").doc("athlete");

  const cleanAthlete = {
    id: athlete.id,
    lastModified: admin.firestore.FieldValue.serverTimestamp(),
    firstname: athlete.firstname,
    lastname: athlete.lastname,
    profile: athlete.profile,
    gears: [
      ...(athlete.bikes || []).map(b => b.id),
    ]
  };

  batch.set(athleteRef, cleanAthlete, { merge: true });

  // 2. Save Gear (Bikes only)
  // Path: users/{userId}/gears/{gearId}
  const allGear = [...(athlete.bikes || [])];
  
  for (const gear of allGear) {
    const gearRef = userRef.collection("gears").doc(String(gear.id));
    const cleanGear = {
      id: gear.id,
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
      name: gear.name,
    };
    batch.set(gearRef, cleanGear, { merge: true });
  }

  return allGear.length; // Return count of gear items processed
}

/**
 * Helper: Transforms and Saves a single Activity to Firestore.
 * Standardizes how we save activities from both Webhook and Manual Sync.
 */
async function saveActivity(activity, userId, batch) {
  // Extract lat/lon if available
  let startLat = null;
  let startLon = null;
  if (activity.start_latlng && Array.isArray(activity.start_latlng) && activity.start_latlng.length === 2) {
    startLat = activity.start_latlng[0];
    startLon = activity.start_latlng[1];
  }

  // Handle differences between Webhook "SummaryActivity" and detailed "DetailedActivity"
  // Detailed activities from manual sync usually have more fields, but we stick to the common ones.
  // Note: Webhook sends a partial update or we fetch full details. 
  // In `stravaWebhook`, we fetch full details, so `activity` is full there.
  // In `syncActivities`, we fetch "SummaryActivity" list, which has most of this.

  const cleanActivity = {
    id: activity.id,
    lastModified: admin.firestore.FieldValue.serverTimestamp(),
    name: activity.name,
    athleteId: activity.athlete ? activity.athlete.id : null, // Handle if athlete obj is missing (rare in full fetch)
    sportType: activity.sport_type || activity.type, // Fallback for older API versions if needed
    startDate: activity.start_date,
    startDateLocal: activity.start_date_local,
    gearId: activity.gear_id || null,
    startLat: startLat,
    startLon: startLon,
    distance: activity.distance,
    totalElevationGain: activity.total_elevation_gain,
    movingTime: activity.moving_time,
    elapsedTime: activity.elapsed_time,
    synced_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  const activityRef = db.collection("users").doc(userId)
    .collection("activities").doc(String(activity.id));

  batch.set(activityRef, cleanActivity, { merge: true });
}

module.exports = {
  getValidAccessToken,
  saveAthleteAndGear,
  saveActivity,
};
