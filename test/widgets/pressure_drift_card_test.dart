import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/services/pressure_drift_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/pressure_drift_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import '../support/german_l10n.dart';

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

    Future<void> pumpCard(WidgetTester tester, {PressureDriftGap? gap, bool loading = false}) {
      return tester.pumpWidget(
        ChangeNotifierProvider<AppSettings>.value(
          value: AppSettings(),
          child: localizedTestApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PressureDriftCard(check: PressureCheck(gap: gap), loading: loading),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('hides while there is neither a reading nor a reason', (tester) async {
      await pumpCard(tester);

      expect(find.text('PRESSURE CHECK'), findsNothing);
    });

    testWidgets('a gap shows collapsed and explains itself once expanded', (tester) async {
      await pumpCard(tester, gap: PressureDriftGap.noRecordedConditions);

      expect(find.text('PRESSURE CHECK'), findsOneWidget);
      expect(find.textContaining('saved without a temperature'), findsNothing);

      await tester.tap(find.text('PRESSURE CHECK'));
      await tester.pumpAndSettle();
      expect(find.textContaining('saved without a temperature'), findsOneWidget);

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
  });
}
