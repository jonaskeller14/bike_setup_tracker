import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/settings/features_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettings();
  });

  tearDown(() => settings.dispose());

  testWidgets('shows and changes the debug Setup Comparison feature', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(home: FeaturesPage()),
      ),
    );

    expect(find.text('Setup Comparison'), findsOneWidget);
    expect(find.text('Off'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Setup Comparison'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Setup Comparison'));
    await tester.pumpAndSettle();
    expect(find.textContaining('experimental comparison'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('On'),
      ),
    );
    await tester.pumpAndSettle();

    expect(settings.enableSetupComparison, isTrue);
    expect(find.text('On'), findsWidgets);
  });
}
