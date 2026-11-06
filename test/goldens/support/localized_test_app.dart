import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// A [MaterialApp] with the app's localization delegates, in English unless
/// a test asks for another [locale].
MaterialApp localizedTestApp({
  Key? key,
  GlobalKey<NavigatorState>? navigatorKey,
  Widget? home,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
  RouteFactory? onGenerateRoute,
  List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
  TransitionBuilder? builder,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode? themeMode,
  Locale locale = const Locale('en'),
  bool debugShowCheckedModeBanner = true,
}) {
  return MaterialApp(
    key: key,
    navigatorKey: navigatorKey,
    home: home,
    routes: routes,
    onGenerateRoute: onGenerateRoute,
    navigatorObservers: navigatorObservers,
    builder: builder,
    theme: theme,
    darkTheme: darkTheme,
    themeMode: themeMode,
    locale: locale,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
  );
}
