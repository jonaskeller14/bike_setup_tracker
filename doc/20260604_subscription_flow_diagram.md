# Subscription Client Flow

Visualizes the client-side purchase / restore / verification flow in
[`lib/services/subscription_service.dart`](../lib/services/subscription_service.dart).
Firestore is the single source of truth; the client never grants entitlement
itself — it calls `verifySubscription`, then reacts to the Firestore listener.
See [20260522_subscription_architecture.md](20260522_subscription_architecture.md)
for the backend/webhook side.

---

## 1. Entry points → restore/purchase

```mermaid
flowchart TD
    init["initialize(enableStrava)"] --> bind["_bindUser()\nsign in + attach Firestore listener\n(BEFORE restore — verify needs auth)"]
    bind --> avail{"_storeAvailable?"}
    avail -- no --> idle["state = Idle"]
    avail -- yes --> load["_loadProducts()"]
    load --> autoRestore["_beginRestore()\nunawaited restorePurchases()\n(silent: _userInitiatedRestore = false)"]

    resume["didChangeAppLifecycleState(resumed)"] --> cooldown{"inactive &&\nstore avail &&\nnot restoring &&\n>30min since last?"}
    cooldown -- yes --> autoRestore
    cooldown -- no --> stop1["ignore"]

    lapse["Firestore listener:\nactive → inactive"] --> lapseGuard{"store avail &&\nnot restoring?"}
    lapseGuard -- yes --> autoRestore
    lapseGuard -- no --> stop2["ignore"]

    tap["restorePurchases() (paywall button)"] --> userFlag["_userInitiatedRestore = true\n_beginRestore()\nstate = Restoring"]
    userFlag --> userRestore["await iap.restorePurchases()"]

    buy["buy(plan)"] --> buyState["state = Purchasing\niap.buyNonConsumable()"]

    autoRestore --> stream(["purchaseStream"])
    userRestore --> stream
    buyState --> stream
```

---

## 2. `_beginRestore` timeout guard (finding-fix #1)

The 5s timer is a watchdog for *the stream staying silent*. If a purchase
event arrives, the state leaves `Restoring`, so the timeout must NOT report
"nothing found" — otherwise a slow verify (cold Cloud Function start or the
bounded transient retries) still in flight at 5s would wrongly tell the user no
purchase was found.

```mermaid
flowchart TD
    begin["_beginRestore()"] --> timer["start 5s Timer → _onRestoreTimeout"]
    timer --> wait{"event arrived\nwithin 5s?"}
    wait -- "yes: _onPurchaseUpdate runs" --> handled["state → Verifying / Purchasing / Idle\n_endRestore() cancels timer"]
    wait -- "no: timer fires" --> to["_onRestoreTimeout()"]
    to --> guard{"_userInitiatedRestore &&\nstate IS Restoring &&\n!hasStravaEntitlement?"}
    guard -- yes --> errNF["state = Error\n'No previous purchase found…'"]
    guard -- no --> silent["stay silent\n(auto-restore, or event already in flight)"]
    errNF --> endr["_endRestore()"]
    silent --> endr
```

---

## 3. `_onPurchaseUpdate` → `_verifyAndAcknowledge`

```mermaid
flowchart TD
    upd["_onPurchaseUpdate(purchases)"] --> sw{"pd.status"}

    sw -- pending --> pend["state = Purchasing"]
    sw -- canceled --> can["state = Idle"]
    sw -- "error (Android code 7\nITEM_ALREADY_OWNED)" --> owned["state = Restoring\nrestorePurchases()"]
    sw -- "error (other)" --> errOther["state = Error"]
    sw -- "purchased / restored" --> verify["granted = _verifyAndAcknowledge(pd)"]

    verify --> complete{"pendingCompletePurchase\n&& NOT (purchased && !granted)?"}
    complete -- yes --> done["completePurchase(pd)"]
    complete -- "no (paid but not granted)" --> requeue["leave un-completed →\nstore redelivers next launch\n(durable retry; avoids auto-refund)"]

    pend --> complete
    can --> complete
    owned --> complete
    errOther --> complete

    done --> endLoop["_endRestore()"]
    requeue --> endLoop
```

---

## 4. `_verifyAndAcknowledge` — verification + bounded retry

```mermaid
flowchart TD
    start["_verifyAndAcknowledge(pd, attempt)"] --> verifying["state = Verifying"]
    verifying --> cached{"restored &&\nentitlement already active?"}
    cached -- yes --> retTrue["state = Idle → return true"]
    cached -- no --> iosCheck{"iOS && missing txId?"}
    iosCheck -- yes --> retMissing["state = Error → return false"]
    iosCheck -- no --> callCf["call verifySubscription CF"]

    callCf -- success --> okFlag["if purchased: _justPurchasedStrava = true\nstate = Idle\n(Firestore listener emits entitlement)"]
    okFlag --> retTrue2["return true"]

    callCf -- "FirebaseFunctionsException" --> transient{"unauthenticated /\nunavailable /\ndeadline-exceeded\n&& attempt < 2?"}
    transient -- yes --> retry["ensureSignedIn()\nbackoff 2^attempt s\nrecurse attempt+1"]
    retry --> verifying
    transient -- no --> restoredCache{"restored &&\nentitlement active?"}
    restoredCache -- yes --> swallow["state = Idle\n(use cached) → return false"]
    restoredCache -- no --> lapsed{"permission-denied &&\nmessage ~ 'not active'?"}
    lapsed -- yes --> lapsedErr["state = Error\n'no longer active…' → return false"]
    lapsed -- no --> genErr["state = Error\n(_friendlyVerifyError) → return false"]

    callCf -- "other exception" --> genErr2["state = Error → return false"]
```

---

## State legend

| State | Meaning |
|-------|---------|
| `Idle` | Resolved; UI shows paywall or dashboard based on Firestore entitlement |
| `LoadingProducts` | Querying store product details |
| `Purchasing` | Purchase dialog launched / pending |
| `Verifying` | `verifySubscription` Cloud Function in flight |
| `Restoring` | `restorePurchases` in flight (watchdog timer running) |
| `Error` | Surfaced to the user via `errorMessage` |

`return true/false` from `_verifyAndAcknowledge` is **"newly verified this
call"**, used only to decide whether a *new* (`purchased`) purchase is safe to
acknowledge. Restored purchases are already acknowledged store-side, so they
always complete regardless of the return value.
