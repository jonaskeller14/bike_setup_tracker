import 'package:flutter/material.dart';

final materialAppTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueGrey.shade700,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontWeight: FontWeight.bold),
  ),
);

final materialAppDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueGrey.shade700,
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontWeight: FontWeight.bold),
  ),
);

List<Color> chartColors(Color primary, int count, {int hueStep = 137}) {
  final hsl = HSLColor.fromColor(primary);
  return List.generate(
    count,
    (i) => hsl.withHue((hsl.hue + i * hueStep) % 360).toColor(),
  );
}
