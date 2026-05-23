# Google Play Real-Time Developer Notifications — Subscription Handling

Reference: https://developer.android.com/google/play/billing/rtdn-reference#sub

Each Play subscription event triggers a Pub/Sub message to `playSubscriptionWebhook`.
The handler looks up the user by `purchaseToken` and updates their Firestore entitlement.

## Notification Type Handling

| Type | Name | Action | Reason |
|------|------|--------|--------|
| 1 | SUBSCRIPTION_RECOVERED | `_refreshPlayEntitlement` | User's account was recovered from hold after a successful payment. Re-query the Play API to restore the correct `expiresAt` and mark `autoRenewing: true`. |
| 2 | SUBSCRIPTION_RENEWED | `_refreshPlayEntitlement` | Subscription successfully renewed. Re-query to advance `expiresAt` to the next billing period. |
| 3 | SUBSCRIPTION_CANCELED | Set `autoRenewing: false` | User canceled but the subscription is still active until the current period ends. We do not expire it — Play will send EXPIRED (13) when access should actually stop. We only clear `autoRenewing` so the UI shows "Expires" instead of "Renews". |
| 4 | SUBSCRIPTION_PURCHASED | No action | New purchase. The client calls `verifySubscription` immediately after purchase, which writes the entitlement. The webhook fires at roughly the same time but the `purchaseToken` is unlikely to be in Firestore yet, so looking up the user would fail anyway. |
| 5 | SUBSCRIPTION_ON_HOLD | `_expireEntitlement` | Payment failed and the account is now on hold — the user has lost access. We expire immediately. If the user pays later, Play sends RECOVERED (1) which restores access. |
| 6 | SUBSCRIPTION_IN_GRACE_PERIOD | No action | Payment failed but the user is still within their grace period and retains access. We keep the entitlement intact and wait: Play sends RENEWED (2) on successful retry or EXPIRED (13) when grace expires. |
| 7 | SUBSCRIPTION_RESTARTED | `_refreshPlayEntitlement` | User restored a previously canceled subscription before it expired (i.e., un-canceled). Re-query to get the fresh `expiresAt` and mark `autoRenewing: true`. |
| 8 | SUBSCRIPTION_PRICE_CHANGE_CONFIRMED | No action | User accepted a price change. Takes effect at next renewal, which fires RENEWED (2). No entitlement fields change now. |
| 9 | SUBSCRIPTION_DEFERRED | `_refreshPlayEntitlement` | An admin or promo deferred (extended) the billing date. Re-query to pick up the new `expiresAt` so the user isn't shown a stale expiry date. |
| 10 | SUBSCRIPTION_PAUSED | `_expireEntitlement` | User explicitly paused their subscription — access stops immediately. When they resume, Play sends RESTARTED (7) which restores access. |
| 11 | SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED | No action | User changed their planned pause window but has not paused yet. No entitlement fields change. |
| 12 | SUBSCRIPTION_REVOKED | `_expireEntitlement` | Subscription was revoked mid-period (typically an immediate refund). Access stops immediately. |
| 13 | SUBSCRIPTION_EXPIRED | `_expireEntitlement` | Subscription reached end-of-life after cancellation or unresolved payment hold. Access stops. |
| 20 | SUBSCRIPTION_PENDING_PURCHASE_CANCELED | No action | A pending (e.g. cash-based) purchase was canceled before it completed. No active entitlement exists, so nothing to update. |

## Key design decisions

**We never expire on CANCELED (3).** The subscription is still paid up until its natural end date. Expiring early would incorrectly cut off a user who has already paid for the remaining period. Play always follows up with EXPIRED (13) when the time actually comes.

**ON_HOLD (5) expires immediately, GRACE_PERIOD (6) does not.** Google distinguishes these: grace period is a short window where the user still has access while Google retries payment; account hold is past that window and access is revoked by Google's policy. We mirror that distinction.

**DEFERRED (9) refreshes rather than being ignored.** Without a refresh, the stored `expiresAt` would show the old date, causing the UI to display an incorrect (earlier) expiry — and potentially trigger a spurious "expired" state on the client before the real expiry.

**PURCHASED (4) is left to the client.** The client flow calls `verifySubscription` synchronously after purchase, which is more reliable than a webhook race where the token isn't yet stored.
