import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'models/app_settings.dart';
import 'models/app_data.dart';
import 'models/filtered_data.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'services/storage_service.dart';

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  ));

  runApp(LoadingGate(
    appSettings: AppSettings(), 
    appData: AppData(),
  ));
}

class LoadingGate extends StatelessWidget {
  final AppSettings appSettings;
  final AppData appData;

  const LoadingGate({super.key, required this.appSettings, required this.appData});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        appSettings.loadAppSettings(),
        appData.load(context),
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
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
              ChangeNotifierProvider.value(value: appSettings),
              ChangeNotifierProvider.value(value: appData),
              ChangeNotifierProxyProvider<AppData, FilteredData>(
                create: (context) => FilteredData(appData),
                update: (context, newAppData, filteredData) => filteredData!..update(newAppData),
              ),
              ProxyProvider<AppData, StorageService>(
                create: (context) => StorageService(),
                update: (context, newAppData, storageService) => storageService!..update(newAppData),
              ),
            ],
            child: const BikeSetupTrackerApp(),
          );
        } else {
          return MaterialApp(
            theme: materialAppTheme,
            
            themeMode: ThemeMode.system,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
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
      home: appSettings.showOnboarding ? const OnboardingPage() : const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
