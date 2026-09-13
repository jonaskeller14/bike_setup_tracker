import 'package:flutter/material.dart';
class ValueHighlightColors extends ThemeExtension<ValueHighlightColors> {
  final Color changed;
  final Color initial;

  const ValueHighlightColors({required this.changed, required this.initial});

  Color get changedFill => changed.withValues(alpha: 0.08);  // e.g. FormFields
  Color get initialFill => initial.withValues(alpha: 0.08);

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

class TaskStatusColors extends ThemeExtension<TaskStatusColors> {
  final Color overdue;
  final Color due;
  final Color upcoming;
  final Color completed;

  const TaskStatusColors({
    required this.overdue,
    required this.due,
    required this.upcoming,
    required this.completed,
  });

  static const light = TaskStatusColors(
    overdue: Color(0xFFC62828), // red 800
    due: Color(0xFFEF6C00), // orange 800 — matches ValueHighlightColors.changed
    upcoming: Color(0xFF1565C0), // blue 800
    completed: Color(0xFF2E7D32), // green 800 — matches ValueHighlightColors.initial
  );

  static const dark = TaskStatusColors(
    overdue: Color(0xFFE57373), // red 300
    due: Color(0xFFFFB74D), // orange 300 — matches ValueHighlightColors.changed
    upcoming: Color(0xFF64B5F6), // blue 300
    completed: Color(0xFF81C784), // green 300 — matches ValueHighlightColors.initial
  );

  @override
  TaskStatusColors copyWith({Color? overdue, Color? due, Color? upcoming, Color? completed}) {
    return TaskStatusColors(
      overdue: overdue ?? this.overdue,
      due: due ?? this.due,
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
    );
  }

  @override
  TaskStatusColors lerp(TaskStatusColors? other, double t) {
    if (other == null) return this;
    return TaskStatusColors(
      overdue: Color.lerp(overdue, other.overdue, t)!,
      due: Color.lerp(due, other.due, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
    );
  }
}

class SnackBarColors extends ThemeExtension<SnackBarColors> {
  final Color success;
  final Color onSuccess;

  const SnackBarColors({required this.success, required this.onSuccess});

  static const light = SnackBarColors(
    success: Color(0xFF2E7D32), // green 800
    onSuccess: Colors.white,
  );

  static const dark = SnackBarColors(
    success: Color(0xFF81C784), // green 300
    onSuccess: Colors.black,
  );

  @override
  SnackBarColors copyWith({Color? success, Color? onSuccess}) {
    return SnackBarColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  SnackBarColors lerp(SnackBarColors? other, double t) {
    if (other == null) return this;
    return SnackBarColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}

class DialColors extends ThemeExtension<DialColors> {
  final Color blue;
  final Color red;
  final Color green;
  final Color brown;
  final Color orange;
  final Color purple;
  final Color grey;

  const DialColors({
    required this.blue,
    required this.red,
    required this.green,
    required this.brown,
    required this.orange,
    required this.purple,
    required this.grey,
  });

  static const light = DialColors(
    blue: Color(0xFF106681), // matches the light primary at the time of writing
    red: Color(0xFFC62828), // red 800
    green: Color(0xFF2E7D32), // green 800
    brown: Color(0xFF5D4037), // brown 700
    orange: _ohlinsGold,
    purple: Color(0xFF6A1B9A), // purple 800
    grey: Color(0xFF424242), // grey 800 — for the near-black dials
  );

  static const dark = DialColors(
    blue: Color(0xFF8AD0EF), // matches the dark primary at the time of writing
    red: Color(0xFFE57373), // red 300
    green: Color(0xFF81C784), // green 300
    brown: Color(0xFFA1887F), // brown 300
    orange: _ohlinsGold,
    purple: Color(0xFFBA68C8), // purple 300
    grey: Color(0xFF9E9E9E), // grey 500 — a black dial still has to be visible
  );

  static const _ohlinsGold = Color(0xFFF5A800);

  @override
  DialColors copyWith({
    Color? blue,
    Color? red,
    Color? green,
    Color? brown,
    Color? orange,
    Color? purple,
    Color? grey,
  }) {
    return DialColors(
      blue: blue ?? this.blue,
      red: red ?? this.red,
      green: green ?? this.green,
      brown: brown ?? this.brown,
      orange: orange ?? this.orange,
      purple: purple ?? this.purple,
      grey: grey ?? this.grey,
    );
  }

  @override
  DialColors lerp(DialColors? other, double t) {
    if (other == null) return this;
    return DialColors(
      blue: Color.lerp(blue, other.blue, t)!,
      red: Color.lerp(red, other.red, t)!,
      green: Color.lerp(green, other.green, t)!,
      brown: Color.lerp(brown, other.brown, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      grey: Color.lerp(grey, other.grey, t)!,
    );
  }
}

final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueGrey.shade700,
  brightness: Brightness.light,
);

final materialAppTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _lightColorScheme,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: _lightColorScheme.surface,
    showDragHandle: true,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontWeight: FontWeight.bold),
  ),
  extensions: const [ValueHighlightColors.light, TaskStatusColors.light, SnackBarColors.light, DialColors.light],
);

final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blueGrey.shade700,
  brightness: Brightness.dark,
);

final materialAppDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _darkColorScheme,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: _darkColorScheme.surface,
    showDragHandle: true,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontWeight: FontWeight.bold),
  ),
  extensions: const [ValueHighlightColors.dark, TaskStatusColors.dark, SnackBarColors.dark, DialColors.dark],
);

List<Color> chartColors(Color primary, int count, {int hueStep = 137}) {
  final hsl = HSLColor.fromColor(primary);
  return List.generate(
    count,
    (i) => hsl.withHue((hsl.hue + i * hueStep) % 360).toColor(),
  );
}
