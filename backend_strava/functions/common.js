const { db, logger, admin } = require("./firebase");

// TTL: Expiration duration for all data (1 year)
const TTL_DAYS = 365;
const getTTLTimestamp = () => admin.firestore.Timestamp.fromDate(new Date(Date.now() + TTL_DAYS * 24 * 60 * 60 * 1000));

/**
 * Custom error for Strava API rate limiting (HTTP 429).
 * Parses X-RateLimit-Limit and X-RateLimit-Usage headers to distinguish
 * between the 15-minute limit and the daily limit.
 *
 * Headers format: "15min_value,daily_value"
 * Example: X-RateLimit-Limit: 100,1000 / X-RateLimit-Usage: 95,500
 */
class StravaRateLimitError extends Error {
  constructor(response) {
    const limitHeader = response.headers.get("X-RateLimit-Limit") || "100,1000";
    const usageHeader = response.headers.get("X-RateLimit-Usage") || "0,0";

    const [limit15min, limitDaily] = limitHeader.split(",").map(Number);
    const [usage15min, usageDaily] = usageHeader.split(",").map(Number);

    const isDailyLimitHit = usageDaily >= limitDaily;

    super(
      `Strava rate limit exceeded (${isDailyLimitHit ? "daily" : "15-min"}): ` +
      `usage ${usage15min}/${limit15min} (15min), ${usageDaily}/${limitDaily} (daily)`
    );

    this.name = "StravaRateLimitError";
    this.usage15min = usage15min;
    this.limit15min = limit15min;
    this.usageDaily = usageDaily;
    this.limitDaily = limitDaily;
    this.isDailyLimitHit = isDailyLimitHit;
  }
}

/**
 * Helper: Checks a Strava API response and throws appropriate errors.
 * Throws StravaRateLimitError on 429, generic Error on other failures.
 */
function checkStravaResponse(response, context = "Strava API") {
  if (response.ok) return;

  if (response.status === 429) {
    throw new StravaRateLimitError(response);
  }

  throw new Error(`${context} failed: ${response.statusText}`);
}

/**
 * Helper: Returns a valid Strava access token for the given athlete, refreshing
 * if expired. Tokens live on athletes/{athleteId}.oauth. Refresh is wrapped in
 * a Firestore transaction so concurrent callers from different devices don't
 * race to refresh and invalidate each other.
 */
async function getValidAccessToken(athleteId) {
  // OAuth lives in `athlete_oauth/{athleteId}` (server-only, never readable
  // by the client) so we keep it out of the user-readable athlete doc.
  const oauthRef = db.collection("athlete_oauth").doc(String(athleteId));

  const initialSnap = await oauthRef.get();
  if (!initialSnap.exists) {
    throw new Error(`OAuth for athlete ${athleteId} not found`);
  }
  const initialOauth = initialSnap.data();

  const now = Math.floor(Date.now() / 1000);
  if (initialOauth.expires_at >= now + 60) {
    return initialOauth.access_token;
  }

  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(oauthRef);
    const oauth = snap.data();

    // Another caller may have refreshed in the meantime.
    if (oauth.expires_at >= now + 60) return oauth.access_token;

    logger.info("REFRESHING_TOKEN", { athleteId });
    const response = await fetch("https://www.strava.com/api/v3/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: process.env.STRAVA_CLIENT_ID,
        client_secret: process.env.STRAVA_CLIENT_SECRET,
        refresh_token: oauth.refresh_token,
        grant_type: "refresh_token",
      }),
    });
    const data = await response.json();
    if (!response.ok) throw new Error("Refresh failed");

    const newOauth = {
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: data.expires_at,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.update(oauthRef, newOauth);
    return data.access_token;
  });
}

/**
 * Helper: Saves athlete profile and gear to Firestore.
 * Gears are embedded as an array on the athlete doc — no subcollection needed.
 * This means gears arrive for free inside the athlete doc snapshot the client
 * already listens to, eliminating a separate Firestore listener.
 */
async function saveAthleteAndGear(athlete, batch) {
  const athleteId = String(athlete.id);
  const athleteRef = db.collection("athletes").doc(athleteId);

  const allGear = [...(athlete.bikes || [])];
  const now = admin.firestore.Timestamp.now();

  batch.set(
    athleteRef,
    {
      id: athlete.id,
      firstname: athlete.firstname,
      lastname: athlete.lastname,
      profile: athlete.profile,
      gears: allGear.map((b) => ({
        id: b.id,
        name: b.name,
        lastModified: now,
      })),
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return allGear.length;
}

/**
 * Helper: Decides which activity should be synced.
 * Only sync bike activities (mtb, roadbike, gravel, velomobil, ....).
 */
function isBikeActivity(activity) {
  const sportType = activity.sport_type || activity.type;
  const bikeTypes = [
    "Ride",
    "MountainBikeRide",
    "EMountainBikeRide",
    "EBikeRide",
    "GravelRide",
    "Velomobile",
    "Handcycle",
    "VirtualRide",
  ];
  return bikeTypes.includes(sportType);
}

/**
 * Helper: Transforms and Saves a single Activity to a Batch document.
 * Standardizes how we save activities from both Webhook and Manual Sync.
 * Uses Hybrid Batching (Map for data, Array for indexing).
 *
 * Path: athletes/{athleteId}/activity_batches/{batchId}
 */
async function saveActivityToBatch(activity, athleteId, batch = null) {
  const isDeleteRequest = activity.isDeleted === true;
  const isBike = isBikeActivity(activity);

  // If it's a real activity (not a delete) and it's NOT a bike, treat as a
  // delete. Handles the case where a user changes activity type from "Ride"
  // to "Run" on Strava.
  const effectiveDelete = isDeleteRequest || (!isDeleteRequest && !isBike);

  const activityId = activity.id;
  const athleteRef = db.collection("athletes").doc(String(athleteId));
  const batchesRef = athleteRef.collection("activity_batches");

  // 1. Transform activity to clean format
  let cleanActivity = null;
  if (!effectiveDelete) {
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

    if (effectiveDelete) {
      updateData[`activities.${activityId}`] = {
        id: activityId,
        isDeleted: true,
        lastModified: admin.firestore.FieldValue.serverTimestamp(),
      };
    } else {
      updateData[`activities.${activityId}`] = cleanActivity;
      updateData.expiresAt = getTTLTimestamp();
    }

    if (batch) {
      batch.update(batchDoc.ref, updateData);
    } else {
      await batchDoc.ref.update(updateData);
    }
    return {
      wasCreated: false,
      wasUpdated: !effectiveDelete,
      wasDeleted: effectiveDelete,
    };
  }

  if (effectiveDelete) return { wasCreated: false, ignored: true }; // Activity to delete not found, or new non-bike activity.

  // 3. New Activity -> Find latest batch or create new
  const latestBatchQuery = await batchesRef
    .orderBy("id", "desc")
    .limit(1)
    .get();

  let targetBatchDoc = !latestBatchQuery.empty
    ? latestBatchQuery.docs[0]
    : null;

  if (targetBatchDoc && targetBatchDoc.data().activityIds.length < 500) {
    const updateData = {
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
      [`activities.${activityId}`]: cleanActivity,
      activityIds: admin.firestore.FieldValue.arrayUnion(activityId),
      expiresAt: getTTLTimestamp(),
    };

    if (batch) {
      batch.update(targetBatchDoc.ref, updateData);
    } else {
      await targetBatchDoc.ref.update(updateData);
    }
  } else {
    const newBatchId = targetBatchDoc
      ? `batch_${String(parseInt(targetBatchDoc.id.split("_")[1]) + 1).padStart(3, "0")}`
      : "batch_001";

    const newBatchData = {
      id: newBatchId,
      athleteId,
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
      activityIds: [activityId],
      activities: {
        [`${activityId}`]: cleanActivity,
      },
      expiresAt: getTTLTimestamp(),
    };

    const newBatchRef = batchesRef.doc(newBatchId);
    if (batch) {
      batch.set(newBatchRef, newBatchData);
    } else {
      await newBatchRef.set(newBatchData);
    }
  }
  return { wasCreated: true };
}

/**
 * Helper: Resolve the active athleteId for a caller. Used by callable
 * functions (manual sync, etc.). Accepts an optional override (future
 * trainer view, where the user picks which athlete to sync).
 */
async function getAthleteIdForCaller(userId, explicitAthleteId = null) {
  const userSnap = await db.collection("users").doc(userId).get();
  if (!userSnap.exists) {
    throw new Error(`User ${userId} not found`);
  }
  const linked = userSnap.data().linked_athletes || [];
  if (linked.length === 0) {
    throw new Error(`User ${userId} has no linked athlete`);
  }
  if (explicitAthleteId) {
    if (!linked.includes(String(explicitAthleteId))) {
      throw new Error(
        `User ${userId} is not linked to athlete ${explicitAthleteId}`
      );
    }
    return String(explicitAthleteId);
  }
  return String(linked[0]);
}

/**
 * Helper: Returns true if at least one device linked to this athlete has an
 * active subscription entitlement covering the Strava sync feature. Used as
 * the gate on the Strava webhook so we don't process activities for users
 * who aren't paying.
 */
async function athleteHasActiveEntitlement(athleteId) {
  const now = admin.firestore.Timestamp.now();
  const snap = await db
    .collection("users")
    .where("linked_athletes", "array-contains", String(athleteId))
    .where("entitlement.strava.expiresAt", ">", now)
    .limit(1)
    .get();
  return !snap.empty;
}

module.exports = {
  StravaRateLimitError,
  checkStravaResponse,
  getValidAccessToken,
  saveAthleteAndGear,
  saveActivityToBatch,
  isBikeActivity,
  getTTLTimestamp,
  getAthleteIdForCaller,
  athleteHasActiveEntitlement,
};
