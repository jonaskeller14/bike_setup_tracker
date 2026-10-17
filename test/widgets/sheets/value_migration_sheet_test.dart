import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:bike_setup_tracker/widgets/sheets/radio_option_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/value_migration_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
const _bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

int _counter = 0;

RecordedValue _record(
  AdjustmentValue value, {
  String? label,
  bool deleted = false,
  DateTime? day,
  RecordedValueSource source = RecordedValueSource.setup,
}) {
  final id = 'r${_counter++}';
  return RecordedValue(
    recordId: id,
    source: source,
    label: label ?? 'Record $id',
    dateTimeLocal: day ?? DateTime(2024, 3, 1),
    value: value,
    isDeleted: deleted,
  );
}

NumericalAdjustment _numerical({AdjustmentUnit? unit, double? max}) =>
    NumericalAdjustment(id: 'a', name: 'A', notes: null, unit: unit, max: max);

CategoricalAdjustment _categorical(Set<String> options) =>
    CategoricalAdjustment(id: 'a', name: 'A', notes: null, unit: null, options: options);

MigrationProposal _rangeProposal({List<RecordedValue>? recorded}) => MigrationProposal.build(
  before: _numerical(unit: _bar, max: 100),
  after: _numerical(unit: _bar, max: 50),
  recorded:
      recorded ??
      [
        _record(const NumericalValue(80), label: 'Alpine', day: DateTime(2024, 3, 2)),
        _record(const NumericalValue(90), label: 'Bike park', day: DateTime(2024, 3, 1)),
        _record(const NumericalValue(95), label: 'Old setup', deleted: true),
      ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ValueMigration? result;
  late bool resultReported;

  Future<void> openSheet(
    WidgetTester tester,
    MigrationProposal proposal, {
    ThemeData? theme,
    String adjustmentName = 'Pressure',
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    result = null;
    resultReported = false;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showValueMigrationSheet(
                      context,
                      adjustmentName: adjustmentName,
                      proposal: proposal,
                    );
                    resultReported = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('summarises the affected records, with deleted ones counted separately', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.text('Update recorded values'), findsOneWidget);
    expect(find.textContaining("Your change to 'Pressure' affects 2 setups (+1 deleted)."), findsOneWidget);
    expect(find.text('Values outside the new range'), findsOneWidget);
  });

  testWidgets('counts rating entries', (tester) async {
    final proposal = _rangeProposal(
      recorded: [_record(const NumericalValue(80), source: RecordedValueSource.ratingEntry)],
    );
    await openSheet(tester, proposal);

    expect(find.textContaining('affects 1 rating entry.'), findsOneWidget);
    expect(find.text('Show affected rating entries'), findsOneWidget);
  });

  testWidgets('the preview shows the newest affected record and its migrated value', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.textContaining('Recorded · Alpine'), findsOneWidget);
    expect(find.text('80 bar'), findsOneWidget);
    expect(find.text('50 bar'), findsOneWidget);
    expect(find.text('Clamped'), findsOneWidget);
  });

  testWidgets('picking Clear updates the preview and the returned migration', (tester) async {
    final proposal = _rangeProposal();
    await openSheet(tester, proposal);

    await tester.tap(find.text('Clear values'));
    await tester.pumpAndSettle();

    expect(find.text('No value'), findsOneWidget);
    expect(find.text('Cleared'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result, proposal.withChoice('range', MigrationChoice.clear).toMigration());
    expect(result!.apply(const NumericalValue(80)), isNull);
  });

  testWidgets('confirming with the defaults returns the default migration', (tester) async {
    final proposal = _rangeProposal();
    await openSheet(tester, proposal);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result, proposal.toMigration());
  });

  testWidgets('Cancel returns null', (tester) async {
    await openSheet(tester, _rangeProposal());

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resultReported, isTrue);
    expect(result, isNull);
  });

  testWidgets('a choice that creates a later issue shows it', (tester) async {
    final proposal = MigrationProposal.build(
      before: _numerical(unit: _psi),
      after: _numerical(unit: _bar, max: 2),
      recorded: [_record(const NumericalValue(10))],
    );
    await openSheet(tester, proposal);

    expect(find.text('Unit changed from psi to bar'), findsOneWidget);
    expect(find.text('Values outside the new range'), findsNothing);
    expect(find.text('0.68948 bar'), findsOneWidget);

    await tester.tap(find.text('Keep numbers'));
    await tester.pumpAndSettle();

    expect(find.text('Values outside the new range'), findsOneWidget);
  });

  testWidgets('an automatic issue shows no choices', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B'}),
      after: _categorical({'A2', 'B'}),
      optionOrigins: const {'A2': 'A', 'B': 'B'},
      recorded: [_record(CategoricalValue(const ['A']))],
    );
    await openSheet(tester, proposal);

    expect(find.text('Options renamed'), findsOneWidget);
    expect(find.text('Applied automatically'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.byType(RadioOptionCard), findsNothing);
  });

  testWidgets('a deleted option offers the remaining options', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B', 'C'}),
      after: _categorical({'A', 'B'}),
      optionOrigins: const {'A': 'A', 'B': 'B'},
      recorded: [_record(CategoricalValue(const ['C']))],
    );
    await openSheet(tester, proposal);

    expect(find.text("Option 'C' deleted"), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result!.apply(CategoricalValue(const ['C'])), CategoricalValue(const ['B']));
  });

  testWidgets('slide 2 lists the live records and the deleted count, and back returns to slide 1', (tester) async {
    await openSheet(tester, _rangeProposal());

    await tester.tap(find.text('Show affected setups'));
    await tester.pumpAndSettle();

    expect(find.text('Affected setups'), findsOneWidget);
    expect(find.text('Alpine'), findsOneWidget);
    expect(find.text('Bike park'), findsOneWidget);
    expect(find.text('+1 deleted setup'), findsOneWidget);
    expect(find.text('Update recorded values'), findsNothing);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Update recorded values'), findsOneWidget);
    expect(find.text('Affected setups'), findsNothing);
  });

  testWidgets('the system back from slide 2 returns to slide 1 and keeps the sheet open', (tester) async {
    await openSheet(tester, _rangeProposal());
    await tester.tap(find.text('Show affected setups'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Update recorded values'), findsOneWidget);
    expect(resultReported, isFalse);
  });

  testWidgets('long names render without overflow at 320 px', (tester) async {
    const longName = 'A very long adjustment name that keeps going and going well past the edge of the screen';
    final proposal = MigrationProposal.build(
      before: _categorical({'Option one', 'Option two', longName}),
      after: _categorical({'Option one', 'Option two'}),
      optionOrigins: const {'Option one': 'Option one', 'Option two': 'Option two'},
      recorded: [
        _record(CategoricalValue(const [longName]), label: longName),
        _record(CategoricalValue(const [longName]), label: longName, deleted: true),
      ],
    );
    await openSheet(tester, proposal, adjustmentName: longName, size: const Size(320, 640));

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Show affected setups'));
    await tester.tap(find.text('Show affected setups'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('renders in the $name theme', (tester) async {
      await openSheet(tester, _rangeProposal(), theme: theme);

      expect(tester.takeException(), isNull);
      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.text('Clear values'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
