# Google Play Billing Library 8 Upgrade

**Status:** Code change applied & verified — pending manual store testing ·
**Created:** 2026-07-22 · **Hard deadline:** 2026-08-31

## Why this exists

Google Play emailed that **Bike Setup Tracker** ships a soon-to-be-deprecated
Google Play Billing Library (PBL) version. From **2026-08-31**, every APK/AAB in
**all tracks** (production, internal, closed, open testing) must use **PBL 8.0.0
or higher**, or new uploads will be **rejected**. PBL 9 is *recommended* but not
required; 8.0.0 is the mandatory floor.

> The app already in the store keeps working after the deadline — the block only
> hits *new uploads*. But since we can no longer ship any update without PBL 8
> after that date, this must land before the next release.

---

## TL;DR — what actually has to change

| Area | Change needed? | Effort |
|---|---|---|
| **Flutter dependency** (`in_app_purchase_android`) | **Yes** — bump `^0.4.0` → `^0.5.2` (Billing 7.1.1 → 8.0.0) | Small |
| **Dart client code** (`subscription_service.dart`) | **No** — confirmed: analyze clean, 813/813 tests green | Verify only |
| **Android native / Gradle** | **No** — PBL is pulled in transitively; no direct dependency to edit | None |
| **Backend** (`backend_strava/`) | **No** — uses the server-side Play Developer API, which is independent of PBL | None |
| **iOS / StoreKit** | **No** — unaffected by a Google Play requirement | None |

The whole job is **one dependency bump + a regression test of the purchase
flow**. There was an open question whether it would also force a Flutter SDK
upgrade — it does not; we were already on a new enough toolchain. See the
verification section.

---

## Starting state (before the bump, from `pubspec.lock`)

| Package | Constraint (`pubspec.yaml`) | Resolved | Bundled PBL |
|---|---|---|---|
| `in_app_purchase` | `^3.2.3` | `3.2.4` | — (federated) |
| `in_app_purchase_android` | `^0.4.0` | `0.4.0+11` | **7.1.1** ← the flagged one |
| `in_app_purchase_storekit` | `^0.4.8` | `0.4.10` | — (iOS) |

**Installed toolchain: Flutter 3.44.0 / Dart 3.12.0** (verified via
`flutter --version`). Note the `pubspec.yaml` constraint `sdk: ^3.9.2` is only
the declared *minimum* — it does not reflect the SDK actually in use. This
distinction turned out to be decisive (see below).

No direct `com.android.billingclient` dependency exists in
[android/app/build.gradle.kts](android/app/build.gradle.kts) — PBL arrives only
through the plugin, so there is nothing to pin manually.

## Target

`in_app_purchase_android` **≥ 0.5.0** bundles **PBL 8.0.0** (introduced in
0.5.0). The federated `in_app_purchase 3.3.0` already depends on
`in_app_purchase_android: ^0.5.0`, so the top-level package moves too.

---

## Which 0.5.x? — resolved empirically

The `0.5.x` line splits on SDK requirements:

| Plugin version | Dart SDK | Flutter | Notes |
|---|---|---|---|
| `0.5.0` / `0.5.0+1` | `^3.0.0` | `≥3.10.0` | `0.5.0+1` migrates to built-in Kotlin for AGP 9. |
| `0.5.1` / `0.5.2` (latest, 2026-07-20) | `^3.12.0` | `≥3.44.0` | Adds overlay billing messages, obfuscated profile id. |

All of these bundle **PBL 8.0.0** — the mandatory floor is satisfied by *any* `0.5.x`.

**The SDK split is a non-issue: we are already on Flutter 3.44.0 / Dart 3.12.0,**
so `0.5.2` is directly usable with **no toolchain upgrade at all**. There is no
"minimal vs. big upgrade" trade-off to make — go straight to the latest.

> Earlier drafts of this doc assumed Flutter 3.35 based on the `sdk: ^3.9.2`
> constraint in `pubspec.yaml`. That constraint is a floor, not the installed
> version. Always check `flutter --version`.

### ✅ Verification — actually executed, not predicted

The bump was applied and resolved locally on 2026-07-22:

1. **`flutter pub outdated`** — the solver's *Resolvable* column independently
   reported `in_app_purchase 3.3.0` and `in_app_purchase_android 0.5.2`,
   i.e. reachable within the existing full dependency graph.
2. **`flutter pub get`** → `Changed 2 dependencies!` — clean resolve, no conflict,
   no version-solving error. Exactly two packages moved:

   | Package | Before | After |
   |---|---|---|
   | `in_app_purchase` | 3.2.4 | **3.3.0** |
   | `in_app_purchase_android` | 0.4.0+11 (PBL 7.1.1) | **0.5.2 (PBL 8.0.0)** |
   | `in_app_purchase_storekit` | 0.4.10 | 0.4.10 *(unchanged)* |
   | `in_app_purchase_platform_interface` | 1.4.1 | 1.4.1 *(unchanged)* |

3. **`flutter analyze lib/services/subscription_service.dart`** → *No issues found.*
   Confirms the PBL 8 API removals do not touch our code (as predicted above).
4. **`flutter test`** → **all 813 tests passed.**
5. **`flutter build appbundle`** → **`app-release.aab` built, 81.7 MB.** The PBL 8
   AAR links and the default `flutter.compileSdkVersion` is sufficient — no
   `compileSdk` bump needed. Only pre-existing warnings (see below), no errors.

**Nothing else in the graph moved** — no cascade into drift, firebase_*,
syncfusion, or the known `excel`/`xml` pin. The feared Path-B blast radius does
not exist for this project.

### Side benefit: one less Built-in Kotlin migration blocker

The release build emits Flutter's KGP deprecation warning:

> *Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
> cloud_functions, device_info_plus, file_picker, file_save_directory,
> firebase_analytics, firebase_app_check, location, share_plus.
> Future versions of Flutter will fail to build if your app uses plugins that
> apply KGP.*

`in_app_purchase_android` is **notably absent** from that list — consistent with
its `0.5.0+1` changelog entry *"Migrates to Built-in Kotlin to support AGP 9."*
So this upgrade does not add to the KGP debt, and on the old `0.4.0+11` the
plugin would very likely have been listed. *(Not directly confirmed — no
before-build was captured for comparison.)*

**This is a separate, future problem**, unrelated to the billing deadline: the
eight plugins above will eventually need Built-in Kotlin–compatible versions
before a future Flutter release drops KGP support. Worth its own tracking item;
nothing blocks the PBL 8 release today.

### Housekeeping — done

`pubspec.yaml` previously declared `environment: sdk: ^3.9.2`, while
`in_app_purchase_android 0.5.2` itself requires `^3.12.0`. Pub resolved anyway
because it validates against the *running* SDK and the app is `publish_to: none` —
but the declared floor was misleading: a contributor on Dart 3.9.x could not have
resolved this project.

Raised to match reality, with an explicit Flutter floor so a toolchain mismatch
fails loudly (in CI too) instead of resolving into a confusing native build error:

```yaml
environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"
```

`flutter pub get` re-verified clean after the change.

---

## Dart code impact analysis

PBL 8 breaking changes in plugin `0.5.0`: removed `queryPurchaseHistory` /
`queryPurchaseHistoryAsync`; added `subResponseCode`,
`oneTimePurchaseOfferDetailsList`, `unfetchedProductList` (all additive).

Reviewed [lib/services/subscription_service.dart](lib/services/subscription_service.dart)
against these:

- Restore path uses `_iap.restorePurchases()` → backed by `queryPurchases` (the
  *current* purchases API), **not** the removed `queryPurchaseHistory`. ✅ safe.
- Subscription purchase path uses `GooglePlayProductDetails`,
  `subscriptionIndex`, `productDetails.subscriptionOfferDetails`, `basePlanId`,
  `offerToken`, `GooglePlayPurchaseParam` — all unchanged in PBL 8. ✅ safe.
- `PurchaseStatus.error` code `'7'` (ITEM_ALREADY_OWNED) handling — response
  codes are unchanged in PBL 8. ✅ safe.

**Conclusion:** no source changes anticipated. Treat any compile error after the
bump as the signal — if it builds and the flows below pass, we're done. The one
thing to watch is the additive `subscriptionOfferDetails` model shape, which the
`_planForProduct`/`_loadProducts` logic already navigates defensively.

---

## Why the backend needs nothing

`backend_strava/functions/subscription.js` validates purchases via the **Google
Play Developer API** (`androidpublisher v3` → `purchases.subscriptionsv2.get`)
using a service account — a **server-to-server REST API**. That API is versioned
and released **independently** of the client-side Play Billing Library. The
`purchaseToken` the client forwards to `verifySubscription` has the same shape
under PBL 8. Real-time developer notifications (Pub/Sub webhook) are likewise
unaffected.

> Sanity check worth doing once (not a code change): confirm the RTDN payload
> format version configured in Play Console is still what `playSubscriptionWebhook`
> parses. It has not changed for PBL 8, but it's a 2-minute verification.

---

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Purchase/restore regression from the plugin bump | Low–Med | **The only remaining real risk.** Static analysis and unit tests cannot cover the store round-trip — run the manual matrix below on a real device via the Play internal testing track before promoting. |
| ~~Dependency conflict / Flutter upgrade cascade~~ | **Ruled out** | Empirically verified: clean resolve, only 2 packages moved, 813/813 tests green. |
| ~~compileSdk too low for the PBL 8 AAR~~ | **Ruled out** | `flutter build appbundle` succeeded on the default `flutter.compileSdkVersion`. |
| `subscriptionOfferDetails` / offer-token shape shift | Low | Covered by the code analysis above; validated by the "buy monthly + yearly" test. |
| Missing the 2026-08-31 window | Med if deferred | It's ~5–6 weeks out; land Path A in the next release cycle. Existing store build is unaffected, only *new uploads* are blocked. |
| Purchase acknowledgement regression → auto-refunds | Low but high-impact | The `completePurchase` / pending-acknowledge logic is unchanged; explicitly verify a real purchase stays purchased (no auto-refund after ~3 days) on the internal track. |

---

## Test matrix (run on a real Android device via Play internal testing / license testers)

- [x] `flutter pub get` resolves cleanly; `flutter analyze` clean on
      `subscription_service.dart`; `flutter test` 813/813 green.
- [x] `flutter build appbundle` succeeds (confirms PBL 8 AAR + compileSdk OK).
- [ ] Products load: monthly + yearly show correct localized prices.
- [ ] Fresh **buy** (monthly) → `verifySubscription` → entitlement active in UI.
- [ ] Buy **yearly** → correct plan resolved (`basePlanId` mapping intact).
- [ ] **Restore** on a reinstall / second device with the same Play account.
- [ ] ITEM_ALREADY_OWNED (buy while already subscribed) → auto-restore path.
- [ ] Purchase is **acknowledged** (not auto-refunded after the grace window).
- [ ] Renewal webhook still updates `expiresAt` (sandbox renews ~every 30 min).
- [ ] Existing subscribers' entitlement unaffected after updating the app.

---

## Step-by-step

1. ~~`pubspec.yaml`: `in_app_purchase: ^3.3.0`, `in_app_purchase_android: ^0.5.2`~~ **done**
2. ~~`flutter pub get` → confirm lock resolves to `0.5.2`~~ **done**
3. ~~`flutter analyze lib/services/subscription_service.dart`~~ **done — clean**
4. ~~`flutter test`~~ **done — 813/813 green**
5. ~~`flutter build appbundle`~~ **done — `app-release.aab`, 81.7 MB**
6. ~~Raise `environment: sdk:` / add `flutter:` floor~~ **done** (housekeeping above)
7. **Run the manual store test matrix** on the Play internal testing track.
   ← **the only remaining substantive work**
8. Bump app version in [pubspec.yaml](pubspec.yaml#L20) (+ `lib/utils/app_info.dart`)
   and ship before **2026-08-31**.

### Follow-up, not part of this task

- Built-in Kotlin migration for the eight KGP plugins listed above, before a
  future Flutter release drops KGP support.

---

## Sources

- [in_app_purchase_android changelog (pub.dev)](https://pub.dev/packages/in_app_purchase_android/changelog)
- [Migrate to Google Play Billing Library 8 (Android Developers)](https://developer.android.com/google/play/billing/migrate-gpblv8)
- [Google Play Billing Library release notes](https://developer.android.com/google/play/billing/release-notes)
