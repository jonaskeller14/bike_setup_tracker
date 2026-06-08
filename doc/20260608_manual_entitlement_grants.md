# Manual Entitlement Grants (Complimentary Access)

How to grant the Strava sync subscription to yourself and friends **without a purchase**, by
writing the entitlement document directly in Firestore. This is the lightweight "comp access"
approach — no code, no deploy, no native store gift codes.

See [20260522_subscription_architecture.md](20260522_subscription_architecture.md) for the
full paid-subscription architecture this builds on.

---

## TL;DR

Write `users/{uid}.entitlement.strava` by hand in the Firebase console with a far-future
`expiresAt`. The app reads it exactly like a real purchase, and nothing on the backend will
ever revoke it.

---

## Why this works

`StravaEntitlement.isActive` ([strava_entitlement.dart:28](../lib/models/strava/strava_entitlement.dart#L28))
only requires two fields to be present and valid:

| Field | Needed for | Notes |
|---|---|---|
| `plan` | `isActive` / UI labels | `"monthly"` or `"yearly"`; unknown values fall back to `monthly` |
| `expiresAt` | `isActive` | Set far in the future for permanent comp access |

Everything else (`productId`, `platform`, `autoRenewing`) has safe defaults in
`fromMap` and only affects cosmetic labels or grace-period timing.

**Nothing revokes a manual grant.** The store webhooks
([subscription.js:151](../backend_strava/functions/subscription.js#L151),
[:329](../backend_strava/functions/subscription.js#L329)) locate a user *only* by querying
`entitlement.strava.purchaseToken` (Android) or `entitlement.strava.originalTransactionId`
(iOS). A comp grant has **neither bridge token**, so no webhook can ever match it and call
`_expireEntitlement`. The client's auto-restore paths also short-circuit while
`hasStravaEntitlement` is true, so they never interfere either.

---

## The document to write

In the Firebase console, open `users/{uid}` and add the `entitlement` map:

```
users/{uid}
  entitlement
    strava
      plan         "yearly"                 // string
      expiresAt    January 1, 2099 00:00    // timestamp (far future)
      platform     "comp"                   // string — distinguishes comp from real purchases
      productId    "comp"                   // string
      autoRenewing false                    // boolean
    notes          "Alex (riding buddy)"    // string — your own admin annotation (optional)
```

Notes:
- `platform: "comp"` is harmless — `billingSource` simply echoes any unknown platform string
  ([strava_entitlement.dart:38](../lib/models/strava/strava_entitlement.dart#L38)). It also
  makes comp grants easy to spot in the console and filter later.
- `autoRenewing: false` is correct — there is no renewal. `isActive` then just checks
  `now < expiresAt` with no grace period, which is what we want.
- A top-level `entitlement.notes` field (sibling of `strava`) is a convenient place to record
  *who* a grant belongs to. It is ignored by every read path and preserved by every write
  path, so it is purely your own bookkeeping.

---

## Finding a user's UID

Each grant is pinned to the user's **anonymous Firebase UID**. To get it:

- **Your own:** double-tap the version number on the About page (added in commit `3f9ed799`).
- **A friend's:** have them do the same and send you the UID.

---

## Limitations — know these before relying on it

| Limitation | Detail |
|---|---|
| **Manual per user** | Each grant is a hand-written console entry. Fine for a few people; tedious at scale. |
| **No expiry automation** | If you set a dated `expiresAt` (not far-future), you must re-grant manually when it lapses. |
| **Anonymous UIDs are fragile** | The grant lives on one anonymous UID. If a friend **reinstalls, clears app data, or switches devices**, they get a *new* UID and the grant is stranded on the old one — you must re-grant to the new UID. |

If these start to hurt (growing list, churn, reinstalls), graduate to a redemption-code Cloud
Function (`redeemAccessCode`) that writes the same document automatically and lets users
re-claim on a new install by re-entering their code.

---

## Native store gift codes (for context)

| Platform | Native subscription gift/promo code? |
|---|---|
| **iOS** | **Yes** — App Store Connect *subscription Offer Codes*. Redeemed in-app or via the App Store; they generate a real transaction that flows through the existing `verifySubscription` + webhook pipeline with **no backend changes**. |
| **Android** | **No** — Google Play promo codes do not support subscriptions (only one-time in-app products and paid apps). A custom redemption code is the only cross-platform option. |

Because Android has no native equivalent, manual grants (or a custom redemption function)
remain the only way to comp friends on Play.

---

## ⚠️ Prerequisite: lock down Firestore rules

This entire scheme — and every real subscription — assumes `entitlement` is **only ever
written server-side**. Confirm your `firestore.rules` forbid clients from writing
`users/{uid}.entitlement`. If a client can write its own user document freely, anyone could
self-grant the subscription by writing `entitlement.strava.expiresAt`, and comp access would
be the least of the problem.
