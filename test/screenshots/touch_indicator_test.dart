import 'package:bike_setup_tracker/screenshots/touch_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TouchIndicator', () {
    var taps = 0;

    Future<void> pumpIndicator(WidgetTester tester, {double jitter = 0}) async {
      taps = 0;
      await tester.pumpWidget(
        TouchIndicator(
          jitter: jitter,
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

    /// Centres of the filled dots (the ring and the rim are strokes).
    List<Offset> dotCentres(WidgetTester tester) {
      final centres = <Offset>[];
      expect(
        indicator,
        paints..everything((method, arguments) {
          if (method == #drawCircle && (arguments[2] as Paint).style == PaintingStyle.fill) {
            centres.add(arguments[0] as Offset);
          }
          return true;
        }),
      );
      return centres;
    }

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

    testWidgets('keeps a quick tap visible for minVisible, then fades it out', (tester) async {
      await pumpIndicator(tester);

      await tester.tapAt(const Offset(100, 200));
      await tester.pump(TouchIndicator.minVisible - const Duration(milliseconds: 50));
      expect(indicator, paintsDotAt(const Offset(100, 200)));

      await tester.pumpAndSettle();
      expect(indicator, isNot(paints..circle()));
    });

    testWidgets('expands a ring from the dot', (tester) async {
      await pumpIndicator(tester);

      await tester.startGesture(const Offset(100, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        indicator,
        paints..something((method, arguments) {
          if (method != #drawCircle) return false;
          final radius = arguments[1] as double;
          return radius > TouchIndicator.radius && radius < TouchIndicator.ringMaxRadius;
        }),
      );
    });

    testWidgets('offsets the dot by at most jitter and keeps the offset while dragging', (tester) async {
      await pumpIndicator(tester, jitter: TouchIndicator.defaultJitter);

      final gesture = await tester.startGesture(const Offset(100, 200));
      await tester.pump();
      final start = dotCentres(tester).single;
      final offset = start - const Offset(100, 200);
      expect(offset.dx.abs(), lessThanOrEqualTo(TouchIndicator.defaultJitter));
      expect(offset.dy.abs(), lessThanOrEqualTo(TouchIndicator.defaultJitter));

      await gesture.moveTo(const Offset(100, 205));
      await tester.pump();
      expect(dotCentres(tester).single, const Offset(100, 205) + offset);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
