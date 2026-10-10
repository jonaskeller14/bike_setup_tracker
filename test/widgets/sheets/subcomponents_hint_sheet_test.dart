import 'dart:async';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_cell.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_group.dart';
import 'package:bike_setup_tracker/widgets/sheets/sheet_header.dart';
import 'package:bike_setup_tracker/widgets/sheets/subcomponents_hint_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late AppSettings appSettings;

  setUp(() => appSettings = AppSettings());

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

  Finder groupsInCard(int index) => find.descendant(
    of: find.byType(Card).at(index),
    matching: find.byType(GarageComponentGroup),
  );

  testWidgets('compares the same bike without and with subcomponents and returns the selection', (tester) async {
    final context = await pumpHost(tester);
    final result = showSubcomponentsSettingSheet(context, value: false);
    await tester.pumpAndSettle();

    expect(find.text('Subcomponents'), findsOneWidget);
    expect(find.text('Without subcomponents'), findsOneWidget);
    expect(find.text('With subcomponents'), findsOneWidget);
    expect(find.text('Trail bike'), findsNWidgets(2));
    // Same 8 components in both cards: flat without, two wheel groups with.
    expect(groupsInCard(0), findsNothing);
    expect(groupsInCard(1), findsNWidgets(2));
    expect(find.byType(GarageComponentCell), findsNWidgets(16));

    await tester.tap(find.text('On'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('lays out without overflow on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final context = await pumpHost(tester);
    unawaited(showSubcomponentsSettingSheet(context, value: false));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GarageComponentGroup), findsNWidgets(2));
  });

  testWidgets('returns null when dismissed without a selection', (tester) async {
    final context = await pumpHost(tester);
    final result = showSubcomponentsSettingSheet(context, value: true);
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(SheetHeader), matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
