import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/pages/adjustment/categorical_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../value_migration_test_utils.dart';
import 'preset_key_test_utils.dart';

void main() {
  testWidgets('CategoricalAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = CategoricalAdjustment(
      id: 'test-id',
      name: 'Test Categorical',
      notes: 'Some notes',
      unit: AdjustmentUnit.fromLegacy('some unit'),
      options: const {'Option 1', 'Option 2'},
    );

    CategoricalAdjustment? result;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>(
        create: (_) => AppSettings(),
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoricalAdjustmentPage.edit(adjustment: initial),
                  ),
                );
                result = edited?.value as CategoricalAdjustment?;
              },
              child: const Text('Open Page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, equals(initial));
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required AppSettings appSettings,
    required CategoricalAdjustment? adjustment,
    required ValueSetter<CategoricalAdjustment?> onResult,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: appSettings,
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<CategoricalAdjustment>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => adjustment == null
                        ? CategoricalAdjustmentPage.add()
                        : CategoricalAdjustmentPage.edit(adjustment: adjustment),
                  ),
                );
                onResult(result);
              },
              child: const Text('Open Page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();
  }

  testWidgets('Count Occurrences checkbox renders when enableCountedSelect is true and saving sets counted:true', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.enableCountedSelect = true;
    CategoricalAdjustment? result;

    await pumpPage(
      tester,
      appSettings: appSettings,
      adjustment: null,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Show Additional Fields'));
    await tester.pumpAndSettle();

    expect(find.text('Count Occurrences'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Adjustment Name'), 'Counted Adjustment');
    await tester.enterText(find.widgetWithText(TextFormField, 'Option 1'), 'Bar');

    await tester.tap(find.text('Count Occurrences'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.counted, isTrue);
  });

  testWidgets('Count Occurrences checkbox absent when flag is false and adjustment is not counted', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.enableCountedSelect = false;

    await pumpPage(
      tester,
      appSettings: appSettings,
      adjustment: null,
      onResult: (_) {},
    );

    expect(find.text('Count Occurrences'), findsNothing);
  });

  testWidgets('Count Occurrences checkbox shown for an existing counted adjustment even when flag is false', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.enableCountedSelect = false;
    final initial = CategoricalAdjustment(
      id: 'test-id',
      name: 'Counted Adjustment',
      notes: null,
      unit: null,
      options: const {'Bar', 'Gel'},
      multiSelect: true,
      counted: true,
    );

    await pumpPage(
      tester,
      appSettings: appSettings,
      adjustment: initial,
      onResult: (_) {},
    );

    expect(find.text('Count Occurrences'), findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Count Occurrences'));
    expect(checkbox.value, isTrue);
  });

  final preset = CategoricalAdjustment(name: 'Preset', notes: null, unit: null, options: const {'A', 'B'}, presetKey: testPresetKey);
  presetKeyTests(
    template: () => CategoricalAdjustmentPage.template(adjustment: preset),
    edit: () => CategoricalAdjustmentPage.edit(adjustment: preset),
    add: () => CategoricalAdjustmentPage.add(),
    fillAdd: (tester) => tester.enterText(find.widgetWithText(TextFormField, 'Option 1'), 'A'),
  );

  group('recorded values on edit', () {
    const sheetTitle = 'Update recorded values';

    CategoricalAdjustment damping(Set<String> options, {bool multiSelect = false, bool counted = false}) =>
        CategoricalAdjustment(
          id: 'damping',
          name: 'Damping',
          notes: null,
          unit: null,
          options: options,
          multiSelect: multiSelect,
          counted: counted,
        );

    RecordedValue selection(List<String> options) => recordedValue(CategoricalValue(options));

    Future<void> setOption(WidgetTester tester, int row, String text) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Option $row'), text);
      await tester.pumpAndSettle();
    }

    Future<void> removeOption(WidgetTester tester, int row) async {
      await tester.tap(find.byTooltip('Remove option').at(row - 1));
      await tester.pumpAndSettle();
    }

    Future<void> confirmSheet(WidgetTester tester) async {
      expect(find.text(sheetTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('value-migration-confirm')));
      await tester.pumpAndSettle();
    }

    CategoricalAdjustmentPage editPage(CategoricalAdjustment adjustment) =>
        CategoricalAdjustmentPage.edit(adjustment: adjustment, migrationContext: ValueMigrationContext(adjustment));

    AdjustmentEditResult<Adjustment> edited(Object? result) => result! as AdjustmentEditResult<Adjustment>;

    testWidgets('a rename with values maps them to the new name without a choice', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'})),
        repository: repositoryWithRecorded([selection(['Soft'])]),
        interact: () => setOption(tester, 1, 'Plush'),
        afterSave: () async {
          expect(find.text('Renamed options'), findsOneWidget);
          expect(find.byType(DropdownButtonFormField<MigrationChoice>), findsNothing);
          await confirmSheet(tester);
        },
      );

      final migrations = edited(result).migrations;
      expect(migrations, hasLength(1));
      expect(migrations.single.apply(CategoricalValue(const ['Soft'])), CategoricalValue(const ['Plush']));
    });

    testWidgets('a rename without values shows no sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'})),
        repository: repositoryWithRecorded(),
        interact: () => setOption(tester, 1, 'Plush'),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
      expect((edited(result).value as CategoricalAdjustment).options, {'Plush', 'Firm'});
    });

    testWidgets('swapping two option names swaps the values', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'})),
        repository: repositoryWithRecorded([selection(['Soft'])]),
        interact: () async {
          await setOption(tester, 1, 'Firm');
          await setOption(tester, 2, 'Soft');
        },
        afterSave: () => confirmSheet(tester),
      );

      final migration = edited(result).migrations.single;
      expect(migration.apply(CategoricalValue(const ['Soft'])), CategoricalValue(const ['Firm']));
      expect(migration.apply(CategoricalValue(const ['Firm'])), CategoricalValue(const ['Soft']));
    });

    testWidgets('a deleted option is mapped to another option by default', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Mid', 'Firm'})),
        repository: repositoryWithRecorded([selection(['Mid'])]),
        interact: () => removeOption(tester, 2),
        afterSave: () async {
          expect(find.byType(DropdownButtonFormField<MigrationChoice>), findsOneWidget);
          await confirmSheet(tester);
        },
      );

      expect(edited(result).migrations.single.apply(CategoricalValue(const ['Mid'])), CategoricalValue(const ['Soft']));
    });

    testWidgets('a deleted option can be cleared', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Mid', 'Firm'})),
        repository: repositoryWithRecorded([selection(['Mid'])]),
        interact: () => removeOption(tester, 2),
        afterSave: () async {
          await tester.tap(find.byType(DropdownButtonFormField<MigrationChoice>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('No value').last);
          await tester.pumpAndSettle();
          await confirmSheet(tester);
        },
      );

      expect(edited(result).migrations.single.apply(CategoricalValue(const ['Mid'])), isNull);
    });

    testWidgets('turning counted off removes repeated options', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Gel', 'Bar'}, multiSelect: true, counted: true)),
        repository: repositoryWithRecorded([selection(['Gel', 'Gel', 'Bar'])]),
        interact: () async {
          await tester.tap(find.text('Count Occurrences'));
          await tester.pumpAndSettle();
        },
        afterSave: () async {
          expect(find.text('Each option can be picked only once now'), findsOneWidget);
          await confirmSheet(tester);
        },
      );

      expect(
        edited(result).migrations.single.apply(CategoricalValue(const ['Gel', 'Gel', 'Bar'])),
        CategoricalValue(const ['Gel', 'Bar']),
      );
    });

    testWidgets('turning multi-select off maps each combination to one option', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'}, multiSelect: true)),
        repository: repositoryWithRecorded([selection(['Soft', 'Firm'])]),
        interact: () async {
          await tester.tap(find.text('Multi Select'));
          await tester.pumpAndSettle();
        },
        afterSave: () async {
          expect(find.byType(DropdownButtonFormField<MigrationChoice>), findsOneWidget);
          await confirmSheet(tester);
        },
      );

      expect(
        edited(result).migrations.single.apply(CategoricalValue(const ['Soft', 'Firm'])),
        CategoricalValue(const ['Soft']),
      );
    });

    testWidgets('a row removed and re-added with the same text keeps its values', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'})),
        repository: repositoryWithRecorded([selection(['Soft'])]),
        interact: () async {
          await removeOption(tester, 1);
          await tester.tap(find.text('Add'));
          await tester.pumpAndSettle();
          await setOption(tester, 2, 'Soft');
        },
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
    });

    testWidgets('deleting an option and renaming another to its text shows the merge', (tester) async {
      final result = await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'})),
        repository: repositoryWithRecorded([selection(['Soft']), selection(['Firm'])]),
        interact: () async {
          await removeOption(tester, 1);
          await setOption(tester, 1, 'Soft');
        },
        afterSave: () async {
          expect(find.text("'Soft' was deleted"), findsWidgets);
          expect(find.text("1 setup keeps 'Soft', now the option renamed from 'Firm'."), findsOneWidget);
          await confirmSheet(tester);
        },
      );

      final migration = edited(result).migrations.single;
      expect(migration.apply(CategoricalValue(const ['Soft'])), CategoricalValue(const ['Soft']));
      expect(migration.apply(CategoricalValue(const ['Firm'])), CategoricalValue(const ['Soft']));
    });

    group('a re-edit', () {
      testWidgets('shows a renamed option deleted later by its newer name', (tester) async {
        final saved = damping({'Soft', 'Firm'});
        final renamed = damping({'Plush', 'Firm'});
        final earlier = MigrationProposal.build(
          before: saved,
          after: renamed,
          optionOrigins: const {'Plush': 'Soft', 'Firm': 'Firm'},
          recorded: [selection(['Soft'])],
        );
        final result = await pushAndSave(
          tester,
          CategoricalAdjustmentPage.edit(
            adjustment: renamed,
            migrationContext: ValueMigrationContext(saved, pending: earlier),
          ),
          repository: repositoryWithRecorded([selection(['Soft'])]),
          interact: () => removeOption(tester, 1),
          afterSave: () async {
            expect(find.text("'Plush' was deleted"), findsWidgets);
            expect(find.textContaining('This replaces the change you confirmed earlier.'), findsOneWidget);
            await confirmSheet(tester);
          },
        );

        expect(edited(result).migrations.single.apply(CategoricalValue(const ['Soft'])), CategoricalValue(const ['Firm']));
      });

      testWidgets('that turns multi-select on again stages nothing', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = AppSettings()..enableMultiSelect = true;
        addTearDown(settings.dispose);
        final saved = damping({'Soft', 'Firm'}, multiSelect: true);
        final single = damping({'Soft', 'Firm'});
        final recorded = [selection(['Soft', 'Firm'])];
        final earlier = MigrationProposal.build(before: saved, after: single, recorded: recorded);
        final result = await pushAndSave(
          tester,
          CategoricalAdjustmentPage.edit(
            adjustment: single,
            migrationContext: ValueMigrationContext(saved, pending: earlier),
          ),
          repository: repositoryWithRecorded(recorded),
          settings: settings,
          interact: () async {
            await tester.tap(find.text('Multi Select'));
            await tester.pumpAndSettle();
          },
        );

        expect(find.text(sheetTitle), findsNothing);
        expect(edited(result).pending, isNull);
      });
    });

    testWidgets('a rename does not look values up when only the name changes', (tester) async {
      final repository = repositoryWithRecorded();
      await pushAndSave(
        tester,
        editPage(damping({'Soft', 'Firm'})),
        repository: repository,
        interact: () => enterName(tester, 'Renamed'),
      );

      verifyNever(() => repository.recordedValues(any()));
    });
  });
}
