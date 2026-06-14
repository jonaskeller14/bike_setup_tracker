import AppIntents
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

// MARK: - App Intents (Apple Shortcuts / Siri)
//
// These expose "Add a Setup" and "Add a Task" in the Shortcuts app and via Siri.
// Each intent simply opens the app's existing deep link; the Flutter-side
// DeepLinkService (lib/services/deep_link_service.dart) maps the URL to the
// matching add flow (SetupActions.addSetup / TaskActions.addTaskRule).
// iOS 18+ only — on older versions the provider is never registered (graceful no-op).

@available(iOS 18.0, *)
struct AddSetupIntent: AppIntent {
  static var title: LocalizedStringResource = "Add a Setup"
  static var description = IntentDescription("Start creating a new setup.")

  func perform() async throws -> some IntentResult & OpensIntent {
    return .result(
      opensIntent: OpenURLIntent(URL(string: "bike-setup-tracker://add-setup")!)
    )
  }
}

@available(iOS 18.0, *)
struct AddBikeIntent: AppIntent {
  static var title: LocalizedStringResource = "Add a Bike"
  static var description = IntentDescription("Start adding a new bike.")

  func perform() async throws -> some IntentResult & OpensIntent {
    return .result(
      opensIntent: OpenURLIntent(URL(string: "bike-setup-tracker://add-bike")!)
    )
  }
}

@available(iOS 18.0, *)
struct AddComponentIntent: AppIntent {
  static var title: LocalizedStringResource = "Add a Component"
  static var description = IntentDescription("Start adding a new component.")

  func perform() async throws -> some IntentResult & OpensIntent {
    return .result(
      opensIntent: OpenURLIntent(URL(string: "bike-setup-tracker://add-component")!)
    )
  }
}

@available(iOS 18.0, *)
struct AddTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Add a Task"
  static var description = IntentDescription("Start creating a new maintenance task.")

  func perform() async throws -> some IntentResult & OpensIntent {
    return .result(
      opensIntent: OpenURLIntent(URL(string: "bike-setup-tracker://add-task")!)
    )
  }
}

@available(iOS 18.0, *)
struct BikeTrackerAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddSetupIntent(),
      phrases: [
        "Add a setup with \(.applicationName)",
        "New setup in \(.applicationName)",
      ],
      shortTitle: "Add a Setup",
      systemImageName: "plus.circle"
    )
    AppShortcut(
      intent: AddBikeIntent(),
      phrases: [
        "Add a bike with \(.applicationName)",
        "New bike in \(.applicationName)",
      ],
      shortTitle: "Add a Bike",
      systemImageName: "bicycle"
    )
    AppShortcut(
      intent: AddComponentIntent(),
      phrases: [
        "Add a component with \(.applicationName)",
        "New component in \(.applicationName)",
      ],
      shortTitle: "Add a Component",
      systemImageName: "gearshape"
    )
    AppShortcut(
      intent: AddTaskIntent(),
      phrases: [
        "Add a task with \(.applicationName)",
        "New task in \(.applicationName)",
      ],
      shortTitle: "Add a Task",
      systemImageName: "checklist"
    )
  }
}
