# Subscription Architecture: Strava Sync

This document explains the end-to-end architecture for the optional Strava sync subscription
(monthly / yearly). It covers the backend, the Flutter client, and how the two stay in sync
across all app lifecycle states.

---

## Overview

The subscription is built on two pillars:

| Pillar | Role |
|--------|------|
| **Firestore** | Single source of truth. `users/{uid}.entitlement.strava` holds the canonical entitlement. The UI reacts to it in real-time via a Firestore listener. |
| **Platform billing APIs** | Google Play (Android) and App Store (iOS) own the actual subscription state. The backend validates purchases and keeps Firestore in sync via server-side webhooks. |

The client never trusts its own IAP events directly. Every purchase is validated server-side;
every renewal is updated server-side. The Flutter app only reads from Firestore.

---

## Firestore Document Shape

```
users/{uid}
  entitlement.strava
    plan                   "monthly" | "yearly"
    expiresAt              Timestamp
    autoRenewing           bool
    platform               "android" | "ios"
    productId              string
    purchaseToken          string   // Android — bridge for webhook user lookups
    originalTransactionId  string   // iOS — bridge for webhook user lookups
```

---

## Backend (`backend_strava/functions/subscription.js`)

### `verifySubscription` (Firebase Callable)

**When:** Called by the client immediately after a successful in-app purchase or manual restore.

**What it does:**
1. Receives `platform`, `productId`, `purchaseToken` from the client.
2. Calls the platform billing API (Play `subscriptionsv2.get` / App Store `/inApps/v1/transactions/{id}`) to validate the token server-side.
3. Writes the canonical entitlement — including `purchaseToken` / `originalTransactionId` — to Firestore.

**Why the bridge keys matter:** `purchaseToken` (Android) and `originalTransactionId` (iOS)
are written here and used by all future webhook calls to look up the correct Firestore user
document. Without this step, renewal webhooks cannot find the user.

**Token stability (Android):** `purchaseToken` is stable across renewals of the same
subscription. It only rotates on resubscribe-after-cancel or plan change — in those cases
the user must tap "Restore" once, which is acceptable per product requirements.

---

### `playSubscriptionWebhook` (Pub/Sub trigger)

**When:** Google Play publishes a message to the `play-subscription-events` Pub/Sub topic on
every subscription lifecycle event (renewal, cancellation, expiry, refund, …).

**What it does:**
1. Decodes the base64 Pub/Sub message.
2. Extracts `notificationType` and `purchaseToken`.
3. Looks up the user in Firestore by `entitlement.strava.purchaseToken`.
4. Acts based on notification type:

| notificationType | Name | Action |
|---|---|---|
| 1 | SUBSCRIPTION_RECOVERED | Re-query Play API → refresh `expiresAt` |
| 2 | SUBSCRIPTION_RENEWED | Re-query Play API → refresh `expiresAt` |
| 7 | SUBSCRIPTION_RESTARTED | Re-query Play API → refresh `expiresAt` |
| 12 | SUBSCRIPTION_REVOKED | Set `expiresAt` = now, `autoRenewing` = false |
| 13 | SUBSCRIPTION_EXPIRED | Set `expiresAt` = now, `autoRenewing` = false |
| 3, 5, 6, default | Canceled / On hold / Grace period | No action (still valid until expiry; EXPIRED fires later) |

**Why no action on type 3 (CANCELED):** The subscription remains valid until the current
period ends. Type 13 (EXPIRED) fires at that point and triggers the actual revocation.

**Observed latency (from GCP logs):** Renewal webhooks arrive within 5–10 seconds of
`expiresAt` in both sandbox and production.

---

### `appStoreServerNotifications` (HTTP POST)

**When:** Apple POSTs to this URL on every App Store subscription lifecycle event.

**What it does:**
1. Verifies and decodes the signed JWS payload using `@apple/app-store-server-library`.
2. Tries production verifier first, falls back to sandbox on failure.
3. Looks up the user by `entitlement.strava.originalTransactionId`.
4. Acts based on `notificationType`:

| notificationType | Action |
|---|---|
| `DID_RENEW` | Update `expiresAt`, set `autoRenewing = true` |
| `EXPIRED`, `GRACE_PERIOD_EXPIRED`, `REFUND`, `REVOKE` | Set `expiresAt` = now, `autoRenewing = false` |
| Others | No action |

**Always responds HTTP 200** to prevent Apple from retrying deliveries for bad or
unrecognised payloads.

---

## Client (`lib/services/subscription_service.dart`)

### `StravaEntitlement`

Immutable snapshot of `users/{uid}.entitlement.strava`, rebuilt from Firestore on every
listener event.

#### `isActive` — grace period logic

```dart
static const Duration _renewalGracePeriod = Duration(hours: 4);

bool get isActive {
  final now = DateTime.now();
  if (autoRenewing) {
    return now.isBefore(expiresAt.add(_renewalGracePeriod));
  }
  return now.isBefore(expiresAt);
}
```

**Why the grace period exists:**

At renewal time there is a 5–30 second window where `expiresAt` has technically passed on
the device clock but the renewal webhook has not yet updated Firestore. Any Firestore write
during that gap (FCM token refresh, settings sync, etc.) causes the snapshot listener to
re-emit with the stale `expiresAt`, making `isActive` briefly return `false`.

`autoRenewing = true` means the platform has committed to renewing. The 4-hour window safely
absorbs any realistic webhook delay without ever blocking a paying user. Canceled
subscriptions (`autoRenewing = false`) expire on the dot — no grace.

This is the same approach used by subscription management SDKs (e.g. RevenueCat).

---

### `SubscriptionService` — measures and why each exists

#### 1. Purchase stream listener (`_purchaseSub`)

Opened at `initialize()`, before any other async work. Receives platform purchase events:

| Event | Action |
|---|---|
| `pending` | Set status → `purchasing` |
| `purchased` / `restored` | Call `_verifyAndAcknowledge` → Cloud Function → Firestore updated |
| `error` | Set status → `error` with message |
| `canceled` | Set status → `idle` |

Always calls `_iap.completePurchase(pd)` when `pd.pendingCompletePurchase` is true.
Both stores require this acknowledgement; failing to call it causes the purchase to be
refunded after a grace period.

**Why open it immediately:** The `in_app_purchase` docs state that unfinished transactions
from the previous session are delivered as soon as the first listener is attached. If the
listener is added after `initState` completes, those transactions are missed.

---

#### 2. Firestore entitlement listener (`_entitlementSub`)

Streams `users/{uid}` and rebuilds `_entitlement` on every snapshot, then calls
`notifyListeners()` so the UI reacts.

**Lapse auto-restore (inside `_bindUser`):**

```dart
if (previousEntitlement?.isActive == true &&
    !(_entitlement?.isActive ?? false) &&
    _storeAvailable && !_isRestoring) {
  _beginRestore();
  _iap.restorePurchases();
}
```

**Why:** If a webhook is delayed beyond the 4-hour grace period and `isActive` goes `false`
while the app is open, this silently triggers a restore. `verifySubscription` refreshes
Firestore and the listener picks up the new `expiresAt`. The user sees no interruption.

---

#### 3. Init restore

```dart
_beginRestore();
unawaited(_iap.restorePurchases());
```

Called once on `initialize()`.

**Why:** The platform does not automatically surface active subscriptions at startup — only
unfinished (unacknowledged) transactions are replayed. `restorePurchases()` is the only way
to discover an active subscription on a fresh install or reinstall.

**Cost:** On Android, `restorePurchases()` queries BillingClient's **local cache** — fast
and no network. On iOS, it contacts Apple's servers once per launch.

---

#### 4. Lifecycle resume auto-restore (`didChangeAppLifecycleState`)

```dart
if (state != AppLifecycleState.resumed) return;
if (hasStravaEntitlement || !_storeAvailable || _isRestoring) return;
// 30-minute cooldown
_iap.restorePurchases();
```

**Why:** Safety net for "the app was backgrounded for a long time and a renewal happened
while it was closed." If the webhook updated Firestore during that time, the Firestore
listener picks it up immediately on resume and `hasStravaEntitlement` returns `true`,
so this branch short-circuits and no restore is triggered. It only fires when Firestore
still shows a lapsed entitlement on resume.

**Cooldown (`_autoRestoreCooldown = 30 min`):** Prevents hammering the store on rapid
background/foreground cycles. More important on iOS, which makes a network call to Apple.

---

#### 5. `_isRestoring` flag + 5-second timeout

`_beginRestore()` sets `_isRestoring = true`; `_endRestore()` clears it (called from
`_onPurchaseUpdate` after all purchase events in a batch are processed).

**Why the flag:** Suppresses the paywall flash during the brief restore window at app
launch. `strava.dart` shows a loading spinner instead of the paywall when
`isRestoring && !hasStravaEntitlement`.

**Why the 5-second timeout:** On iOS, if `restorePurchases()` finds no active subscription,
the purchase stream emits no events and `_onPurchaseUpdate` is never called. Without the
timeout, `_isRestoring` would stay `true` indefinitely and the paywall would never appear
for users who genuinely have no subscription.

---

#### 6. `_verifyAndAcknowledge` optimisation

For **restored** purchases, the Cloud Function call is skipped when an active entitlement
is already in Firestore:

```dart
if (pd.status == PurchaseStatus.restored && (_entitlement?.isActive ?? false)) {
  _setStatus(SubscriptionPurchaseStatus.idle);
  return;
}
```

**Why:** The webhook has already done the work. Calling `verifySubscription` again is a
redundant network round-trip. For new purchases (`purchased`) the call always runs.

---

## `StravaService` — `_checkEntitlementExpiry` (`lib/services/strava_service.dart`)

Called from `StravaService`'s own user-document Firestore listener whenever the user doc
updates while an athlete is still linked.

**What it does:** Detects `_wasEntitled → isEntitled` transitions to:
- **Active → lapsed:** Stop Firestore data listeners, wipe local SQLite Strava data.
- **Lapsed → active:** Restart data listeners (no full disconnect + re-auth needed).

**Why it duplicates the Firestore read:** `SubscriptionService` and `StravaService` are
separate `ChangeNotifier`s. `StravaService` owns the data listener lifecycle and SQLite
clearing; `SubscriptionService` owns the entitlement state. Keeping them decoupled avoids
introducing a direct service-to-service dependency.

**Grace period mirrors `StravaEntitlement.isActive`:**

```dart
static const Duration _renewalGracePeriod = Duration(hours: 4);

final buffer = autoRenewing ? _renewalGracePeriod : Duration.zero;
final isEntitled = expiresAt != null &&
    DateTime.now().isBefore(expiresAt.add(buffer));
```

**Why they must match:** If the grace period only applied to the UI but not here, the app
could show the Strava dashboard while simultaneously clearing its SQLite data — corrupting
the user's local state. The matching buffer ensures data is only cleared when the UI would
also show the paywall.

**`_wasEntitled` guard:** Transition detection prevents false-positive data clears on fresh
installs and re-auth flows where `entitlement` is absent before `verifySubscription` has
written a value for the first time.

---

## Lifecycle coverage summary

| Scenario | Mechanism |
|---|---|
| New purchase | Client IAP → `verifySubscription` CF → Firestore → listener |
| Auto-renewal (app open or backgrounded) | Play/Apple webhook → Firestore → listener |
| Auto-renewal (app closed) | Webhook fires regardless → Firestore updated → listener picks up on next open |
| Renewal gap (5–30 s, `autoRenewing=true`) | Grace period in `isActive` / `_checkEntitlementExpiry` — user sees nothing |
| Cold start with active subscription | Init restore → skips CF (entitlement already active in Firestore) |
| Cold start without subscription | Init restore → no events → 5-second timeout → `_isRestoring=false` → paywall |
| Resume with lapsed entitlement | Lifecycle resume restore → `verifySubscription` → Firestore → listener |
| Webhook missed beyond grace period | Firestore-lapse listener auto-restore → CF → Firestore |
| Manual "Restore" button | `restorePurchases()` → `verifySubscription` → Firestore → listener |
| Cancel then resubscribe (token rotates) | Client taps "Restore" once — new token written by `verifySubscription`; subsequent renewals use the new token and require no further action |

---

## Sandbox vs production

| Property | Sandbox | Production |
|---|---|---|
| Renewal cadence | ~30 minutes | 30 days |
| Webhook delivery latency | 5–10 seconds | 5–10 seconds |
| Grace period covers renewal gap | Yes | Yes |
| `PLAY_NO_USER_FOR_TOKEN` (7-day log) | Never observed | Expected: never |

The 4-hour grace period is intentionally conservative. In practice the webhook arrives in
under 30 seconds. The buffer exists to guard against exceptional backend slowness, not the
normal case.
