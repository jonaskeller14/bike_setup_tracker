const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const crypto = require("crypto");
const { db, logger, admin } = require("./firebase");
const { syncFullHistory, syncRecent } = require("./sync");
const {
  requireActiveStravaEntitlement,
  userHasActiveStravaEntitlement,
} = require("./common");

// If the athlete was fully synced within this window, skip the full re-sync
// and just pull recent activities. Webhooks + weekly scheduled sync cover any
// drift beyond this freshness boundary.
const FULL_SYNC_FRESHNESS_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
const OAUTH_STATE_TTL_MS = 10 * 60 * 1000;
// Temporary compatibility window for released app versions that still send
// their Firebase UID as the OAuth state. Remove this fallback after rollout.
const LEGACY_OAUTH_STATE_DEADLINE_MS = Date.parse("2026-10-31T00:00:00Z");
const LEGACY_FIREBASE_UID_PATTERN = /^[A-Za-z0-9]{28}$/;

async function resolveOAuthUserId(state, nowMs = Date.now()) {
  const stateRef = db.collection("strava_oauth_states").doc(String(state));
  let userId;

  try {
    userId = await db.runTransaction(async (tx) => {
      const stateSnap = await tx.get(stateRef);
      if (!stateSnap.exists) return null;

      const stateData = stateSnap.data();
      const expiresAt = stateData?.expiresAt?.toMillis?.() ?? 0;
      if (!stateData?.userId || expiresAt <= nowMs) {
        throw new Error("INVALID_OR_EXPIRED_STATE");
      }
      tx.delete(stateRef);
      return stateData.userId;
    });
  } catch (error) {
    logger.warn("INVALID_OR_EXPIRED_OAUTH_STATE");
    return null;
  }

  if (userId) return { userId, isLegacy: false };
  if (nowMs >= LEGACY_OAUTH_STATE_DEADLINE_MS ||
      !LEGACY_FIREBASE_UID_PATTERN.test(String(state))) {
    return null;
  }

  try {
    await admin.auth().getUser(String(state));
    logger.warn("LEGACY_OAUTH_STATE_ACCEPTED", {
      migrationDeadline: new Date(LEGACY_OAUTH_STATE_DEADLINE_MS).toISOString(),
    });
    return { userId: String(state), isLegacy: true };
  } catch (error) {
    logger.warn("INVALID_LEGACY_OAUTH_STATE");
    return null;
  }
}

exports.resolveOAuthUserId = resolveOAuthUserId;

/**
 * Creates a short-lived, one-time OAuth state value. The Firebase UID never
 * leaves the backend, preventing account-linking attacks based on forged UIDs.
 */
exports.createStravaOAuthState = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    try {
      await requireActiveStravaEntitlement(userId);
    } catch (error) {
      throw new HttpsError("permission-denied", error.message);
    }

    const state = crypto.randomBytes(32).toString("base64url");
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + OAUTH_STATE_TTL_MS)
    );
    await db.collection("strava_oauth_states").doc(state).set({
      userId,
      expiresAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { state };
  }
);

/**
 * STRATEGY: OAuth Token Exchange
 * Strava redirects the user here after they click 'Authorize' in the app.
 * We receive a 'code' and a short-lived, one-time server-created state value.
 * During the migration window, legacy app versions may still send a Firebase
 * UID as state; that compatibility path expires on 2026-10-31.
 *
 * Writes:
 *   athletes/{athleteId}  - profile + oauth + initial sync state
 *   users/{userId}        - arrayUnion this athleteId into linked_athletes
 */
exports.exchangeToken = onRequest(
  { secrets: ["STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET"] },
  async (req, res) => {
    const code = req.query.code;
    const state = req.query.state;

    if (!code || !state) {
      logger.error("MISSING_CODE_OR_STATE", { hasCode: Boolean(code), hasState: Boolean(state) });
      return res.status(400).send("Missing code or user identification");
    }

    const oauthUser = await resolveOAuthUserId(state);
    if (!oauthUser) {
      return res.redirect("bike-setup-tracker://strava-auth?success=false&error=invalid_state");
    }
    const { userId } = oauthUser;

    let isEntitled = false;
    try {
      isEntitled = await userHasActiveStravaEntitlement(userId);
    } catch (error) {
      logger.error("STRAVA_AUTH_ENTITLEMENT_CHECK_FAILED", {
        userId,
        error: error.message,
      });
    }
    if (!isEntitled) {
      logger.warn("STRAVA_AUTH_PERMISSION_DENIED", { userId });
      return res.redirect("bike-setup-tracker://strava-auth?success=false&error=permission_denied");
    }

    try {
      // 1. Exchange the temporary code for a permanent access token.
      const response = await fetch("https://www.strava.com/api/v3/oauth/token", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: process.env.STRAVA_CLIENT_ID,
          client_secret: process.env.STRAVA_CLIENT_SECRET,
          code: code,
          grant_type: "authorization_code",
        }),
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(`Strava Token Exchange failed: ${JSON.stringify(data)}`);
      }

      const athleteId = String(data.athlete.id);
      const athleteRef = db.collection("athletes").doc(athleteId);
      const oauthRef = db.collection("athlete_oauth").doc(athleteId);
      const userRef = db.collection("users").doc(userId);

      // Read existing state BEFORE the merge writes so we can decide between
      // full vs. recent sync based on whether this athlete was synced
      // recently by another device.
      const existingSnap = await athleteRef.get();
      const lastFullRaw = existingSnap.data()?.strava_sync_last_full;
      const lastFull = lastFullRaw?.toMillis?.();
      const isFresh = lastFull && Date.now() - lastFull < FULL_SYNC_FRESHNESS_MS;

      // 2a. Write the client-readable athlete doc — profile + sync seed. No
      //     OAuth here (server-only, see below). `merge: true` so a second
      //     device re-linking the same athlete preserves existing sync state.
      await athleteRef.set(
        {
          id: data.athlete.id,
          firstname: data.athlete.firstname,
          lastname: data.athlete.lastname,
          profile: data.athlete.profile,
          sync_day: new Date().getDay(), // 0=Sun..6=Sat — used by weekly sync
          lastModified: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // 2b. Write the OAuth tokens to the server-only collection.
      await oauthRef.set({
        access_token: data.access_token,
        refresh_token: data.refresh_token,
        expires_at: data.expires_at,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 3. Set this device's linked athlete to exactly [athleteId]. Using a
      //    direct assignment (not arrayUnion) means reconnecting with a
      //    different Strava account cleanly replaces the old link — the orphan
      //    trigger will detect the removed athleteId and purge it. Also drop
      //    the TTL so the doc survives indefinitely now that Strava is linked.
      await userRef.set(
        {
          linked_athletes: [athleteId],
          expiresAt: admin.firestore.FieldValue.delete(),
        },
        { merge: true }
      );

      logger.info("STRAVA_AUTH_SUCCESSFUL", { userId, athleteId, isFresh });

      // 4. Kick off a background sync. Non-blocking.
      //    - Fresh athlete (re-link from another device, synced < 7 days ago):
      //      recent sync only — saves a paginated full pull for data we
      //      already have. Webhooks + weekly job catch any drift.
      //    - Stale or new athlete: full history sync.
      if (isFresh) {
        syncRecent(athleteId).catch((err) =>
          logger.error("BACKGROUND_RECENT_SYNC_FAILED", {
            athleteId,
            error: err.message,
          })
        );
      } else {
        syncFullHistory(athleteId).catch((err) =>
          logger.error("BACKGROUND_FULL_SYNC_FAILED", {
            athleteId,
            error: err.message,
          })
        );
      }

      // 5. Deep-link back to the app.
      return res.redirect("bike-setup-tracker://strava-auth?success=true");
    } catch (error) {
      logger.error("AUTH_ERROR", error);
      return res.redirect(
        "bike-setup-tracker://strava-auth?success=false&error=auth_failed"
      );
    }
  }
);

/**
 * STRATEGY: Availability check
 * Counts how many athletes currently have an active Strava OAuth (i.e. are
 * linked to at least one device). Compares against a configurable cap so we
 * stay under Strava's per-application rate limit.
 *
 * Configurable via Firestore doc `server_config/strava_limits`:
 *   { manualStop: bool, maxUsers: number, buffer: number }
 */
exports.checkStravaAvailability = onCall(
  { enforceAppCheck: true },
  async (request) => {
    try {
      const configDoc = await db
        .collection("server_config")
        .doc("strava_limits")
        .get();
      let config = { manualStop: false, maxUsers: 100, buffer: 10 };
      if (configDoc.exists) {
        config = { ...config, ...configDoc.data() };
      }

      if (config.manualStop) {
        return { available: false, reason: "manual_stop" };
      }

      // Count athletes that currently have OAuth tokens (i.e. someone is
      // linked). `athlete_oauth` only exists for currently-linked athletes —
      // orphan cleanup deletes it.
      const snapshot = await db.collection("athlete_oauth").count().get();

      const activeCount = snapshot.data().count;
      const cap = config.maxUsers + config.buffer;
      if (activeCount >= cap) {
        logger.warn("STRAVA_LIMIT_REACHED", { activeCount, cap });
        return { available: false, reason: "limit_reached" };
      }
      return { available: true };
    } catch (error) {
      logger.error("CHECK_AVAILABILITY_ERROR", error);
      throw new HttpsError("internal", "Failed to check availability");
    }
  }
);
