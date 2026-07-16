import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_sag_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget build({
    required SagAdjustment adjustment,
    required double? initialValue,
    required String? value,
    required ValueChanged<String> onChanged,
    required Key formKey,
  }) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetSagAdjustmentWidget(
            key: const ValueKey('SAG'),
            adjustment: adjustment,
            initialValue: initialValue,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  SagAdjustment sag({double? travel = 160}) =>
      SagAdjustment(name: 'SAG', notes: null, referenceTravelMm: travel);

  group('SetSagAdjustmentWidget', () {
    testWidgets('toggles % → mm and reports the stored percentage', (tester) async {
      final formKey = GlobalKey<FormState>();
      String? reported;
      await tester.pumpWidget(build(
        adjustment: sag(),
        initialValue: null,
        value: '25',
        onChanged: (v) => reported = v,
        formKey: formKey,
      ));

      expect(find.text('%'), findsOneWidget);

      await tester.tap(find.text('%'));
      await tester.pumpAndSettle();

      // 25% of 160mm travel = 40mm.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(double.parse(field.controller!.text), closeTo(40, 1e-6));
      expect(find.text('mm'), findsOneWidget);
      expect(find.text('= 25 %'), findsOneWidget);

      // Entering a measured length reports the derived percentage.
      await tester.enterText(find.byType(TextField), '48');
      await tester.pump();
      expect(double.parse(reported!), closeTo(30, 1e-6));
    });

    testWidgets('validates against travel-converted bounds in mm', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(build(
        adjustment: sag(),
        initialValue: null,
        value: '25',
        onChanged: (_) {},
        formKey: formKey,
      ));

      await tester.tap(find.text('%'));
      await tester.pumpAndSettle();

      // The 100% bound is 160mm of travel.
      await tester.enterText(find.byType(TextField), '170');
      expect(formKey.currentState!.validate(), isFalse);

      await tester.enterText(find.byType(TextField), '40');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('offers no mm toggle when the travel is unknown', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(build(
        adjustment: sag(travel: null),
        initialValue: null,
        value: '25',
        onChanged: (_) {},
        formKey: formKey,
      ));

      expect(find.text('%'), findsOneWidget);
      await tester.tap(find.text('%'));
      await tester.pumpAndSettle();

      expect(find.text('mm'), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '25');
    });
  });
}
