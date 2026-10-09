import 'dart:async';

import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/widgets/sheets/component_catalog_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The picker drills into brand trees of any depth, asks for required axes one
/// at a time and for optional axes in one skippable step. Fixtures are inline
/// YAML run through the real [parseCatalogFile].

const _foxYaml = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      description: Top damper
      adjustments:
        - { name: High Speed Compression, type: step, max: 8 }
    grip_x:
      name: GRIP X
      adjustments:
        - { name: Rebound, type: step, max: ~ }
nodes:
  - label: "36"
    level: model
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        years: "2025-2026"
        children:
          - label: Factory
            level: trim
            options:
              damper: [grip_x2, grip_x]
              travel_mm: [150, 160]
              wheel_size: [29]
          - label: Performance
            level: trim
            options:
              damper: [grip_x]
              travel_mm: [150, 160]
      - label: "2021–2024"
        level: generation
        id: "2021"
        draft: true
        children:
          - label: Rhythm
            level: trim
''';

/// One level deep: the model itself is the product, without any options.
const _acmeYaml = '''
brand: Acme
component_type: fork
nodes:
  - label: Bolt
    level: model
''';

/// Every entry is draft, so the brand must not be offered at all.
const _draftYaml = '''
brand: Ghost
component_type: fork
nodes:
  - label: Phantom
    level: model
    draft: true
''';

const _ohlinsYaml = '''
brand: Öhlins
component_type: shock
nodes:
  - label: TTX22
    level: model
    children:
      - label: m.2
        level: version
        id: m2
        options:
          size: ["210x50/52.5/55", "185x50/55"]
''';

ComponentCatalogRepository _repository([List<String> files = const [_foxYaml, _acmeYaml, _draftYaml, _ohlinsYaml]]) =>
    ComponentCatalogRepository.withCatalogs([for (final file in files) parseCatalogFile(file)]);

class _FailingRepository extends ComponentCatalogRepository {
  @override
  Future<List<ResolvedPreset>> forType(ComponentType type) => Future.error(StateError('broken asset'));
}

class _PendingRepository extends ComponentCatalogRepository {
  final Completer<List<ResolvedPreset>> completer = Completer();

  @override
  Future<List<ResolvedPreset>> forType(ComponentType type) => completer.future;
}

/// Holds what the sheet returned once it closes.
class _Outcome {
  bool closed = false;
  ResolvedPreset? result;
}

Future<_Outcome> _open(
  WidgetTester tester, {
  ComponentCatalogRepository? repository,
  ComponentType type = ComponentType.fork,
  ResolvedPreset? current,
  bool settle = true,
}) async {
  final outcome = _Outcome();
  await tester.pumpWidget(
    Provider<ComponentCatalogRepository>.value(
      value: repository ?? _repository(),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                outcome.result = await showComponentCatalogPicker(
                  context: context,
                  componentType: type,
                  current: current,
                );
                outcome.closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return outcome;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChoiceChip, label));
  await tester.pumpAndSettle();
}

/// Brand → model → generation → trim on FOX.
Future<void> _openFoxTrims(WidgetTester tester) async {
  await _tap(tester, 'FOX');
  await _tap(tester, '36');
  await _tap(tester, '2025–2026');
}

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<ListTile>(find.widgetWithText(ListTile, label)).selected;

/// FOX 36 Factory with GRIP X2 and 160 mm by default, from its own parse of
/// the file, as a saved component resolves it.
ResolvedPreset _currentFoxFactory([Map<String, Object> values = const {'damper': 'grip_x2', 'travel_mm': 160}]) {
  var preset = catalogProducts(parseCatalogFile(_foxYaml)).first;
  for (final MapEntry(key: axisId, value: valueId) in values.entries) {
    final axis = preset.product!.options[axisId]!;
    preset = preset.select(axis, axis.values.firstWhere((value) => value.id == valueId));
  }
  return preset;
}

void main() {
  group('drill-down', () {
    testWidgets('lists brands with selectable products only', (tester) async {
      await _open(tester);

      expect(find.text('Choose from catalog'), findsOneWidget);
      expect(find.text('FOX'), findsOneWidget);
      expect(find.text('Acme'), findsOneWidget);
      expect(find.text('Ghost'), findsNothing);
      expect(find.text('Öhlins'), findsNothing, reason: 'shocks are a different type');
    });

    testWidgets('titles each stage after its level and hides draft nodes', (tester) async {
      await _open(tester);

      await _tap(tester, 'FOX');
      expect(find.text('Select model'), findsOneWidget);

      await _tap(tester, '36');
      expect(find.text('Select generation'), findsOneWidget);
      expect(find.text('2025–2026'), findsOneWidget);
      expect(find.text('2021–2024'), findsNothing);

      await _tap(tester, '2025–2026');
      expect(find.text('Select trim'), findsOneWidget);
      expect(find.text('FOX 36 2025–2026'), findsOneWidget, reason: 'the context line names the path');
      expect(find.text('Factory'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
    });

    testWidgets('a one-level brand returns its product straight away', (tester) async {
      final outcome = await _open(tester);

      await _tap(tester, 'Acme');
      await _tap(tester, 'Bolt');

      expect(outcome.closed, isTrue);
      expect(outcome.result?.product?.label, 'Bolt');
      expect(toComponentPreset(outcome.result!).toJson(), {'brand': 'acme', 'component_type': 'fork', 'model': 'bolt'});
    });

    testWidgets('back returns to the previous level', (tester) async {
      await _open(tester);
      await _openFoxTrims(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Select generation'), findsOneWidget);
    });
  });

  group('option axes', () {
    testWidgets('asks for the required axis, then applies the chosen optional value', (tester) async {
      final outcome = await _open(tester);
      await _openFoxTrims(tester);

      await _tap(tester, 'Factory');
      expect(find.text('Select damper'), findsOneWidget);
      expect(find.textContaining('HSC 8'), findsOneWidget);
      expect(find.textContaining('Rebound ?'), findsOneWidget, reason: 'a placeholder max is not a range');

      await _tap(tester, 'GRIP X2');
      expect(find.text('Optional details'), findsOneWidget);
      expect(find.text('Wheel size'), findsNothing, reason: 'a single value resolves without asking');
      expect(find.text('Skip'), findsOneWidget);

      await _tapChip(tester, '160 mm');
      await _tap(tester, 'Apply');

      expect(toComponentPreset(outcome.result!).toJson(), {
        'brand': 'fox',
        'component_type': 'fork',
        'model': '36',
        'generation': '2025',
        'trim': 'factory',
        'damper': 'grip_x2',
        'travel_mm': 160,
        'wheel_size': '29',
      });
    });

    testWidgets('skip leaves the optional axes unset', (tester) async {
      final outcome = await _open(tester);
      await _openFoxTrims(tester);
      await _tap(tester, 'Factory');
      await _tap(tester, 'GRIP X');

      await _tapChip(tester, '150 mm');
      await _tapChip(tester, '150 mm');
      expect(find.text('Skip'), findsOneWidget, reason: 'tapping a chosen chip again clears it');

      await _tap(tester, 'Skip');

      final map = toComponentPreset(outcome.result!).toJson();
      expect(map['damper'], 'grip_x');
      expect(map.containsKey('travel_mm'), isFalse);
    });

    testWidgets('a single-value required axis is not asked for', (tester) async {
      final outcome = await _open(tester);
      await _openFoxTrims(tester);

      await _tap(tester, 'Performance');
      expect(find.text('Select damper'), findsNothing);
      expect(find.text('Optional details'), findsOneWidget);

      await _tap(tester, 'Skip');
      expect(toComponentPreset(outcome.result!).toJson()['damper'], 'grip_x');
    });

    testWidgets('groups shock sizes by eye-to-eye length', (tester) async {
      final outcome = await _open(tester, type: ComponentType.shock);
      await _tap(tester, 'Öhlins');
      await _tap(tester, 'TTX22');
      expect(find.text('Select version'), findsOneWidget);

      await _tap(tester, 'm.2');
      expect(find.text('Eye-to-eye 210 mm'), findsOneWidget);
      expect(find.text('Eye-to-eye 185 mm'), findsOneWidget);

      await _tapChip(tester, '185x55 mm');
      await _tap(tester, 'Apply');
      expect(toComponentPreset(outcome.result!).toJson()['size'], '185x55');
    });
  });

  testWidgets('a row whose tap completes the selection shows a check', (tester) async {
    await _open(tester);

    await _tap(tester, 'Acme');
    expect(
      find.descendant(of: find.widgetWithText(ListTile, 'Bolt'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await _openFoxTrims(tester);
    expect(
      find.descendant(of: find.widgetWithText(ListTile, 'Factory'), matching: find.byIcon(Icons.arrow_forward_ios)),
      findsOneWidget,
      reason: 'a damper and a travel are still to be asked for',
    );
  });

  group('with a current selection', () {
    testWidgets('opens on the optional details with the current options chosen', (tester) async {
      final outcome = await _open(tester, current: _currentFoxFactory());

      expect(find.text('Optional details'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '160 mm')).selected, isTrue);

      await _tapChip(tester, '150 mm');
      await _tap(tester, 'Apply');
      final map = toComponentPreset(outcome.result!).toJson();
      expect(map['damper'], 'grip_x2');
      expect(map['travel_mm'], 150);
    });

    testWidgets('back leads through the current damper and up the path to it', (tester) async {
      await _open(tester, current: _currentFoxFactory());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Select damper'), findsOneWidget);
      expect(_isSelected(tester, 'GRIP X2'), isTrue);
      expect(_isSelected(tester, 'GRIP X'), isFalse);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Select trim'), findsOneWidget);
      expect(_isSelected(tester, 'Factory'), isTrue);
      expect(_isSelected(tester, 'Performance'), isFalse);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Select generation'), findsOneWidget);
      expect(_isSelected(tester, '2025–2026'), isTrue);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Choose from catalog'), findsOneWidget, reason: 'back leads up to the brand list');
      expect(_isSelected(tester, 'FOX'), isTrue);
      expect(_isSelected(tester, 'Acme'), isFalse);
    });

    testWidgets('changing the damper keeps the current options', (tester) async {
      final outcome = await _open(tester, current: _currentFoxFactory());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await _tap(tester, 'GRIP X');
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '160 mm')).selected, isTrue);

      await _tap(tester, 'Apply');
      final map = toComponentPreset(outcome.result!).toJson();
      expect(map['damper'], 'grip_x');
      expect(map['travel_mm'], 160);
    });

    testWidgets('opens on a required axis without a current value', (tester) async {
      await _open(tester, current: _currentFoxFactory(const {'travel_mm': 160}));

      expect(find.text('Select damper'), findsOneWidget);
      expect(_isSelected(tester, 'GRIP X2'), isFalse);
      expect(_isSelected(tester, 'GRIP X'), isFalse);
    });

    testWidgets('a product with nothing to ask opens among its siblings', (tester) async {
      await _open(tester, current: catalogProducts(parseCatalogFile(_acmeYaml)).first);

      expect(find.text('Select model'), findsOneWidget);
      expect(_isSelected(tester, 'Bolt'), isTrue);
    });

    testWidgets('a current selection of another type is ignored', (tester) async {
      await _open(tester, type: ComponentType.shock, current: _currentFoxFactory());

      expect(find.text('Choose from catalog'), findsOneWidget);
    });
  });

  testWidgets('search jumps straight to a product', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'grip x2');
    await tester.pumpAndSettle();
    expect(find.text('FOX 36 Factory'), findsOneWidget);
    expect(find.text('FOX 36 Performance'), findsNothing);

    await _tap(tester, 'FOX 36 Factory');
    expect(find.text('Select damper'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('FOX 36 Factory'), findsOneWidget, reason: 'back returns to the results');
  });

  group('states', () {
    testWidgets('shows a loading bar until the catalog arrives', (tester) async {
      final repository = _PendingRepository();
      await _open(tester, repository: repository, settle: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      repository.completer.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows an empty hint when nothing is selectable', (tester) async {
      await _open(tester, repository: _repository(const [_draftYaml]));

      expect(find.text('No catalog entries available.'), findsOneWidget);
    });

    testWidgets('shows a failure message when the catalog cannot load', (tester) async {
      await _open(tester, repository: _FailingRepository());

      expect(find.text('Could not load the catalog.'), findsOneWidget);
    });
  });

  testWidgets('long labels and many size chips fit a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final strokes = [for (var stroke = 40; stroke <= 65; stroke++) '$stroke'].join('/');
    final yaml =
        '''
brand: Cane Creek With An Unusually Long Brand Name For Testing
component_type: shock
nodes:
  - label: DBcoil IL Inline Coil Shock With A Very Long Model Name That Wraps
    level: model
    years: "2019-2026"
    category: Enduro And Downhill Long Category Name
    options:
      size: ["210x$strokes", { size: "230x60", label: "9.0x2.35in with a long part number MTBM 9999-XXL" }]
''';
    await _open(tester, repository: _repository([yaml]), type: ComponentType.shock);

    await _tap(tester, 'Cane Creek With An Unusually Long Brand Name For Testing');
    await _tap(tester, 'DBcoil IL Inline Coil Shock With A Very Long Model Name That Wraps');

    expect(find.byType(ChoiceChip), findsNWidgets(27));
    expect(tester.takeException(), isNull);
  });
}
