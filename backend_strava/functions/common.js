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
 * Helper: Transforms and Saves a single Activity to a Batch document.
 * Standardizes how we save activities from both Webhook and Manual Sync.
 * Uses Hybrid Batching (Map for data, Array for indexing).
 */
async function saveActivityToBatch(activity, userId, batch = null) {
  const isDelete = activity.isDeleted === true;
  const activityId = activity.id;
  const userRef = db.collection("users").doc(userId);
  const batchesRef = userRef.collection("activity_batches");

  // 1. Transform activity to clean format
  let cleanActivity = null;
  if (!isDelete) {
    let startLat = null;
    let startLon = null;
    if (activity.start_latlng && Array.isArray(activity.start_latlng) && activity.start_latlng.length === 2) {
      startLat = activity.start_latlng[0];
      startLon = activity.start_latlng[1];
    }

    cleanActivity = {
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
    };
  }

  // 2. Lookup existing batch
  const existingBatchQuery = await batchesRef
    .where("activityIds", "array-contains", activityId)
    .limit(1)
    .get();

  if (!existingBatchQuery.empty) {
    const batchDoc = existingBatchQuery.docs[0];
    const updateData = {
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (isDelete) {
      // DELETE Case
      updateData[`activities.${activityId}`] = admin.firestore.FieldValue.delete();
      updateData.activityIds = admin.firestore.FieldValue.arrayRemove(activityId);
    } else {
      // UPDATE Case
      updateData[`activities.${activityId}`] = cleanActivity;
    }

    if (batch) {
      batch.update(batchDoc.ref, updateData);
    } else {
      await batchDoc.ref.update(updateData);
    }
    return;
  }

  if (isDelete) return; // Activity to delete not found

  // 3. New Activity -> Find latest batch or create new
  const latestBatchQuery = await batchesRef
    .orderBy("id", "desc")
    .limit(1)
    .get();

  let targetBatchDoc = !latestBatchQuery.empty ? latestBatchQuery.docs[0] : null;
  
  if (targetBatchDoc && targetBatchDoc.data().activityIds.length < 500) {
    const updateData = {
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
      [`activities.${activityId}`]: cleanActivity,
      activityIds: admin.firestore.FieldValue.arrayUnion(activityId),
    };

    if (batch) {
      batch.update(targetBatchDoc.ref, updateData);
    } else {
      await targetBatchDoc.ref.update(updateData);
    }
  } else {
    // 4. Create New Batch
    const newBatchId = targetBatchDoc 
      ? `batch_${String(parseInt(targetBatchDoc.id.split('_')[1]) + 1).padStart(3, '0')}`
      : "batch_001";
    
    const newBatchData = {
      id: newBatchId,
      userId,
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
      activityIds: [activityId],
      activities: {
        [`${activityId}`]: cleanActivity
      }
    };

    const newBatchRef = batchesRef.doc(newBatchId);
    if (batch) {
      batch.set(newBatchRef, newBatchData);
    } else {
      await newBatchRef.set(newBatchData);
    }
  }
}

module.exports = {
  getValidAccessToken,
  saveAthleteAndGear,
  saveActivityToBatch,
};
