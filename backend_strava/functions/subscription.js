const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { db, logger, admin } = require("./firebase");
const { google } = require("googleapis");
const jwt = require("jsonwebtoken");
const {
  SignedDataVerifier,
  NotificationTypeV2,
  Environment,
} = require("@apple/app-store-server-library");

/**
 * Maps a Play base-plan tag or App Store product id to the canonical plan
 * name we persist in Firestore. Must stay in sync with the Flutter StravaPlan enum.
 */
function planNameFor(platform, productId, basePlanId) {
  if (platform === "android") {
    if (basePlanId === "monthly") return "monthly";
    if (basePlanId === "yearly") return "yearly";
  } else if (platform === "ios") {
    if (productId === "strava_sync_monthly") return "monthly";
    if (productId === "strava_sync_yearly") return "yearly";
  }
  return null;
}

const ANDROID_PACKAGE_NAME = "com.jonaskeller14.bike_setup_tracker";
const ANDROID_PRODUCT_ID = "strava_sync";
// Google Play Pub/Sub topic — create in Google Cloud Console and configure in
// Play Console → Monetize → Subscriptions → Real-time developer notifications
const PLAY_PUBSUB_TOPIC = "play-subscription-events";

// ── verifySubscription ────────────────────────────────────────────────────────

/**
 * STRATEGY: verifySubscription
 * Called by the client after a successful in_app_purchase flow. Validates the
 * purchase with the platform's billing API and writes the canonical entitlement
 * (including the bridge token for webhook lookups) to Firestore.
 */
exports.verifySubscription = onCall(
  {
    enforceAppCheck: true,
    secrets: [
      "GOOGLE_PLAY_SERVICE_ACCOUNT",
      "APP_STORE_KEY_ID",
      "APP_STORE_ISSUER_ID",
      "APP_STORE_PRIVATE_KEY",
      "APP_STORE_BUNDLE_ID",
    ],
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const { platform, productId, purchaseToken } = request.data || {};
    if (!platform || !productId || !purchaseToken) {
      throw new HttpsError(
        "invalid-argument",
        "platform, productId and purchaseToken are required."
      );
    }

    let entitlement;
    try {
      if (platform === "android") {
        entitlement = await verifyGooglePlayPurchase(productId, purchaseToken);
      } else if (platform === "ios") {
        entitlement = await verifyAppStorePurchase(productId, purchaseToken);
      } else {
        throw new HttpsError("invalid-argument", `Unknown platform: ${platform}`);
      }
    } catch (e) {
      logger.error("VERIFY_FAILED", { userId, platform, productId, error: e.message });
      throw new HttpsError("permission-denied", `Verification failed: ${e.message}`);
    }

    if (!entitlement) {
      throw new HttpsError("permission-denied", "Purchase is not active.");
    }

    await db.collection("users").doc(userId).set(
      { entitlement: { strava: entitlement } },
      { merge: true }
    );

    logger.info("ENTITLEMENT_WRITTEN", {
      userId,
      plan: entitlement.plan,
      platform: entitlement.platform,
    });

    return { ok: true, expiresAt: entitlement.expiresAt.toMillis() };
  }
);

// ── playSubscriptionWebhook ───────────────────────────────────────────────────

/**
 * STRATEGY: Google Play Real-time Developer Notifications
 *
 * Play publishes to the configured Pub/Sub topic whenever a subscription
 * event occurs (renewal, cancellation, refund, etc.). We look up the user
 * by purchaseToken and update their Firestore entitlement accordingly.
 *
 * Setup (one-time, done by developer):
 *   1. Google Cloud Console → Pub/Sub → create topic "play-subscription-events"
 *   2. Grant google-play-developer-notifications@system.gserviceaccount.com
 *      the "Pub/Sub Publisher" role on that topic.
 *   3. Play Console → Monetize → Subscriptions → Real-time developer
 *      notifications → enable → paste full topic resource name.
 */
exports.playSubscriptionWebhook = onMessagePublished(
  {
    topic: PLAY_PUBSUB_TOPIC,
    region: "europe-west3",
    secrets: ["GOOGLE_PLAY_SERVICE_ACCOUNT"],
  },
  async (event) => {
    // Pub/Sub message data is base64-encoded JSON.
    const raw = Buffer.from(event.data.message.data, "base64").toString("utf8");
    const message = JSON.parse(raw);

    // Play sends a testNotification when you first configure the topic —
    // acknowledge it but take no action.
    if (message.testNotification) {
      logger.info("PLAY_TEST_NOTIFICATION_RECEIVED");
      return;
    }

    const notification = message.subscriptionNotification;
    if (!notification) {
      logger.info("PLAY_UNKNOWN_MESSAGE_FORMAT", { message });
      return;
    }

    const { purchaseToken, notificationType } = notification;
    if (!purchaseToken) {
      logger.warn("PLAY_MISSING_PURCHASE_TOKEN");
      return;
    }

    logger.info("PLAY_NOTIFICATION", { notificationType, purchaseToken: purchaseToken.slice(0, 20) });

    // Look up the user by the stored purchaseToken.
    const userSnap = await db.collection("users")
      .where("entitlement.strava.purchaseToken", "==", purchaseToken)
      .limit(1)
      .get();

    if (userSnap.empty) {
      // Token not yet stored — the user subscribed but hasn't opened the app
      // so verifySubscription hasn't run yet. Ignore: the next app open will
      // call verifySubscription and store the token.
      logger.info("PLAY_NO_USER_FOR_TOKEN");
      return;
    }

    const userRef = userSnap.docs[0].ref;

    // See https://developer.android.com/google/play/billing/rtdn-reference#sub
    switch (notificationType) {
      case 1:  // SUBSCRIPTION_RECOVERED
      case 2:  // SUBSCRIPTION_RENEWED
      case 7:  // SUBSCRIPTION_RESTARTED
        await _refreshPlayEntitlement(userRef, purchaseToken);
        break;

      case 12: // SUBSCRIPTION_REVOKED (immediate refund)
      case 13: // SUBSCRIPTION_EXPIRED
        await _expireEntitlement(userRef, "android");
        break;

      case 3:  // SUBSCRIPTION_CANCELED — still valid until period end; mark autoRenewing false
        await userRef.update({ "entitlement.strava.autoRenewing": false });
        logger.info("PLAY_SUBSCRIPTION_CANCELED", { purchaseToken: purchaseToken.slice(0, 20) });
        break;

      case 5:  // SUBSCRIPTION_ON_HOLD — payment failed, user loses access until RECOVERED
      case 10: // SUBSCRIPTION_PAUSED — user explicitly paused, loses access until RESTARTED
        await _expireEntitlement(userRef, "android");
        break;

      case 9:  // SUBSCRIPTION_DEFERRED — expiry was extended; refresh to update expiresAt
        await _refreshPlayEntitlement(userRef, purchaseToken);
        break;

      case 6:  // SUBSCRIPTION_IN_GRACE_PERIOD — keep access during grace period
      default:
        logger.info("PLAY_NOTIFICATION_NO_ACTION", { notificationType });
        break;
    }
  }
);

/**
 * Re-queries the Play API to get the latest expiresAt and writes it to
 * Firestore. Called on renewal/recovery events.
 */
async function _refreshPlayEntitlement(userRef, purchaseToken) {
  const credentials = JSON.parse(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT);
  const authClient = new google.auth.JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const androidPublisher = google.androidpublisher({ version: "v3", auth: authClient });

  const res = await androidPublisher.purchases.subscriptionsv2.get({
    packageName: ANDROID_PACKAGE_NAME,
    token: purchaseToken,
  });
  const purchase = res.data;
  const lineItem = purchase.lineItems?.[0];
  if (!lineItem) {
    logger.warn("PLAY_REFRESH_NO_LINE_ITEM", { purchaseToken: purchaseToken.slice(0, 20) });
    return;
  }

  const expiry = lineItem.expiryTime ? new Date(lineItem.expiryTime) : null;
  if (!expiry) return;

  const basePlanId = lineItem.offerDetails?.basePlanId;
  const plan = planNameFor("android", lineItem.productId || ANDROID_PRODUCT_ID, basePlanId);

  await userRef.update({
    "entitlement.strava.expiresAt": admin.firestore.Timestamp.fromDate(expiry),
    "entitlement.strava.autoRenewing": purchase.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE",
    ...(plan && { "entitlement.strava.plan": plan }),
  });

  logger.info("PLAY_ENTITLEMENT_REFRESHED", {
    plan,
    expiresAt: expiry.toISOString(),
  });
}

// ── appStoreServerNotifications ───────────────────────────────────────────────

/**
 * STRATEGY: Apple App Store Server Notifications V2
 *
 * Apple POSTs to this endpoint for every subscription lifecycle event.
 * We verify the JWS payload using Apple's official library and update
 * the Firestore entitlement.
 *
 * Setup (one-time, done by developer):
 *   App Store Connect → Monetization → Subscriptions →
 *   App Store Server Notifications → paste this function's URL:
 *   https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/appStoreServerNotifications
 *   Select "Production server notifications".
 */
exports.appStoreServerNotifications = onRequest(
  {
    region: "europe-west3",
    secrets: [
      "APP_STORE_KEY_ID",
      "APP_STORE_ISSUER_ID",
      "APP_STORE_PRIVATE_KEY",
      "APP_STORE_BUNDLE_ID",
    ],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const signedPayload = req.body?.signedPayload;
    if (!signedPayload) {
      return res.status(400).send("Missing signedPayload");
    }

    const bundleId = process.env.APP_STORE_BUNDLE_ID;

    // Try production verifier first, then sandbox. Apple recommends always
    // trying production first and only falling back to sandbox on failure.
    let notification;
    for (const env of [Environment.PRODUCTION, Environment.SANDBOX]) {
      try {
        const verifier = _buildAppleVerifier(env, bundleId);
        notification = await verifier.verifyAndDecodeNotification(signedPayload);
        break;
      } catch (e) {
        if (env === Environment.PRODUCTION) continue; // try sandbox next
        logger.error("APPLE_NOTIFICATION_VERIFY_FAILED", { error: e.message });
        return res.status(200).send("OK"); // return 200 to prevent Apple retries for bad payloads
      }
    }

    if (!notification) {
      return res.status(200).send("OK");
    }

    const { notificationType, data } = notification;

    logger.info("APPLE_NOTIFICATION", { notificationType, subtype: notification.subtype });

    // TEST notification — acknowledge, no action.
    if (notificationType === NotificationTypeV2.TEST) {
      logger.info("APPLE_TEST_NOTIFICATION_RECEIVED");
      return res.status(200).send("OK");
    }

    // All subscription events carry a signedTransactionInfo in data.
    if (!data?.signedTransactionInfo) {
      return res.status(200).send("OK");
    }

    // Decode the transaction to get originalTransactionId and expiresDate.
    const verifier = _buildAppleVerifier(
      data.environment === "Sandbox" ? Environment.SANDBOX : Environment.PRODUCTION,
      bundleId
    );
    const transaction = await verifier.verifyAndDecodeTransaction(data.signedTransactionInfo);
    const { originalTransactionId, expiresDate, productId: txProductId } = transaction;

    if (!originalTransactionId) {
      return res.status(200).send("OK");
    }

    // Look up the user by originalTransactionId.
    const userSnap = await db.collection("users")
      .where("entitlement.strava.originalTransactionId", "==", originalTransactionId)
      .limit(1)
      .get();

    if (userSnap.empty) {
      // Not yet stored — same as Play: user hasn't opened app yet.
      logger.info("APPLE_NO_USER_FOR_TRANSACTION", { originalTransactionId });
      return res.status(200).send("OK");
    }

    const userRef = userSnap.docs[0].ref;

    switch (notificationType) {
      case NotificationTypeV2.DID_RENEW: {
        // expiresDate comes from the decoded transaction (milliseconds epoch).
        const expiry = expiresDate ? new Date(expiresDate) : null;
        if (!expiry) break;
        const plan = planNameFor("ios", txProductId, null);
        await userRef.update({
          "entitlement.strava.expiresAt": admin.firestore.Timestamp.fromDate(expiry),
          "entitlement.strava.autoRenewing": true,
          ...(plan && { "entitlement.strava.plan": plan }),
        });
        logger.info("APPLE_ENTITLEMENT_RENEWED", { expiresAt: expiry.toISOString() });
        break;
      }

      case NotificationTypeV2.EXPIRED:
      case NotificationTypeV2.GRACE_PERIOD_EXPIRED:
      case NotificationTypeV2.REFUND:
      case NotificationTypeV2.REVOKE:
        await _expireEntitlement(userRef, "ios");
        break;

      case NotificationTypeV2.DID_CHANGE_RENEWAL_STATUS: {
        // AUTO_RENEW_DISABLED = user canceled; AUTO_RENEW_ENABLED = user re-enabled.
        // The subscription is still active until expiresAt — only autoRenewing changes.
        const autoRenewing = notification.subtype !== "AUTO_RENEW_DISABLED";
        await userRef.update({ "entitlement.strava.autoRenewing": autoRenewing });
        logger.info("APPLE_AUTO_RENEW_STATUS_UPDATED", { autoRenewing });
        break;
      }

      case NotificationTypeV2.SUBSCRIBED: {
        if (notification.subtype === "RESUBSCRIBE") {
          // User resubscribed outside the app — client verifySubscription won't run,
          // so the webhook is the only mechanism to update Firestore.
          const expiry = expiresDate ? new Date(expiresDate) : null;
          if (!expiry) break;
          const plan = planNameFor("ios", txProductId, null);
          await userRef.update({
            "entitlement.strava.expiresAt": admin.firestore.Timestamp.fromDate(expiry),
            "entitlement.strava.autoRenewing": true,
            ...(plan && { "entitlement.strava.plan": plan }),
          });
          logger.info("APPLE_ENTITLEMENT_RESUBSCRIBED", { expiresAt: expiry.toISOString() });
        }
        // INITIAL_BUY: client writes entitlement via verifySubscription.
        break;
      }

      case NotificationTypeV2.DID_FAIL_TO_RENEW: // grace period active; wait for DID_RENEW or GRACE_PERIOD_EXPIRED
      case NotificationTypeV2.DID_CHANGE_RENEWAL_PREF: // plan switch takes effect at next renewal via DID_RENEW
      default:
        logger.info("APPLE_NOTIFICATION_NO_ACTION", { notificationType });
        break;
    }

    // Always respond 200 — Apple retries on non-2xx.
    return res.status(200).send("OK");
  }
);

// Apple's root CAs are not shipped with @apple/app-store-server-library —
// they must be downloaded from https://www.apple.com/certificateauthority/
// and bundled with the function. Loaded once at module load.
const _appleRootCerts = (() => {
  const fs = require("fs");
  const path = require("path");
  const dir = path.join(__dirname, "apple-certs");
  return fs.readdirSync(dir)
    .filter(f => f.endsWith(".cer") || f.endsWith(".pem"))
    .map(f => fs.readFileSync(path.join(dir, f)));
})();

function _buildAppleVerifier(environment, bundleId) {
  return new SignedDataVerifier(
    _appleRootCerts,
    false,        // enableOnlineChecks: false to avoid OCSP calls from Cloud Functions
    environment,
    bundleId
  );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

/**
 * Sets entitlement.strava.expiresAt to now, effectively revoking access.
 * Used for refunds, expirations, and revocations.
 */
async function _expireEntitlement(userRef, platform) {
  await userRef.update({
    "entitlement.strava.expiresAt": admin.firestore.Timestamp.now(),
    "entitlement.strava.autoRenewing": false,
  });
  logger.info("ENTITLEMENT_EXPIRED", { platform, userId: userRef.id });
}

// ── verifyGooglePlayPurchase ──────────────────────────────────────────────────

async function verifyGooglePlayPurchase(productId, purchaseToken) {
  const credentials = JSON.parse(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT);
  const authClient = new google.auth.JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });

  const androidPublisher = google.androidpublisher({ version: "v3", auth: authClient });

  const res = await androidPublisher.purchases.subscriptionsv2.get({
    packageName: ANDROID_PACKAGE_NAME,
    token: purchaseToken,
  });
  const purchase = res.data;

  if (
    purchase.subscriptionState !== "SUBSCRIPTION_STATE_ACTIVE" &&
    purchase.subscriptionState !== "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
  ) {
    return null;
  }

  const lineItem = purchase.lineItems?.[0];
  if (!lineItem) return null;

  const basePlanId = lineItem.offerDetails?.basePlanId;
  const expiry = lineItem.expiryTime ? new Date(lineItem.expiryTime) : null;
  const plan = planNameFor("android", lineItem.productId || ANDROID_PRODUCT_ID, basePlanId);
  if (!plan || !expiry) return null;

  return {
    plan,
    expiresAt: admin.firestore.Timestamp.fromDate(expiry),
    productId: lineItem.productId || ANDROID_PRODUCT_ID,
    platform: "android",
    autoRenewing: purchase.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE",
    purchaseToken,                          // bridge for webhook lookups
  };
}

// ── verifyAppStorePurchase ────────────────────────────────────────────────────

async function verifyAppStorePurchase(productId, transactionId) {
  const token = _signAppStoreJwt();

  const fetchTransaction = async (env) => {
    const host = env === "sandbox"
      ? "https://api.storekit-sandbox.itunes.apple.com"
      : "https://api.storekit.itunes.apple.com";
    return fetch(
      `${host}/inApps/v1/transactions/${transactionId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
  };

  let response = await fetchTransaction("production");
  if (response.status === 404) response = await fetchTransaction("sandbox");
  if (!response.ok) {
    throw new Error(`App Store API ${response.status}: ${response.statusText}`);
  }

  const body = await response.json();
  const decoded = jwt.decode(body.signedTransactionInfo);
  if (!decoded) throw new Error("Could not decode App Store transaction.");

  if (decoded.productId !== productId) {
    throw new Error(`Transaction productId mismatch: ${decoded.productId}`);
  }

  const expiry = decoded.expiresDate ? new Date(decoded.expiresDate) : null;
  if (!expiry || expiry < new Date()) return null;

  const plan = planNameFor("ios", decoded.productId, null);
  if (!plan) return null;

  return {
    plan,
    expiresAt: admin.firestore.Timestamp.fromDate(expiry),
    productId: decoded.productId,
    platform: "ios",
    autoRenewing: true,
    originalTransactionId: decoded.originalTransactionId, // bridge for webhook lookups
  };
}

function _signAppStoreJwt() {
  const kid = process.env.APP_STORE_KEY_ID;
  const iss = process.env.APP_STORE_ISSUER_ID;
  const bundleId = process.env.APP_STORE_BUNDLE_ID;
  const privateKey = process.env.APP_STORE_PRIVATE_KEY.replace(/\\n/g, "\n");

  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iss,
      iat: now,
      exp: now + 60 * 30,
      aud: "appstoreconnect-v1",
      bid: bundleId,
    },
    privateKey,
    { algorithm: "ES256", keyid: kid }
  );
}
