import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/pressure_drift_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/pressure_drift_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import '../support/german_l10n.dart';

const _reference = PressureConditions(temperatureC: 20, altitudeM: 500);
const _current = PressureConditions(temperatureC: 5, altitudeM: 1800);

Setup _setup() => Setup(
  id: 'setup_1',
  datetime: DateTime.utc(2026, 10, 10, 9),
  datetimeLocal: DateTime(2026, 10, 10, 9),
  bike: 'bike_1',
  person: null,
  tags: const {},
  bikeAdjustmentValues: const {},
  personAdjustmentValues: const {},
);

KnownUnit get _psi => AdjustmentUnit.fromLegacy('psi') as KnownUnit;

/// 80 psi set earlier; [predicted] is what the pump would read now.
PressureDriftEntry _drift(String id, {double predicted = 77.2, double elapsedDays = 0}) => PressureDriftEntry(
  adjustmentId: id,
  adjustmentName: 'Air $id',
  componentName: 'Fork',
  unit: _psi,
  referenceSetup: _setup(),
  referenceValue: 80,
  referenceConditions: _reference,
  currentConditions: _current,
  predictedReading: predicted,
  elapsedDays: elapsedDays,
  leakShare: 0,
  temperatureShare: predicted - 80,
  altitudeShare: 0,
);

PressureReferenceGapEntry _gapEntry(String id) => PressureReferenceGapEntry(
  adjustmentId: id,
  adjustmentName: 'Air $id',
  componentName: 'Shock',
  unit: _psi,
  referenceSetup: _setup(),
  referenceValue: 180,
);

PressureCheck _checkOf(List<PressureCheckEntry> entries) =>
    PressureCheck(currentConditions: _current, entries: entries);

void main() {
  group('formatPressure', () {
    test('uses fewer decimals for larger values', () {
      expect(formatPressure(120.4, englishL10n), '120');
      expect(formatPressure(85.44, englishL10n), '85.4');
      expect(formatPressure(5.125, englishL10n), '5.13');
    });

    test('uses a decimal comma in German', () {
      expect(formatPressure(120.4, germanL10n), '120');
      expect(formatPressure(85.44, germanL10n), '85,4');
      expect(formatPressure(5.125, germanL10n), '5,13');
    });
  });

  group('signedPressure', () {
    test('spells out the sign', () {
      expect(signedPressure(0.5, englishL10n), '+0.50');
      expect(signedPressure(-0.5, englishL10n), '-0.50');
      expect(signedPressure(-0.5, germanL10n), '-0,50');
    });
  });

  group('signedPercent', () {
    test('drops the decimal from 10 % on', () {
      expect(signedPercent(0.055, englishL10n), '+5.5 %');
      expect(signedPercent(-0.12, englishL10n), '-12 %');
    });

    test('uses a decimal comma in German', () {
      expect(signedPercent(0.055, germanL10n), '+5,5 %');
    });
  });

  group('PressureDriftCard', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pumpCheck(WidgetTester tester, Widget Function(BuildContext) card) {
      return tester.pumpWidget(
        ChangeNotifierProvider<AppSettings>.value(
          value: AppSettings(),
          child: localizedTestApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: SingleChildScrollView(child: Builder(builder: card)),
            ),
          ),
        ),
      );
    }

    Future<void> pumpCard(WidgetTester tester, {PressureDriftGap? gap, bool loading = false}) => pumpCheck(
      tester,
      (_) => PressureDriftCard(
        check: PressureCheck(gap: gap),
        loading: loading,
      ),
    );

    testWidgets('hides while there is neither a reading nor a reason', (tester) async {
      await pumpCard(tester);

      expect(find.text('PRESSURE CHECK'), findsNothing);
    });

    testWidgets('a gap shows collapsed and explains itself once expanded', (tester) async {
      await pumpCard(tester, gap: PressureDriftGap.noRecordedPressure);

      expect(find.text('PRESSURE CHECK'), findsOneWidget);
      expect(find.textContaining('No pressure recorded'), findsNothing);

      await tester.tap(find.text('PRESSURE CHECK'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No pressure recorded'), findsOneWidget);

      await tester.tap(find.textContaining('Learn more'));
      await tester.pumpAndSettle();
      expect(find.text('Why the reading changes'), findsOneWidget);
    });

    testWidgets('shows a spinner while the conditions are being fetched', (tester) async {
      await pumpCard(tester, gap: PressureDriftGap.noCurrentConditions, loading: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('PRESSURE CHECK'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Getting the current temperature'), findsOneWidget);
    });

    group('set now', () {
      /// Mirrors the page: the card shows what the parent keeps.
      Future<List<(String, bool)>> pumpMarkable(
        WidgetTester tester,
        List<PressureCheckEntry> entries, {
        Set<String> marked = const {},
        Set<String>? available,
      }) async {
        final calls = <(String, bool)>[];
        var setNowIds = {...marked};
        await pumpCheck(
          tester,
          (_) => StatefulBuilder(
            builder: (context, setState) => PressureDriftCard(
              check: _checkOf(entries),
              setNowIds: setNowIds,
              setNowAvailableIds: available ?? {for (final e in entries) e.adjustmentId},
              onSetNowChanged: (id, setNow) {
                calls.add((id, setNow));
                setState(() => setNowIds = setNow ? {...setNowIds, id} : ({...setNowIds}..remove(id)));
              },
            ),
          ),
        );
        return calls;
      }

      testWidgets('tapping the toggle reports the id', (tester) async {
        final calls = await pumpMarkable(tester, [_drift('a')]);

        await tester.tap(find.text('Set now'));
        await tester.pump();

        expect(calls, [('a', true)]);
      });

      testWidgets('marking shows a snackbar whose undo unmarks again', (tester) async {
        final calls = await pumpMarkable(tester, [_drift('a')]);

        await tester.tap(find.text('Set now'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Fork · Air a marked as set now'), findsOneWidget);

        await tester.tap(find.text('UNDO'));
        await tester.pump();

        expect(calls, [('a', true), ('a', false)]);
        expect(find.byType(PressureDriftIcon), findsOneWidget);
      });

      testWidgets('unmarking shows no snackbar', (tester) async {
        await pumpMarkable(tester, [_drift('a')], marked: {'a'});
        await tester.tap(find.text('PRESSURE CHECK'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Set now'));
        await tester.pump();

        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('a marked row shows Set now and no arrow or drift', (tester) async {
        await pumpMarkable(tester, [_drift('a'), _drift('b')], marked: {'a'});

        expect(find.text('Set now'), findsNWidgets(2));
        expect(find.byType(PressureDriftIcon), findsOneWidget);
        expect(find.text('-3.5 %'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('tapping a marked row unmarks it', (tester) async {
        final calls = await pumpMarkable(tester, [_drift('a')], marked: {'a'});
        await tester.tap(find.text('PRESSURE CHECK'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Set now'));
        await tester.pump();

        expect(calls, [('a', false)]);
        expect(find.byType(PressureDriftIcon), findsOneWidget);
      });

      testWidgets('marking every drifted row says no pump and keeps the card open', (tester) async {
        await pumpMarkable(tester, [_drift('a')]);
        expect(find.text('Worth getting the pump out'), findsOneWidget);

        await tester.tap(find.text('Set now'));
        await tester.pumpAndSettle();

        expect(find.text('No need to get the pump out'), findsOneWidget);
        expect(find.byType(PressureDriftIcon), findsNothing);
        expect(find.text('Set now'), findsOneWidget);
      });

      testWidgets('a row within the threshold can be marked too', (tester) async {
        final calls = await pumpMarkable(tester, [_drift('a', predicted: 79.9)]);

        await tester.tap(find.text('PRESSURE CHECK'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Set now'));
        await tester.pump();

        expect(calls, [('a', true)]);
      });

      testWidgets('shows no toggle without a callback', (tester) async {
        await pumpCheck(
          tester,
          (_) => PressureDriftCard(check: _checkOf([_drift('a')]), setNowAvailableIds: const {'a'}),
        );

        expect(find.text('Set now'), findsNothing);
      });

      testWidgets('shows no toggle for a row that is not available', (tester) async {
        await pumpMarkable(tester, [_drift('a'), _drift('b')], available: {'b'});

        expect(find.text('Set now'), findsOneWidget);
      });

      testWidgets('lists a reference without conditions and lets it be marked', (tester) async {
        final calls = await pumpMarkable(tester, [_gapEntry('a')]);
        await tester.tap(find.text('PRESSURE CHECK'));
        await tester.pumpAndSettle();

        expect(find.textContaining('No conditions recorded on'), findsOneWidget);
        expect(find.text('180 psi'), findsOneWidget);
        expect(find.byType(PressureDriftIcon), findsNothing);
        expect(find.textContaining('nothing to compare'), findsOneWidget);

        await tester.tap(find.text('Set now'));
        await tester.pump();

        expect(calls, [('a', true)]);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(
          find.descendant(of: find.byType(PressureDriftCard), matching: find.byIcon(Icons.check_circle_outline)),
          findsOneWidget,
        );
      });

      testWidgets('shows how long ago an old reference was set', (tester) async {
        await pumpMarkable(tester, [_drift('a', elapsedDays: 12.4)]);

        expect(find.textContaining('12 days ago'), findsOneWidget);
      });

      testWidgets('shows no age for a reference from today', (tester) async {
        await pumpMarkable(tester, [_drift('a', elapsedDays: 0.6)]);

        expect(find.textContaining('ago'), findsNothing);
      });
    });
  });
}
