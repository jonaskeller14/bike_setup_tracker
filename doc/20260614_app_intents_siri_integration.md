# App Intents & Siri Integration

**Date:** 2026-06-14  
**Context:** Current implementation uses simple deep-link shortcuts. This document explains the architecture and roadmap for richer Siri / Apple Intelligence integration.

---

## Current implementation

The app registers four `AppIntent` structs (`AddSetupIntent`, `AddBikeIntent`, `AddComponentIntent`, `AddTaskIntent`) via `BikeTrackerAppShortcuts`. Each intent:

1. Sets `openAppWhenRun = true` to foreground the app.
2. Calls `await UIApplication.shared.open(url)` to trigger a deep link.
3. The Flutter `DeepLinkService` picks up the URL and opens the matching screen.

This is the **simplest possible integration** — Siri hears a phrase, the app opens, done. No data flows back to Siri; no parameters are extracted from speech.

---

## Why `OpenURLIntent` was abandoned

`OpenURLIntent` is a system intent for opening **web URLs only** (`http`/`https`). Custom URL schemes like `bike-setup-tracker://` are explicitly prohibited. It also carries a semantic return type (`OpensIntent`) that signals to Apple Intelligence "this action opens something," which is useful for AI chaining — but since our intents are terminal (nothing meaningful chains after "open a screen"), the signal buys nothing here. `UIApplication.shared.open()` is the correct tool for custom scheme deep links.

---

## How rich Siri interactions work

To support examples like:

- *"Create a setup named Trail Ride"*
- *"What are my current settings?"*
- *"Create a new setup and increase the sag by 2mm"*

...the architecture needs to change significantly. The pieces are:

### 1. Intent parameters

Parameters let Siri extract structured data from the user's speech.

```swift
@available(iOS 16.0, *)
struct CreateSetupIntent: AppIntent {
    static var title: LocalizedStringResource = "Create a Setup"

    @Parameter(title: "Name")
    var name: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Call back into Flutter via MethodChannel or SharedPreferences
        let result = await BikeTrackerBridge.createSetup(name: name)
        return .result(dialog: "Created setup \(result.name).")
    }
}
```

Siri can now ask "What would you like to name it?" if the user doesn't provide it.

### 2. Entities and queries

For *"What are my current settings?"* Siri needs to fetch live data from the app. This requires conforming to `AppEntity` and `EntityQuery`.

```swift
@available(iOS 16.0, *)
struct SetupEntity: AppEntity {
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)") }
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Setup"
    static var defaultQuery = SetupQuery()
}

@available(iOS 16.0, *)
struct SetupQuery: EntityQuery {
    func entities(for ids: [String]) async throws -> [SetupEntity] {
        // Fetch from shared app group / SQLite
    }
    func suggestedEntities() async throws -> [SetupEntity] {
        // Return recent/all setups for Siri suggestions
    }
}
```

With entities in place, Siri can resolve *"my Trail Ride setup"* to a concrete `SetupEntity` and pass it to an intent.

### 3. Returning results to Siri (no app open required)

Intents can return dialogs and values **without opening the app**, which is critical for Siri responses and Apple Intelligence summaries.

```swift
func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
    let setup = try await fetchCurrentSetup()
    let summary = setup.adjustments.map { "\($0.name): \($0.value)" }.joined(separator: ", ")
    return .result(value: summary, dialog: "Your current settings are: \(summary)")
}
```

### 4. Multi-step intents (*"Create a setup and increase sag by 2mm"*)

This is the most complex case. Apple Intelligence (iOS 18+) can compose two intents when both are declared with proper semantic types. The key is combining a creation intent with an update intent that takes an entity as input.

```swift
@available(iOS 16.0, *)
struct UpdateAdjustmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Update Adjustment"

    @Parameter(title: "Setup")
    var setup: SetupEntity

    @Parameter(title: "Adjustment")
    var adjustment: AdjustmentEntity

    @Parameter(title: "Delta")
    var delta: Double

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let newValue = try await BikeTrackerBridge.updateAdjustment(
            setupId: setup.id,
            adjustmentId: adjustment.id,
            delta: delta
        )
        return .result(dialog: "\(adjustment.name) updated to \(newValue).")
    }
}
```

Apple Intelligence can chain `CreateSetupIntent → UpdateAdjustmentIntent` automatically if the output of the first intent (a `SetupEntity`) matches the `setup` parameter type of the second.

---

## The Flutter bridge problem

All rich intents need to **read and write app data** without the Flutter engine necessarily being warm. The options:

| Approach | Pros | Cons |
|---|---|---|
| **App Group SQLite** | Fast, direct, no Flutter needed | Must keep schema in sync with Drift |
| **App Group UserDefaults / JSON file** | Simple to write from Flutter | Only practical for small read-only data |
| **MethodChannel (app must be running)** | Full Flutter access | Intent fails if app is backgrounded/killed |
| **Background Flutter engine** | Full Dart logic reuse | Complex, high memory, Apple may kill it |

**Recommended path:** Write a lightweight read/write layer that uses an **App Group SQLite file** (same file Drift uses, opened read-only from Swift for queries, write via a simple JSON command file that Flutter processes on next launch for mutations). This avoids duplicating business logic while not requiring a live Flutter engine.

---

## Roadmap suggestion

| Phase | What | Complexity |
|---|---|---|
| **Now** | Deep-link shortcuts (current state) | Done |
| **Phase 1** | `CreateSetupIntent` with a `name` parameter, writes via shared file | Low |
| **Phase 2** | `SetupEntity` + `SetupQuery` so Siri can resolve setup names from speech | Medium |
| **Phase 3** | `QueryCurrentSettingsIntent` returning a dialog without opening app | Medium |
| **Phase 4** | `UpdateAdjustmentIntent` with entity + delta parameter | High |
| **Phase 5** | Apple Intelligence chaining (create + update in one sentence) | High — iOS 18+ only |

Phases 1–3 are compatible with iOS 16+. Phases 4–5 benefit from iOS 18 Apple Intelligence but the intents themselves can be declared for iOS 16 with graceful degradation.
