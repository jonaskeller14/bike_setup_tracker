import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/installation_timeline_hint_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late AppSettings appSettings;
  late Component component;

  setUp(() {
    appSettings = AppSettings();
    component = Component(
      id: 'component',
      name: 'Fork',
      componentType: ComponentType.fork,
      installations: [Installation.sinceBeginning(parent: 'bike')],
    );
  });

  tearDown(() => appSettings.dispose());

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appSettings,
        child: MaterialApp(
          theme: materialAppTheme,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    return tester.element(find.byType(Scaffold));
  }

  testWidgets('shows a synthetic timeline and returns activation', (tester) async {
    final context = await pumpHost(tester);
    final result = showInstallationTimelineHintSheet(context, component: component);
    await tester.pumpAndSettle();

    expect(find.text('Installation history'), findsOneWidget);
    expect(
      find.text(
        'Without installation history, the app only saves the bike where this component is installed now. '
        'It does not save past installs or removals. You can change this anytime in Settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Example timeline'), findsOneWidget);
    expect(find.text('Trail bike'), findsOneWidget);
    expect(find.text('Enduro bike'), findsOneWidget);

    await tester.tap(find.text('Activate now'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('returns dismissal from the explicit dismiss button', (tester) async {
    final context = await pumpHost(tester);
    final result = showInstallationTimelineHintSheet(context, component: component);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue without tracking'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });
}
