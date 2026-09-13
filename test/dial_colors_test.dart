import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Value guard for the dial palette.
///
/// A dial color is persisted per adjustment and describes a physical part, so
/// it must not drift when the app's theme changes. Editing a value here is a
/// deliberate act: it repaints every dial already saved with that color.
void main() {
  group('DialColors values are pinned', () {
    test('light palette', () {
      expect(DialColors.light.blue, const Color(0xFF106681));
      expect(DialColors.light.red, const Color(0xFFC62828));
      expect(DialColors.light.green, const Color(0xFF2E7D32));
      expect(DialColors.light.brown, const Color(0xFF5D4037));
      expect(DialColors.light.orange, const Color(0xFFF5A800));
      expect(DialColors.light.purple, const Color(0xFF6A1B9A));
      expect(DialColors.light.grey, const Color(0xFF424242));
    });

    test('dark palette', () {
      expect(DialColors.dark.blue, const Color(0xFF8AD0EF));
      expect(DialColors.dark.red, const Color(0xFFE57373));
      expect(DialColors.dark.green, const Color(0xFF81C784));
      expect(DialColors.dark.brown, const Color(0xFFA1887F));
      expect(DialColors.dark.orange, const Color(0xFFF5A800));
      expect(DialColors.dark.purple, const Color(0xFFBA68C8));
      expect(DialColors.dark.grey, const Color(0xFF9E9E9E));
    });

    test('Öhlins gold is the same in both themes', () {
      expect(DialColors.dark.orange, DialColors.light.orange);
    });

    test('every color within a palette is distinct', () {
      for (final palette in [DialColors.light, DialColors.dark]) {
        final resolved = StepAdjustmentDialColor.values
            .map((c) => _resolve(palette, c))
            .toSet();
        expect(resolved, hasLength(StepAdjustmentDialColor.values.length));
      }
    });
  });

  group('Dial colors are independent of the color scheme', () {
    testWidgets('a differently seeded theme resolves the same dial colors', (WidgetTester tester) async {
      late Color fromAppTheme;
      late Color fromForeignTheme;

      Widget probe(ThemeData theme, ValueSetter<Color> onResolved) => MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                onResolved(resolveDialColor(context, StepAdjustmentDialColor.red));
                return const SizedBox.shrink();
              },
            ),
          );

      await tester.pumpWidget(probe(materialAppTheme, (c) => fromAppTheme = c));
      await tester.pumpWidget(probe(
        ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
          extensions: const [DialColors.light],
        ),
        (c) => fromForeignTheme = c,
      ));

      expect(fromForeignTheme, fromAppTheme);
      expect(fromAppTheme, DialColors.light.red);
    });

    testWidgets('a theme without the extension still resolves per brightness', (WidgetTester tester) async {
      late Color resolved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            resolved = resolveDialColor(context, StepAdjustmentDialColor.green);
            return const SizedBox.shrink();
          },
        ),
      ));

      expect(resolved, DialColors.dark.green);
    });
  });

  group('App themes', () {
    test('both register the dial palette', () {
      expect(materialAppTheme.extension<DialColors>(), DialColors.light);
      expect(materialAppDarkTheme.extension<DialColors>(), DialColors.dark);
    });

    test('dial blue was frozen from the primary color', () {
      // Not a constraint, a tripwire: if the seed color changes this fails, and
      // the fix is normally to leave DialColors alone — saved dials must keep
      // their color — and update this expectation to the frozen value.
      expect(
        DialColors.light.blue,
        materialAppTheme.colorScheme.primary,
        reason: 'The primary color changed. Keep DialColors.light.blue as it is '
            'so existing dials stay the color the rider picked, and adjust this '
            'expectation instead.',
      );
      expect(
        DialColors.dark.blue,
        materialAppDarkTheme.colorScheme.primary,
        reason: 'The dark primary color changed — see the light-theme note above.',
      );
    });
  });
}

Color _resolve(DialColors palette, StepAdjustmentDialColor color) => switch (color) {
      StepAdjustmentDialColor.blue => palette.blue,
      StepAdjustmentDialColor.red => palette.red,
      StepAdjustmentDialColor.green => palette.green,
      StepAdjustmentDialColor.brown => palette.brown,
      StepAdjustmentDialColor.orange => palette.orange,
      StepAdjustmentDialColor.purple => palette.purple,
      StepAdjustmentDialColor.grey => palette.grey,
    };
