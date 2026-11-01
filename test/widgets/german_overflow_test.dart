import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/widgets/lists/garage_list.dart';
import 'package:bike_setup_tracker/widgets/lists/list_scroll_controller.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:bike_setup_tracker/widgets/lists/task_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../goldens/support/golden_test_harness.dart';

/// German strings are longer than English ones, so the lists that carry the
/// most chrome are laid out in `de` on a small phone, a normal phone and a
/// tablet, in light and dark, with the largest system text size.
void main() {
  const de = Locale('de');
  const sizes = {
    'small phone': Size(320, 640),
    'phone': Size(390, 844),
    'tablet': Size(1024, 768),
  };
  late GoldenTestHarness harness;

  setUp(() async {
    Intl.defaultLocale = 'de';
    harness = await GoldenTestHarness.create();
    await harness.repository.addTaskRules([
      TaskRule(
        name: 'Hinterbau-Kinematik und Lager auf Spiel prüfen',
        tags: const {},
        association: const BikeTaskAssociation(GoldenTestHarness.trailBikeId),
        interval: const DurationThreshold(Duration(days: 1)),
      ),
      TaskRule(
        name: 'Kette',
        tags: const {},
        association: const BikeTaskAssociation(GoldenTestHarness.trailBikeId),
        interval: const ActivityCountThreshold(1),
        delay: const ActivityCountThreshold(3),
      ),
      TaskRule(
        name: 'Bremsen entlüften',
        tags: const {},
        association: const BikeTaskAssociation(GoldenTestHarness.gravelBikeId),
        interval: const DistanceThreshold(2500000),
        repeat: false,
        priority: TaskPriority.critical,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await harness.dispose();
  });

  Future<void> pumpAndCheck(WidgetTester tester, Widget list, Size viewport, Brightness brightness) async {
    await tester.pumpWidget(
      harness.wrap(
        brightness: brightness,
        viewport: viewport,
        locale: de,
        textScaler: const TextScaler.linear(1.3),
        child: Scaffold(body: list),
      ),
    );
    await settleGolden(tester);
    expect(tester.takeException(), isNull);
  }

  for (final MapEntry(key: name, value: viewport) in sizes.entries) {
    for (final brightness in Brightness.values) {
      final label = '$name, ${brightness.name}';

      testWidgets('the garage fits in German on a $label', (tester) async {
        final controller = ListScrollController();
        addTearDown(controller.dispose);
        await pumpAndCheck(tester, GarageList(controller: controller), viewport, brightness);
      });

      testWidgets('the setup history fits in German on a $label', (tester) async {
        await pumpAndCheck(tester, const SetupList(), viewport, brightness);
      });

      testWidgets('the task list fits in German on a $label', (tester) async {
        await pumpAndCheck(tester, const TaskList(), viewport, brightness);
        expect(find.textContaining('Jeden Tag'), findsWidgets);
      });
    }
  }
}
