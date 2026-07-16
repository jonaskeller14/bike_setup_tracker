import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/sag_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2: existing users upgrade a plain "SAG" percentage numerical to the
/// SagAdjustment subtype (and back), keeping the same adjustment id so setup
/// values, history and charts stay attached. See doc/20260715_sag_adjustment_type.md §7.
void main() {
  const bannerLabel = 'Convert to SAG adjustment';

  NumericalAdjustment percentSag({String name = 'SAG'}) => NumericalAdjustment(
        id: 'adj-1',
        name: name,
        notes: 'measured static',
        unit: const CustomUnit('%'),
        min: 0,
        max: 100,
      );

  Future<Object?> openNumerical(
    WidgetTester tester,
    NumericalAdjustment adjustment, {
    bool enableSagConversion = true,
  }) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(
                    adjustment: adjustment,
                    enableSagConversion: enableSagConversion,
                  ),
                ),
              );
            },
            child: const Text('Open Page'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();
    return result;
  }

  group('Convert-to-SAG offer visibility', () {
    testWidgets('shown for a % adjustment named "sag"', (tester) async {
      await openNumerical(tester, percentSag());
      expect(find.text(bannerLabel), findsOneWidget);
    });

    testWidgets('hidden when the name has nothing to do with sag', (tester) async {
      await openNumerical(tester, percentSag(name: 'Pressure'));
      expect(find.text(bannerLabel), findsNothing);
    });

    testWidgets('hidden when the unit is not %', (tester) async {
      await openNumerical(
        tester,
        NumericalAdjustment(
          id: 'adj-1',
          name: 'SAG',
          notes: null,
          unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
          min: 0,
          max: 100,
        ),
      );
      expect(find.text(bannerLabel), findsNothing);
    });

    testWidgets('hidden when conversion is disabled (e.g. person adjustment)', (tester) async {
      await openNumerical(tester, percentSag(), enableSagConversion: false);
      expect(find.text(bannerLabel), findsNothing);
    });
  });

  testWidgets('upgrading returns a SagAdjustment with the same id and captured travel',
      (tester) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(
                    adjustment: percentSag(),
                    enableSagConversion: true,
                    componentType: ComponentType.fork,
                  ),
                ),
              );
            },
            child: const Text('Open Page'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(bannerLabel));
    await tester.pumpAndSettle();

    // We're now on the SAG page (via pushReplacement). Enter travel and save.
    expect(find.text('Edit SAG Adjustment'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. 160'), '160');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isA<SagAdjustment>());
    final sag = result! as SagAdjustment;
    expect(sag.id, 'adj-1'); // same row → values/history stay attached
    expect(sag.name, 'SAG');
    expect(sag.notes, 'measured static');
    expect(sag.referenceTravelMm, 160);
  });

  testWidgets('downgrading returns a plain numerical (% / 0..100, no travel, same id)',
      (tester) async {
    Object? result;
    final sag = SagAdjustment(
      id: 'adj-1',
      name: 'SAG',
      notes: 'measured static',
      referenceTravelMm: 160,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(
                  builder: (context) => SagAdjustmentPage.edit(adjustment: sag),
                ),
              );
            },
            child: const Text('Open Page'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Convert to plain numerical'));
    await tester.pumpAndSettle();

    // Now on the numerical page (via pushReplacement). Save unchanged.
    expect(find.text('Edit Numerical Adjustment'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final EditResult<Adjustment> edit = result! as EditResult<Adjustment>;
    final numerical = edit.value;
    expect(numerical, isNot(isA<SagAdjustment>()));
    expect(numerical, isA<NumericalAdjustment>());
    expect(numerical.id, 'adj-1');
    expect(numerical.name, 'SAG');
    expect(numerical.unit, const CustomUnit('%'));
    expect((numerical as NumericalAdjustment).min, 0);
    expect(numerical.max, 100);
  });
}
