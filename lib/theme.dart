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
  extensions: const [ValueHighlightColors.light, TaskStatusColors.light, SnackBarColors.light],
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
  extensions: const [ValueHighlightColors.dark, TaskStatusColors.dark, SnackBarColors.dark],
);

List<Color> chartColors(Color primary, int count, {int hueStep = 137}) {
  final hsl = HSLColor.fromColor(primary);
  return List.generate(
    count,
    (i) => hsl.withHue((hsl.hue + i * hueStep) % 360).toColor(),
  );
}
