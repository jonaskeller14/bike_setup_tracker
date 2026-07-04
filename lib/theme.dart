import 'package:flutter/material.dart';
class ValueHighlightColors extends ThemeExtension<ValueHighlightColors> {
  final Color changed;
  final Color initial;

  const ValueHighlightColors({required this.changed, required this.initial});

  static const light = ValueHighlightColors(
    changed: Color(0xFFEF6C00), // orange 800
    initial: Color(0xFF2E7D32), // green 800
  );

  static const dark = ValueHighlightColors(
    changed: Color(0xFFFFB74D), // orange 300
    initial: Color(0xFF81C784), // green 300
  );

  @override
  ValueHighlightColors copyWith({Color? changed, Color? initial}) {
    return ValueHighlightColors(
      changed: changed ?? this.changed,
      initial: initial ?? this.initial,
    );
  }

  @override
  ValueHighlightColors lerp(ValueHighlightColors? other, double t) {
    if (other == null) return this;
    return ValueHighlightColors(
      changed: Color.lerp(changed, other.changed, t)!,
      initial: Color.lerp(initial, other.initial, t)!,
    );
  }
}

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
  extensions: const [ValueHighlightColors.light],
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
  extensions: const [ValueHighlightColors.dark],
);

List<Color> chartColors(Color primary, int count, {int hueStep = 137}) {
  final hsl = HSLColor.fromColor(primary);
  return List.generate(
    count,
    (i) => hsl.withHue((hsl.hue + i * hueStep) % 360).toColor(),
  );
}
