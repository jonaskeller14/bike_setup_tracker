import 'package:bike_setup_tracker/screenshots/touch_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TouchIndicator', () {
    var taps = 0;

    Future<void> pumpIndicator(WidgetTester tester) async {
      taps = 0;
      await tester.pumpWidget(
        TouchIndicator(
          child: MaterialApp(
            home: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }

    final indicator = find.byType(TouchIndicator);
    PaintPattern paintsDotAt(Offset position) =>
        paints..circle(x: position.dx, y: position.dy, radius: TouchIndicator.radius);

    testWidgets('paints nothing until a touch', (tester) async {
      await pumpIndicator(tester);

      expect(indicator, isNot(paints..circle()));
    });

    testWidgets('follows a touch and lets it through to the app', (tester) async {
      await pumpIndicator(tester);

      final gesture = await tester.startGesture(const Offset(100, 200));
      await tester.pump();
      expect(indicator, paintsDotAt(const Offset(100, 200)));

      await gesture.moveTo(const Offset(100, 205));
      await tester.pump();
      expect(indicator, paintsDotAt(const Offset(100, 205)));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('fades the dot out after release', (tester) async {
      await pumpIndicator(tester);

      await tester.tapAt(const Offset(100, 200));
      await tester.pump();
      expect(indicator, paintsDotAt(const Offset(100, 200)));

      await tester.pumpAndSettle();
      expect(indicator, isNot(paints..circle()));
    });
  });
}
