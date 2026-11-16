import 'package:bike_setup_tracker/widgets/rolling_value_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String psi(double value) => '${value.round()} psi';

  Widget app(String text, double? value, {String Function(double)? format, bool disableAnimations = false}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: SizedBox(
              width: 120,
              child: RollingValueText(text, value: value, format: format),
            ),
          ),
        ),
      );

  /// Every single-character text shown while the count runs.
  Future<Set<String>> digitsDuringCount(WidgetTester tester) async {
    final seen = <String>{};
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        if (text.data?.length == 1) seen.add(text.data!);
      }
    }
    return seen;
  }

  group('RollingValueText', () {
    testWidgets('counts through every step, then rests as one text', (tester) async {
      await tester.pumpWidget(app('85 psi', 85, format: psi));
      expect(find.text('85 psi'), findsOneWidget);

      await tester.pumpWidget(app('90 psi', 90, format: psi));
      expect(await digitsDuringCount(tester), containsAll(['5', '6', '7', '8', '9', '0']));

      await tester.pumpAndSettle();
      expect(find.text('90 psi'), findsOneWidget);
    });

    testWidgets('splits a large change into a few even steps', (tester) async {
      await tester.pumpWidget(app('0 psi', 0, format: psi));
      await tester.pumpWidget(app('120 psi', 120, format: psi));
      // 0, 20, 40, 60, 80, 100, 120.
      final digits = await digitsDuringCount(tester);
      expect(digits, containsAll(['2', '4', '6', '8']));
      expect(digits, isNot(anyOf(contains('3'), contains('5'), contains('7'), contains('9'))));

      await tester.pumpAndSettle();
      expect(find.text('120 psi'), findsOneWidget);
    });

    testWidgets('counts down as well', (tester) async {
      await tester.pumpWidget(app('12 psi', 12, format: psi));
      await tester.pumpWidget(app('9 psi', 9, format: psi));
      expect(await digitsDuringCount(tester), containsAll(['2', '1', '0', '9']));

      await tester.pumpAndSettle();
      expect(find.text('9 psi'), findsOneWidget);
    });

    testWidgets('without a format, rolls only the characters that change', (tester) async {
      await tester.pumpWidget(app('84 psi', 84));
      await tester.pumpWidget(app('86 psi', 86));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('5'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('86 psi'), findsOneWidget);
    });

    testWidgets('rolls text without a value as a whole', (tester) async {
      await tester.pumpWidget(app('Open', null));
      await tester.pumpWidget(app('Firm', null));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Firm'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('switches at once while animations are disabled', (tester) async {
      await tester.pumpWidget(app('84 psi', 84, format: psi, disableAnimations: true));
      await tester.pumpWidget(app('86 psi', 86, format: psi, disableAnimations: true));
      await tester.pump();
      expect(find.text('86 psi'), findsOneWidget);
    });
  });
}
