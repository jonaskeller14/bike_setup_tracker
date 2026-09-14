import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_tags_bulk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BulkTagChanges? result;
  late bool dismissed;

  setUp(() {
    result = null;
    dismissed = false;
  });

  Widget harness(List<Set<String>> itemTags, {Set<String> availableTags = const {}}) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showSetTagsBulkSheet(
                context: context,
                itemTags: itemTags,
                availableTags: availableTags,
                title: 'Set Tags',
                subtitle: 'Use tags to group your tasks',
                applyLabel: 'Apply to ${itemTags.length} Tasks',
              );
              dismissed = result == null;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String tag) async {
    await tester.tap(find.text(tag));
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.text('Apply to 3 Tasks'));
    await tester.pumpAndSettle();
  }

  bool applyEnabled(WidgetTester tester) {
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    return button.onPressed != null;
  }

  Finder chipFinder(String tag) => find.ancestor(of: find.text(tag), matching: find.byType(FilterChip));

  FilterChip chipFor(WidgetTester tester, String tag) => tester.widget<FilterChip>(chipFinder(tag));

  /// A partially assigned tag is drawn as a diagonally half-filled chip.
  bool isPartial(WidgetTester tester, String tag) {
    return find.byKey(ValueKey('tag-partial-$tag')).evaluate().isNotEmpty;
  }

  const mixedSelection = [
    {'service', 'winter'},
    {'service'},
    <String>{},
  ];

  testWidgets('half-fills a partially assigned tag and keeps the tag avatar', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    expect(isPartial(tester, 'service'), isTrue);
    expect(isPartial(tester, 'winter'), isTrue);
    expect(chipFor(tester, 'service').selected, isFalse);
    expect(find.byIcon(Icons.tag), findsNWidgets(2)); // one per chip
    expect(find.byTooltip('Add tag'), findsOneWidget);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('explains the half-filled state only while a tag starts out partial', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    expect(find.textContaining('Half-filled tags'), findsOneWidget);

    // The hint describes the starting point, so cycling a tag keeps it visible.
    await tapChip(tester, 'service');
    await tapChip(tester, 'winter');
    expect(find.textContaining('Half-filled tags'), findsOneWidget);
  });

  testWidgets('omits the half-filled hint when every tag is on all or none', (tester) async {
    await tester.pumpWidget(harness(const [
      {'service'},
      {'service'},
    ], availableTags: {'race'}));
    await open(tester);

    expect(find.textContaining('Half-filled tags'), findsNothing);
  });

  testWidgets('aligns the partial fill with the chip outline', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    final fill = find.byKey(const ValueKey('tag-partial-service'));
    final chipSurface = find.descendant(of: chipFinder('service'), matching: find.byType(Material)).first;

    expect(tester.getRect(fill), tester.getRect(chipSurface));
  });

  testWidgets('paints the partial fill over half the chip', (tester) async {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: materialAppTheme,
      home: RepaintBoundary(
        key: boundaryKey,
        child: const Scaffold(
          body: SetTagsBulkSheetContent(
            itemTags: mixedSelection,
            availableTags: {'service', 'winter', 'race'},
            title: 'Set Tags',
            subtitle: 'Use tags to group your tasks',
            applyLabel: 'Apply to 3 Tasks',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    late ui.Image image;
    late ByteData bytes;
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      image = await boundary.toImage();
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });

    Color pixel(Offset point) {
      final index = (point.dy.round() * image.width + point.dx.round()) * 4;
      return Color.fromARGB(
        bytes.getUint8(index + 3),
        bytes.getUint8(index),
        bytes.getUint8(index + 1),
        bytes.getUint8(index + 2),
      );
    }

    // The diagonal runs bottom-left to top-right, so the bottom-right corner is
    // filled and the top-left corner is not. Both points sit clear of the
    // avatar and label.
    final partial = tester.getRect(chipFinder('service'));
    final unselected = tester.getRect(chipFinder('race'));
    final filledHalf = pixel(Offset(partial.right - 10, partial.bottom - 4));
    final emptyHalf = pixel(Offset(partial.left + 10, partial.top + 4));
    final plain = pixel(Offset(unselected.left + 10, unselected.top + 4));

    expect(filledHalf, materialAppTheme.colorScheme.secondaryContainer);
    expect(emptyHalf, isNot(filledHalf), reason: 'the diagonal split must be visible');
    expect(emptyHalf, plain, reason: 'the unfilled half must match an unselected chip');
  });

  testWidgets('marks a tag every item carries as selected without a checkmark', (tester) async {
    await tester.pumpWidget(harness(const [
      {'service'},
      {'service', 'winter'},
      {'service'},
    ]));
    await open(tester);

    expect(chipFor(tester, 'service').selected, isTrue);
    expect(chipFor(tester, 'service').showCheckmark, isFalse);
    expect(isPartial(tester, 'service'), isFalse);
  });

  testWidgets('cycles a partially assigned tag through add, remove and back to mixed', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tapChip(tester, 'service');
    expect(chipFor(tester, 'service').selected, isTrue);
    expect(isPartial(tester, 'service'), isFalse);
    expect(applyEnabled(tester), isTrue);

    await tapChip(tester, 'service');
    expect(chipFor(tester, 'service').selected, isFalse);
    expect(isPartial(tester, 'service'), isFalse);
    expect(applyEnabled(tester), isTrue);

    await tapChip(tester, 'service');
    expect(isPartial(tester, 'service'), isTrue);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('leaves untouched tags out of the applied changes', (tester) async {
    await tester.pumpWidget(harness(mixedSelection, availableTags: const {'service', 'winter', 'race'}));
    await open(tester);

    await tapChip(tester, 'race');
    await apply(tester);

    expect(result?.added, {'race'});
    expect(result?.removed, isEmpty);
    expect(result!.apply({'service', 'winter'}), {'service', 'winter', 'race'});
    expect(result!.apply(const {}), {'race'});
  });

  testWidgets('removes a tag from every item via the chip delete button', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('winter'), matching: find.byType(FilterChip)),
      matching: find.byTooltip('Delete'),
    ));
    await tester.pumpAndSettle();
    await apply(tester);

    expect(result?.added, isEmpty);
    expect(result?.removed, {'winter'});
    expect(result!.apply({'service', 'winter'}), {'service'});
  });

  testWidgets('assigns a newly created tag to every item', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tester.tap(find.byTooltip('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tubeless');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(chipFor(tester, 'tubeless').selected, isTrue);
    // The field collapses back to the bare add button after a successful add.
    expect(find.byType(TextField), findsNothing);

    await apply(tester);
    expect(result?.added, {'tubeless'});
    expect(result?.removed, isEmpty);
  });

  testWidgets('grows the new-tag field with the typed text, then caps it at the sheet width',
      (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tester.tap(find.byTooltip('Add tag'));
    await tester.pumpAndSettle();
    final double hintWidth = tester.getSize(find.byType(TextField)).width;

    await tester.enterText(find.byType(TextField), 'a fairly long tag name');
    await tester.pumpAndSettle();
    final double grownWidth = tester.getSize(find.byType(TextField)).width;
    expect(grownWidth, greaterThan(hintWidth));

    await tester.enterText(find.byType(TextField), 'x' * 400);
    await tester.pumpAndSettle();
    final double cappedWidth = tester.getSize(find.byType(TextField)).width;
    final double availableWidth = tester
        .getSize(find.ancestor(of: find.byType(TextField), matching: find.byType(Wrap)))
        .width;
    expect(cappedWidth, greaterThan(grownWidth));
    expect(cappedWidth, availableWidth, reason: 'the field stops growing once it fills the row');
  });

  testWidgets('rejects a duplicate tag inline', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tester.tap(find.byTooltip('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'service');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Tag already exists'), findsOneWidget);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('opens the new-tag field instead of the empty placeholder when there are no tags',
      (tester) async {
    await tester.pumpWidget(harness(const [<String>{}, <String>{}, <String>{}]));
    await open(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('No tags yet'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tubeless');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(chipFor(tester, 'tubeless').selected, isTrue);
    await apply(tester);
    expect(result?.added, {'tubeless'});
  });

  testWidgets('returns null when the sheet is dismissed', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tapChip(tester, 'service');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
