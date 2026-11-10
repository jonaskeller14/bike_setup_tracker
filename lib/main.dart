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
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_resolution.dart';
import 'models/app_settings.dart';
import 'pages/home_page.dart';
import 'pages/loading_error_page.dart';
import 'pages/onboarding_page.dart';
import 'repositories/app_repository.dart';
import 'repositories/component_catalog_repository.dart';
import 'repositories/filter_persistence.dart';
import 'services/app_hint_service.dart';
import 'services/backup_service.dart';
import 'services/catalog_migration_service.dart';
import 'services/database_migration_service.dart';
import 'services/deep_link_service.dart';
import 'services/error_reporter.dart';
import 'services/google_drive_service.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';
import 'services/quick_actions_service.dart';
import 'services/setup_activity_analysis_service.dart';
import 'services/strava_service.dart';
import 'services/subscription_service.dart';
import 'services/tip_service.dart';
import 'theme.dart';
import 'utils/regional_defaults.dart';

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

  configureSystemChrome();

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

void configureSystemChrome() {
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
}

BootErrorReporter recordBootError = recordNonFatal;

class LoadingGate extends StatefulWidget {
  final AppSettings appSettings;
  final AppRepository appRepository;
  final AppHintService appHintService;
  final SubscriptionService Function() createSubscriptionService;
  final StravaService Function(AppRepository, AppSettings) createStravaService;
  final bool enablePushNotifications;

  const LoadingGate({
    super.key,
    required this.appSettings,
    required this.appRepository,
    required this.appHintService,
    this.createSubscriptionService = SubscriptionService.new,
    this.createStravaService = StravaService.new,
    this.enablePushNotifications = true,
  });

  @override
  State<LoadingGate> createState() => _LoadingGateState();
}

class _LoadingGateState extends State<LoadingGate> {
  late final Future<void> _initialization;
  late final _catalogRepository = ComponentCatalogRepository(
    languageCode: () => appLocaleOf(widget.appSettings).languageCode,
  );

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  RegionalDefaults _deviceRegionalDefaults() {
    final dispatcher = PlatformDispatcher.instance;
    return regionalDefaults(
      deviceRegionCode(dispatcher.locales),
      alwaysUse24HourFormat: dispatcher.alwaysUse24HourFormat,
    );
  }

  Future<void> _initialize() async {
    try {
      await Future.wait([
        // Settings load best-effort: whatever was read before the failure is
        // kept, the rest stays at its code default.
        widget.appSettings.loadAppSettings(regionalDefaults: _deviceRegionalDefaults()).catchError(
          (Object e, StackTrace s) => recordBootError(e, s, reason: 'App settings failed to load'),
        ),
        _loadAndMigrate(),
        // Hints are cosmetic — a failure here must not block the app.
        widget.appHintService.load().catchError(
          (Object e, StackTrace s) => recordBootError(e, s, reason: 'App hints failed to load'),
        ),
      ]);
      await _restoreFilters();
      if (widget.appSettings.enableComponentPresets) {
        unawaited(CatalogMigrationService.run(widget.appRepository, _catalogRepository));
      }
    } catch (e, s) {
      if (!kDebugMode) unawaited(FirebaseAnalytics.instance.logEvent(name: 'app_init_failed'));
      recordBootError(e, s, reason: 'App initialization failed');
      rethrow;
    }
  }

  /// Runs once settings and data are loaded: restoring earlier would let the
  /// first recompute drop a bike whose row has not been read yet. Saving starts
  /// only afterwards, so nothing overwrites the saved criteria before they are read.
  Future<void> _restoreFilters() async {
    final appRepository = widget.appRepository;
    if (widget.appSettings.rememberFilters) {
      final saved = await FilterPersistence.load();
      if (saved != null) appRepository.filters.restore(saved);
    }
    appRepository.onFiltersChanged = () => unawaited(FilterPersistence.save(appRepository.filters));
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
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoadingErrorPage(),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: widget.appRepository.database),
              ChangeNotifierProvider<SetupActivityAnalysisService>(
                create: (_) => SetupActivityAnalysisService(
                  widget.appRepository.database,
                  hierarchy: () => widget.appRepository.componentHierarchy,
                ),
              ),
              Provider<ComponentCatalogRepository>.value(value: _catalogRepository),
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
                create: (context) => widget.createStravaService(widget.appRepository, widget.appSettings),
                update: (context, settings, appRepo, stravaService) {
                  if (settings.enableStrava) {
                    unawaited(stravaService!.update(appRepository: appRepo, appSettings: settings));
                  }
                  return stravaService!;
                },
              ),
              ChangeNotifierProxyProvider<AppSettings, SubscriptionService>(
                lazy: false,
                create: (context) => widget.createSubscriptionService(),
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
                if (widget.enablePushNotifications) NotificationService().init(widget.appRepository);
                return const BikeSetupTrackerApp();
              },
            ),
          );
        } else {
          return MaterialApp(
            theme: materialAppTheme,
            darkTheme: materialAppDarkTheme,
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
            debugShowCheckedModeBanner: false,
          );
        }
      },
    );
  }
}

class BikeSetupTrackerApp extends StatefulWidget {
  const BikeSetupTrackerApp({super.key});

  @override
  State<BikeSetupTrackerApp> createState() => _BikeSetupTrackerAppState();
}

class _BikeSetupTrackerAppState extends State<BikeSetupTrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The device language is an input to resolveAppLocale, so a system change has to rebuild.
  @override
  void didChangeLocales(List<Locale>? locales) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final (themeMode, localeCode, showOnboarding) = context.select<AppSettings, (ThemeMode, String?, bool)>(
      (settings) => (settings.themeMode, settings.localeCode, settings.showOnboarding),
    );
    final locale = resolveAppLocale(
      override: localeCode,
      deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
    );

    return MaterialApp(
      title: 'Bike Setup Tracker',
      theme: materialAppTheme,
      darkTheme: materialAppDarkTheme,
      themeMode: themeMode,
      locale: locale,
      localeResolutionCallback: keepRegionLocale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // For packages that format with the default locale, such as the calendar.
      // Our own text takes the language from context.l10n, which rebuilds on a
      // switch. Runs inside Localizations, so the date symbols are loaded first.
      builder: (context, child) {
        final loadedLocale = Localizations.localeOf(context);
        Intl.defaultLocale = loadedLocale.toString();
        unawaited(QuickActionsService().updateLocale(loadedLocale));
        unawaited(context.read<StravaService>().updateNotificationLanguage(loadedLocale.languageCode));
        return child!;
      },
      navigatorKey: NavigationService.navigatorKey,
      home: showOnboarding ? const OnboardingPage() : const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
