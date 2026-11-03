import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/widgets/lists/garage_list.dart';
import 'package:bike_setup_tracker/widgets/lists/list_scroll_controller.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:bike_setup_tracker/widgets/lists/task_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/golden_test_harness.dart';

/// French, Italian, Spanish and Portuguese run 20-30 % longer than English, so
/// the lists that carry the most chrome are laid out in each of them on a small
/// phone, a normal phone and a tablet, in light and dark, with the largest
/// system text size.
void main() {
  const languages = {
    'fr': 'Vérifier le jeu de la cinématique de suspension et des roulements',
    'it': 'Controlla il gioco della cinematica delle sospensioni e dei cuscinetti',
    'es': 'Revisar la holgura de la cinemática de la suspensión y de los rodamientos',
    'pt': 'Verificar a folga da cinemática da suspensão e dos rolamentos',
  };
  const sizes = {
    'small phone': Size(320, 640),
    'phone': Size(390, 844),
    'tablet': Size(1024, 768),
  };
  late GoldenTestHarness harness;

  setUp(() async {
    harness = await GoldenTestHarness.create();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> addTasks(String longName) => harness.repository.addTaskRules([
    TaskRule(
      name: longName,
      tags: const {},
      association: const BikeTaskAssociation(GoldenTestHarness.trailBikeId),
      interval: const DurationThreshold(Duration(days: 1)),
    ),
    TaskRule(
      name: 'Chain',
      tags: const {},
      association: const BikeTaskAssociation(GoldenTestHarness.trailBikeId),
      interval: const ActivityCountThreshold(1),
      delay: const ActivityCountThreshold(3),
    ),
    TaskRule(
      name: 'Brakes',
      tags: const {},
      association: const BikeTaskAssociation(GoldenTestHarness.gravelBikeId),
      interval: const DistanceThreshold(2500000),
      repeat: false,
      priority: TaskPriority.critical,
    ),
  ]);

  Future<void> pumpAndCheck(
    WidgetTester tester,
    Locale locale,
    Widget list,
    Size viewport,
    Brightness brightness,
  ) async {
    await tester.pumpWidget(
      harness.wrap(
        brightness: brightness,
        viewport: viewport,
        locale: locale,
        textScaler: const TextScaler.linear(1.3),
        child: Scaffold(body: list),
      ),
    );
    await settleGolden(tester);
    expect(tester.takeException(), isNull);
  }

  for (final MapEntry(key: code, value: longName) in languages.entries) {
    final locale = Locale(code);
    for (final MapEntry(key: name, value: viewport) in sizes.entries) {
      for (final brightness in Brightness.values) {
        final label = '$code, $name, ${brightness.name}';

        testWidgets('the garage fits in $label', (tester) async {
          final controller = ListScrollController();
          addTearDown(controller.dispose);
          await pumpAndCheck(tester, locale, GarageList(controller: controller), viewport, brightness);
        });

        testWidgets('the setup history fits in $label', (tester) async {
          await pumpAndCheck(tester, locale, const SetupList(), viewport, brightness);
        });

        testWidgets('the task list fits in $label', (tester) async {
          await addTasks(longName);
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
          await pumpAndCheck(tester, locale, const TaskList(), viewport, brightness);
        });
      }
    }
  }
}
