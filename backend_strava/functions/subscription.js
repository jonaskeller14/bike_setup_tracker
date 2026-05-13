const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { db, logger, admin } = require("./firebase");
const { google } = require("googleapis");
const jwt = require("jsonwebtoken");

/**
 * Maps a Play base-plan tag or App Store product id to the canonical plan
 * name we persist in Firestore. Must stay in sync with the Flutter
 * `StravaPlan` enum.
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

/**
 * STRATEGY: verifySubscription
 *
 * Called by the client after a successful in_app_purchase flow. Validates
 * the purchase with the platform's billing API and writes the canonical
 * entitlement to `users/{authUid}.entitlement.strava`.
 *
 * Required secrets:
 *   GOOGLE_PLAY_SERVICE_ACCOUNT  — JSON of a service account with the
 *                                  "View financial data, orders, and..."
 *                                  permission in Play Console (Setup → API
 *                                  Access)
 *   APP_STORE_KEY_ID             — App Store Connect → Keys → "Key ID"
 *   APP_STORE_ISSUER_ID          — App Store Connect → Keys → "Issuer ID"
 *   APP_STORE_PRIVATE_KEY        — Contents of the AuthKey_*.p8 file (full
 *                                  -----BEGIN PRIVATE KEY----- block)
 *   APP_STORE_BUNDLE_ID          — App's bundle id, e.g. "com.example.bike"
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
      logger.error("VERIFY_FAILED", {
        userId,
        platform,
        productId,
        error: e.message,
      });
      throw new HttpsError("permission-denied", `Verification failed: ${e.message}`);
    }

    if (!entitlement) {
      throw new HttpsError("permission-denied", "Purchase is not active.");
    }

    await db.collection("users").doc(userId).set(
      {
        entitlement: { strava: entitlement },
      },
      { merge: true }
    );

    logger.info("ENTITLEMENT_WRITTEN", {
      userId,
      plan: entitlement.plan,
      expiresAt: entitlement.expiresAt,
    });

    return { ok: true, expiresAt: entitlement.expiresAt.toMillis() };
  }
);

/**
 * Google Play verification — uses Android Publisher API v3.
 * https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2/get
 */
async function verifyGooglePlayPurchase(productId, purchaseToken) {
  const credentials = JSON.parse(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT);
  const authClient = new google.auth.JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });

  const androidPublisher = google.androidpublisher({ version: "v3", auth: authClient });

  // Subscriptions V2 returns line items so we can identify the active base plan.
  const res = await androidPublisher.purchases.subscriptionsv2.get({
    packageName: ANDROID_PACKAGE_NAME,
    token: purchaseToken,
  });
  const purchase = res.data;

  if (purchase.subscriptionState !== "SUBSCRIPTION_STATE_ACTIVE" &&
      purchase.subscriptionState !== "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") {
    return null;
  }

  // lineItems[0] tells us which base plan is active.
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
  };
}

/**
 * App Store verification — uses App Store Server API.
 * https://developer.apple.com/documentation/appstoreserverapi/get_transaction_info
 *
 * `purchaseToken` from in_app_purchase on iOS is the transaction ID.
 */
async function verifyAppStorePurchase(productId, transactionId) {
  const token = signAppStoreJwt();

  // Use the production endpoint first; if 4xx with code 4040010, fall back
  // to sandbox. Apple recommends always trying prod first.
  const fetchTransaction = async (env) => {
    const host =
      env === "sandbox"
        ? "https://api.storekit-sandbox.itunes.apple.com"
        : "https://api.storekit.itunes.apple.com";
    const response = await fetch(
      `${host}/inApps/v1/transactions/${transactionId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    return response;
  };

  let response = await fetchTransaction("production");
  if (response.status === 404) {
    response = await fetchTransaction("sandbox");
  }
  if (!response.ok) {
    throw new Error(`App Store API ${response.status}: ${response.statusText}`);
  }

  const body = await response.json();
  // `signedTransactionInfo` is a JWS. We trust it because we just fetched it
  // from Apple's signed endpoint over TLS; for a paranoid path you'd verify
  // its signature against Apple's root certs.
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
    autoRenewing: true, // App Store doesn't give us this on a one-off lookup;
                       // App Store Server Notifications will set the precise
                       // value when renewal status changes.
  };
}

function signAppStoreJwt() {
  const kid = process.env.APP_STORE_KEY_ID;
  const iss = process.env.APP_STORE_ISSUER_ID;
  const bundleId = process.env.APP_STORE_BUNDLE_ID;
  const privateKey = process.env.APP_STORE_PRIVATE_KEY.replace(/\\n/g, "\n");

  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iss,
      iat: now,
      exp: now + 60 * 30, // 30 min, well under Apple's 60-min max
      aud: "appstoreconnect-v1",
      bid: bundleId,
    },
    privateKey,
    {
      algorithm: "ES256",
      keyid: kid,
    }
  );
}
