import 'package:bike_setup_tracker/widgets/sheets/language_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required String? localeCode,
    required ValueChanged<String?> onSelected,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      localizedTestApp(
        locale: locale,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => languageSheet(context: context, localeCode: localeCode, onSelected: onSelected),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final tiles = find.byType(InkWell);

  bool selected(String title) {
    final tile = find.ancestor(of: find.text(title), matching: tiles);
    return find.descendant(of: tile, matching: find.byIcon(Icons.check_circle)).evaluate().isNotEmpty;
  }

  testWidgets('names each language itself next to its flag', (tester) async {
    await openSheet(tester, localeCode: 'de', onSelected: (_) {});

    expect(find.text('English'), findsWidgets);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('🇬🇧'), findsOneWidget);
    expect(find.text('🇩🇪'), findsOneWidget);
  });

  testWidgets('scrolls when the languages do not fit the screen', (tester) async {
    tester.view.physicalSize = const Size(360, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openSheet(tester, localeCode: null, onSelected: (_) {});

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('English').last, findsOneWidget);
  });

  testWidgets('marks the system language when nothing is stored', (tester) async {
    await openSheet(tester, localeCode: null, onSelected: (_) {});

    expect(selected('System'), isTrue);
    expect(selected('Deutsch'), isFalse);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('shows the language the device would pick under System', (tester) async {
    await openSheet(tester, localeCode: null, onSelected: (_) {});

    // The test device speaks English: once as System's subtitle, once as its own tile.
    expect(find.text('English'), findsNWidgets(2));
  });

  testWidgets('marks the stored language', (tester) async {
    await openSheet(tester, localeCode: 'de', onSelected: (_) {});

    expect(selected('Deutsch'), isTrue);
    expect(selected('System'), isFalse);
  });

  testWidgets('hands the chosen code back and closes', (tester) async {
    String? chosen = 'unset';
    await openSheet(tester, localeCode: null, onSelected: (code) => chosen = code);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(chosen, 'de');
    expect(find.text('Sprache'), findsNothing);
    expect(find.text('Language'), findsNothing);
  });

  testWidgets('hands back null for the system language', (tester) async {
    String? chosen = 'unset';
    await openSheet(tester, localeCode: 'de', onSelected: (code) => chosen = code);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(chosen, isNull);
  });

  testWidgets('speaks German while the app is German', (tester) async {
    await openSheet(tester, localeCode: null, onSelected: (_) {}, locale: const Locale('de'));

    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });
}
