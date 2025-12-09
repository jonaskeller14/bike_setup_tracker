import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'pages/home_page.dart';

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
  runApp(LoadingGate(appSettings: AppSettings()));
}

class LoadingGate extends StatelessWidget {
  final AppSettings appSettings;

  const LoadingGate({super.key, required this.appSettings});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: appSettings.loadAppSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ChangeNotifierProvider.value(
            value: appSettings,
            child: const MyApp(),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return MaterialApp(
      title: 'Bike Setup Tracker',
      theme: materialAppTheme,
      darkTheme: materialAppDarkTheme,
      themeMode: appSettings.themeMode,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
