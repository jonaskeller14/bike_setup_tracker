import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/delete_task_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppRepository extends Mock implements AppRepository {}

void main() {
  late _MockAppRepository repository;
  late List<TaskRule> rules;

  setUp(() {
    repository = _MockAppRepository();
    final bike = Bike(id: 'bike', name: 'A very long bike name that must not overflow', person: null);
    final component = Component(
      id: 'component',
      name: 'A very long component name that must not overflow',
      componentType: ComponentType.fork,
      installations: [Installation.sinceBeginning(parent: bike.id)],
    );
    rules = [
      TaskRule(name: 'Lower leg service', tags: const {}, componentId: component.id),
      TaskRule(name: 'Check headset', tags: const {}, bikeId: bike.id),
    ];
    when(() => repository.bikes).thenReturn({bike.id: bike});
    when(() => repository.components).thenReturn({component.id: component});
  });

  Widget harness(ValueChanged<List<TaskRule>?> onResult) {
    return ChangeNotifierProvider<AppRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onResult(await showDeleteTaskRulesSheet(context, taskRules: rules)),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains entry deletion and selects every task by default', (tester) async {
    await tester.pumpWidget(harness((_) {}));
    await open(tester);

    expect(find.text('Deleting a task also deletes its corresponding task entries.'), findsOneWidget);
    expect(find.text('Tasks (2 / 2)'), findsOneWidget);
    expect(find.text('Delete 2 tasks'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    expect(find.text('A very long bike name that must not overflow'), findsOneWidget);
  });

  testWidgets('allows selecting a subset and returns only the selected rules', (tester) async {
    List<TaskRule>? selected;
    await tester.pumpWidget(harness((result) => selected = result));
    await open(tester);

    await tester.tap(find.text('Lower leg service'));
    await tester.pump();
    expect(find.text('Tasks (1 / 2)'), findsOneWidget);
    expect(find.text('Delete 1 task'), findsOneWidget);

    await tester.tap(find.text('Delete 1 task'));
    await tester.pumpAndSettle();
    expect(selected, [rules.last]);
  });

  testWidgets('allows continuing without deleting any tasks', (tester) async {
    List<TaskRule>? selected;
    await tester.pumpWidget(harness((result) => selected = result));
    await open(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('Tasks (0 / 2)'), findsOneWidget);
    expect(find.text('Continue without deleting tasks'), findsOneWidget);

    await tester.tap(find.text('Continue without deleting tasks'));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });

  testWidgets('dismissal returns null', (tester) async {
    List<TaskRule>? result = rules;
    await tester.pumpWidget(harness((value) => result = value));
    await open(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
