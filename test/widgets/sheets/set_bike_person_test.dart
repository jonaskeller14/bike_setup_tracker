import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_bike_person.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ({String? person})? result;
  late bool dismissed;

  final anna = Person(id: 'anna', name: 'Anna');
  final ben = Person(id: 'ben', name: 'Ben');
  final persons = {anna.id: anna, ben.id: ben};

  setUp(() {
    result = null;
    dismissed = false;
  });

  Widget harness(List<String?> bikePersons, {Map<String, Person>? personsOverride}) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showSetBikePersonSheet(
                context: context,
                bikePersons: bikePersons,
                persons: personsOverride ?? persons,
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

  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  bool applyEnabled(WidgetTester tester) {
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    return button.onPressed != null;
  }

  FilterChip chipFor(WidgetTester tester, String label) =>
      tester.widget<FilterChip>(find.ancestor(of: find.text(label), matching: find.byType(FilterChip)));

  bool isPartial(String key) => find.byKey(ValueKey('person-partial-$key')).evaluate().isNotEmpty;

  const mixedSelection = ['anna', 'anna', null];

  testWidgets('half-fills riders on only part of the selection', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    expect(isPartial('anna'), isTrue);
    expect(isPartial('none'), isTrue);
    expect(isPartial('ben'), isFalse);
    expect(chipFor(tester, 'Ben').selected, isFalse);
    expect(find.textContaining('Half-filled chips'), findsOneWidget);
    expect(find.text('Apply to 3 Bikes'), findsOneWidget);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('marks the rider of every bike as selected without the half-filled hint', (tester) async {
    await tester.pumpWidget(harness(const ['anna', 'anna']));
    await open(tester);

    expect(chipFor(tester, 'Anna').selected, isTrue);
    expect(chipFor(tester, 'Anna').showCheckmark, isFalse);
    expect(isPartial('anna'), isFalse);
    expect(find.textContaining('Half-filled chips'), findsNothing);
  });

  testWidgets('picking a rider clears the others, tapping it again restores the mix', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tapChip(tester, 'Ben');
    expect(chipFor(tester, 'Ben').selected, isTrue);
    expect(chipFor(tester, 'Anna').selected, isFalse);
    expect(chipFor(tester, 'No rider').selected, isFalse);
    expect(isPartial('anna'), isFalse);
    expect(isPartial('none'), isFalse);
    expect(applyEnabled(tester), isTrue);

    await tapChip(tester, 'Ben');
    expect(chipFor(tester, 'Ben').selected, isFalse);
    expect(isPartial('anna'), isTrue);
    expect(isPartial('none'), isTrue);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('keeps apply disabled when the pick is the rider every bike already has', (tester) async {
    await tester.pumpWidget(harness(const ['anna', 'anna']));
    await open(tester);

    await tapChip(tester, 'Ben');
    expect(applyEnabled(tester), isTrue);

    await tapChip(tester, 'Anna');
    expect(chipFor(tester, 'Anna').selected, isTrue);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('returns the picked rider', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tapChip(tester, 'Anna');
    await apply(tester);

    expect(result, (person: 'anna'));
  });

  testWidgets('returns a null person for "No rider"', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tapChip(tester, 'No rider');
    await apply(tester);

    expect(dismissed, isFalse);
    expect(result, (person: null));
  });

  testWidgets('offers only "No rider" with a hint when there are no riders', (tester) async {
    await tester.pumpWidget(harness(const [null], personsOverride: const {}));
    await open(tester);

    expect(find.byType(FilterChip), findsOneWidget);
    expect(chipFor(tester, 'No rider').selected, isTrue);
    expect(find.textContaining("as soon as you've created one"), findsOneWidget);
  });

  testWidgets('returns null when the sheet is dismissed', (tester) async {
    await tester.pumpWidget(harness(mixedSelection));
    await open(tester);

    await tapChip(tester, 'Ben');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
