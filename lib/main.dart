import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'models/app_settings.dart';
import 'repositories/app_repository.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'services/google_drive_service.dart';
import 'services/storage_service.dart';
import 'services/strava_service.dart';
import 'services/navigation_service.dart';
import 'services/deep_link_service.dart';
import 'services/quick_actions_service.dart';
import 'utils/file_export.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'database/app_database.dart';
import 'services/database_migration_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  debugPrint("Handling background message: ${message.messageId}");
}

final materialAppTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueGrey.shade700,
    brightness: Brightness.light,
  ),
);

final materialAppDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueGrey.shade700,
    brightness: Brightness.dark,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode 
        ? const AndroidDebugProvider() 
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode 
        ? const AppleDebugProvider() 
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  runApp(
    LoadingGate(
      appSettings: AppSettings(),
      appRepository: AppRepository(appDatabase),
    ),
  );
}

class LoadingGate extends StatelessWidget {
  final AppSettings appSettings;
  final AppRepository appRepository;

  const LoadingGate({
    super.key,
    required this.appSettings,
    required this.appRepository,
  });

  Future<void> _loadAndMigrate(BuildContext context) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'bike_setup_tracker.sqlite'));
    final dbExists = await dbFile.exists();

    if (!dbExists) {
      debugPrint("Starting database migration to Drift...");
      final legacyData = await appRepository.loadLegacyData();
      if (legacyData != null) {
        final migrationService = DatabaseMigrationService(appRepository.database);
        await migrationService.migrateFromSelectedData(legacyData);
        debugPrint("Migration inserted data successfully.");
        
        // Save a backup of the final JSON state just in case.
        await FileExport.saveBackup(context: null, database: appRepository.database);
      }
      debugPrint("Database migration completed.");
    }
    
    await appRepository.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        appSettings.loadAppSettings(),
        _loadAndMigrate(context),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 12,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    Text(
                      "Failed to load data. \nClose and restart the app.",
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    //TODO: Add button to send support email with debug file
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: appRepository.database),
              ChangeNotifierProvider.value(value: appSettings),
              ChangeNotifierProvider.value(value: appRepository),
              ProxyProvider<AppRepository, StorageService>(
                lazy: false,
                create: (context) => StorageService(),
                update: (context, appRepo, storageService) => storageService!..update(appRepository.database),
              ),
              ChangeNotifierProxyProvider2<AppRepository, AppSettings, GoogleDriveService>(
                lazy: false,
                create: (context) => GoogleDriveService(appRepository, appRepository.database),
                update: (context, appRepo, settings, googleDriveService) {
                  if (settings.enableGoogleDrive) googleDriveService!.update(newAppData: appRepo);
                  return googleDriveService!;
                },
              ),
              ChangeNotifierProxyProvider2<AppSettings, AppRepository, StravaService>(
                lazy: false,
                create: (context) => StravaService(appRepository),
                update: (context, settings, appRepo, stravaService) {
                  if (settings.enableStrava) stravaService!.update(newAppData: appRepo);
                  return stravaService!;
                },
              ),
            ],
            child: Builder(
              builder: (context) {
                // Initialize Services after Snapshots are done and context is available
                DeepLinkService().init();
                QuickActionsService().init();
                return const BikeSetupTrackerApp();
              },
            ),
          );
        } else {
          return MaterialApp(
            theme: materialAppTheme,

            themeMode: ThemeMode.system,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
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
      home: appSettings.showOnboarding
          ? const OnboardingPage()
          : const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
