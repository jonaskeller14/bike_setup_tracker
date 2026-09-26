import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'models/app_settings.dart';
import 'pages/home_page.dart';
import 'pages/loading_error_page.dart';
import 'pages/onboarding_page.dart';
import 'repositories/app_repository.dart';
import 'repositories/component_preset_repository.dart';
import 'services/app_hint_service.dart';
import 'services/backup_service.dart';
import 'services/database_migration_service.dart';
import 'services/deep_link_service.dart';
import 'services/google_drive_service.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';
import 'services/quick_actions_service.dart';
import 'services/setup_activity_analysis_service.dart';
import 'services/strava_service.dart';
import 'services/subscription_service.dart';
import 'services/tip_service.dart';
import 'theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set on every launch: the flag is persisted, so a release build installed
  // over a debug one would otherwise inherit its disabled state.
  unawaited(FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode));

  if (!kDebugMode) {
    // These replace Flutter's own error printing, which is what surfaces stack
    // traces in the debug console.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
      return true;
    };
  }

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode 
        ? const AndroidDebugProvider() 
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode 
        ? const AppleDebugProvider() 
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  final appDatabase = AppDatabase();

  final appSettings = AppSettings();
  final appRepository = AppRepository(appDatabase);
  final appHintService = AppHintService(
    appRepository: appRepository,
    appSettings: appSettings,
  );

  runApp(
    LoadingGate(
      appSettings: appSettings,
      appRepository: appRepository,
      appHintService: appHintService,
    ),
  );
}

typedef BootErrorReporter = void Function(Object error, StackTrace stack, {required String reason});

void _reportBootErrorToCrashlytics(Object error, StackTrace stack, {required String reason}) {
  unawaited(
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: false),
  );
}

/// Startup failures never reach the global handlers: [LoadingGate] catches them
/// to show [LoadingErrorPage] or to degrade silently, so they must be reported
/// explicitly. Overridable so those paths can be tested without Firebase.
@visibleForTesting
BootErrorReporter recordBootError = _reportBootErrorToCrashlytics;

class LoadingGate extends StatefulWidget {
  final AppSettings appSettings;
  final AppRepository appRepository;
  final AppHintService appHintService;

  const LoadingGate({
    super.key,
    required this.appSettings,
    required this.appRepository,
    required this.appHintService,
  });

  @override
  State<LoadingGate> createState() => _LoadingGateState();
}

class _LoadingGateState extends State<LoadingGate> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait([
        // Settings load best-effort: whatever was read before the failure is
        // kept, the rest stays at its code default.
        widget.appSettings.loadAppSettings().catchError(
          (Object e, StackTrace s) => recordBootError(e, s, reason: 'App settings failed to load'),
        ),
        _loadAndMigrate(),
        // Hints are cosmetic — a failure here must not block the app.
        widget.appHintService.load().catchError(
          (Object e, StackTrace s) => recordBootError(e, s, reason: 'App hints failed to load'),
        ),
      ]);
    } catch (e, s) {
      if (!kDebugMode) unawaited(FirebaseAnalytics.instance.logEvent(name: 'app_init_failed'));
      recordBootError(e, s, reason: 'App initialization failed');
      rethrow;
    }
  }

  Future<void> _loadAndMigrate() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'bike_setup_tracker.sqlite'));
    final dbExists = await dbFile.exists();

    if (!dbExists) {
      debugPrint("Starting database migration to Drift...");
      final legacyData = await widget.appRepository.loadLegacyData();
      if (legacyData != null) {
        final migrationService = DatabaseMigrationService(widget.appRepository.database);
        await migrationService.migrateFromSelectedData(legacyData);
        debugPrint("Migration inserted data successfully.");

        // Save a backup of the final JSON state just in case.
        await BackupService.saveBackup(context: null, database: widget.appRepository.database);
      } else {
        // Null means the legacy blob failed to parse (an absent one decodes to
        // empty data). The user boots into an empty database and `dbExists`
        // suppresses any retry, so this is silent data loss.
        recordBootError(
          StateError('Legacy data failed to parse'),
          StackTrace.current,
          reason: 'Legacy migration skipped — user booted with an empty database',
        );
      }
      debugPrint("Database migration completed.");
    }

    await widget.appRepository.initialize();

    // Block the UI until the in-memory caches reflect the DB. Deep-link
    // handlers (shortcuts/App Actions) read these synchronously, so mounting
    // the navigator before the first emissions causes false-empty checks.
    await widget.appRepository.initialDataLoaded;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: materialAppTheme,
            home: const LoadingErrorPage(),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: widget.appRepository.database),
              ChangeNotifierProvider<SetupActivityAnalysisService>(
                create: (_) => SetupActivityAnalysisService(widget.appRepository.database),
              ),
              Provider<ComponentPresetRepository>(create: (_) => ComponentPresetRepository()),
              ChangeNotifierProvider.value(value: widget.appSettings),
              ChangeNotifierProvider.value(value: widget.appRepository),
              ListenableProxyProvider2<AppRepository, AppSettings, AppHintService>(
                create: (_) => widget.appHintService,
                update: (_, appRepository, appSettings, appHintService) {
                  appHintService!.update(
                    appRepository: appRepository,
                    appSettings: appSettings,
                  );
                  return appHintService;
                },
              ),
              ProxyProvider<AppRepository, BackupService>(
                lazy: false,
                create: (context) => BackupService(),
                update: (context, appRepo, backupService) => backupService!..update(appRepo.database),
              ),
              ChangeNotifierProxyProvider2<AppRepository, AppSettings, GoogleDriveService>(
                lazy: false,
                create: (context) => GoogleDriveService(widget.appRepository, widget.appRepository.database),
                update: (context, appRepo, settings, googleDriveService) {
                  if (settings.enableGoogleDrive) {
                    googleDriveService!.update(appRepository: appRepo);
                  }
                  return googleDriveService!;
                },
              ),
              ChangeNotifierProxyProvider2<AppSettings, AppRepository, StravaService>(
                lazy: false,
                create: (context) => StravaService(widget.appRepository, widget.appSettings),
                update: (context, settings, appRepo, stravaService) {
                  if (settings.enableStrava) {
                    unawaited(stravaService!.update(appRepository: appRepo, appSettings: settings));
                  }
                  return stravaService!;
                },
              ),
              ChangeNotifierProxyProvider<AppSettings, SubscriptionService>(
                lazy: false,
                create: (context) => SubscriptionService(),
                update: (context, settings, subscriptionService) {
                  unawaited(subscriptionService!.initialize(enableStrava: settings.enableStrava));
                  return subscriptionService;
                },
              ),
              ChangeNotifierProvider<TipService>(
                lazy: false,
                create: (context) {
                  final tipService = TipService();
                  unawaited(tipService.initialize());
                  return tipService;
                },
              ),
            ],
            child: Builder(
              builder: (context) {
                // Initialize Services after Snapshots are done and context is available
                unawaited(DeepLinkService().init());
                unawaited(QuickActionsService().init());
                NotificationService().init(widget.appRepository);
                return const BikeSetupTrackerApp();
              },
            ),
          );
        } else {
          return MaterialApp(
            theme: materialAppTheme,
            darkTheme: materialAppDarkTheme,
            themeMode: ThemeMode.system,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
            debugShowCheckedModeBanner: false,
          );
        }
      },
    );
  }
}

class BikeSetupTrackerApp extends StatelessWidget {
  const BikeSetupTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return MaterialApp(
      title: 'Bike Setup Tracker',
      theme: materialAppTheme,
      darkTheme: materialAppDarkTheme,
      themeMode: appSettings.themeMode,
      navigatorKey: NavigationService.navigatorKey,
      home: appSettings.showOnboarding ? const OnboardingPage() : const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
