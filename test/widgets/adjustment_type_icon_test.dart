import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/adjustment_type_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3: sag's type icon is the numerical base plus a small travel badge, so
/// it reads as "a specialized numerical". See doc/20260715_sag_adjustment_type.md §6.4.
void main() {
  Widget host(Adjustment adjustment) => MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(body: AdjustmentTypeIcon(adjustment)),
      );

  testWidgets('a plain numerical renders a single base icon, no badge', (tester) async {
    await tester.pumpWidget(host(NumericalAdjustment(
      name: 'Pressure',
      notes: null,
      unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
    )));

    expect(find.byIcon(NumericalAdjustment.iconData), findsOneWidget);
    expect(find.byIcon(SagAdjustment.badgeIconData), findsNothing);
  });

  testWidgets('a sag renders the numerical base plus the travel badge', (tester) async {
    await tester.pumpWidget(host(SagAdjustment(name: 'SAG', notes: null, referenceTravelMm: 160)));

    // Base is the numerical icon (sag's flat fallback), badge is the travel mark.
    expect(find.byIcon(NumericalAdjustment.iconData), findsOneWidget);
    expect(find.byIcon(SagAdjustment.badgeIconData), findsOneWidget);
  });

  testWidgets('sag flat fallback getIconData stays the numerical icon', (tester) async {
    expect(SagAdjustment(name: 'SAG', notes: null).getIconData(), NumericalAdjustment.iconData);
  });
}
