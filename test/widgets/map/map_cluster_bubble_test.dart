import 'dart:math' as math;

import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/map/map_cluster_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  const minSweep = math.pi / 9;
  double total(List<double> sweeps) => sweeps.fold(0, (sum, sweep) => sum + sweep);

  group('donutSweeps', () {
    test('gives a single kind the full turn', () {
      expect(donutSweeps([5]), [closeTo(2 * math.pi, 1e-9)]);
    });

    test('splits in proportion when every share is large enough', () {
      final sweeps = donutSweeps([1, 1, 2]);
      expect(sweeps[0], closeTo(math.pi / 2, 1e-9));
      expect(sweeps[1], closeTo(math.pi / 2, 1e-9));
      expect(sweeps[2], closeTo(math.pi, 1e-9));
    });

    test('lifts a tiny share to the minimum and keeps the full turn', () {
      final sweeps = donutSweeps([79, 1]);
      expect(sweeps[1], closeTo(minSweep, 1e-9));
      expect(total(sweeps), closeTo(2 * math.pi, 1e-9));
    });

    test('re-clamps a share the first clamp pushed under the minimum', () {
      // 23/400 of a turn is 20.7°, just above the minimum, until clamping
      // the single pin shrinks it to 19.6°.
      final sweeps = donutSweeps([376, 23, 1]);
      expect(sweeps[1], closeTo(minSweep, 1e-9));
      expect(sweeps[2], closeTo(minSweep, 1e-9));
      expect(total(sweeps), closeTo(2 * math.pi, 1e-9));
    });

    test('leaves zero counts without a segment', () {
      final sweeps = donutSweeps([3, 0]);
      expect(sweeps[1], 0);
      expect(total(sweeps), closeTo(2 * math.pi, 1e-9));
    });
  });

  group('MapClusterBubble', () {
    Widget bubble(Map<MapPinKind, int> counts, {ThemeData? theme}) => localizedTestApp(
      theme: theme ?? materialAppTheme,
      home: Center(
        child: SizedBox.square(dimension: 40, child: MapClusterBubble(counts: counts)),
      ),
    );

    testWidgets('shows the total and announces it', (tester) async {
      await tester.pumpWidget(bubble({MapPinKind.setup: 8, MapPinKind.activity: 3, MapPinKind.feedback: 1}));

      expect(find.text('12'), findsOneWidget);
      expect(find.bySemanticsLabel('Cluster of 12 pins'), findsOneWidget);
    });

    testWidgets('fits a four-digit count inside the ring', (tester) async {
      await tester.pumpWidget(bubble({MapPinKind.activity: 1234}, theme: materialAppDarkTheme));

      expect(find.text('1234'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
