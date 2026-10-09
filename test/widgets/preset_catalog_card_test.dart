import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/widgets/preset_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// One product per supplied brand, in the exact order given. The real
/// repository loads brands alphabetically, so ordering here mimics that to
/// prove the card reorders popular brands to the front.
ComponentCatalogRepository _repository(List<String> brands, ComponentType type) {
  return ComponentCatalogRepository.withCatalogs([
    for (final brand in brands)
      parseCatalogFile('''
brand: $brand
component_type: ${type.name}
nodes:
  - label: Base
    level: model
'''),
  ]);
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required List<String> brands,
  ComponentType type = ComponentType.fork,
}) async {
  await tester.pumpWidget(
    Provider<ComponentCatalogRepository>.value(
      value: _repository(brands, type),
      child: MaterialApp(
        home: Scaffold(
          body: PresetCatalogCard(componentType: type, onTap: () {}, onUnlink: () {}),
        ),
      ),
    ),
  );
  // Let the async teaser load resolve and rebuild.
  await tester.pumpAndSettle();
}

/// Reads the ListTile subtitle text currently rendered by the card.
String _subtitle(WidgetTester tester) {
  final tile = tester.widget<ListTile>(find.byType(ListTile));
  return (tile.subtitle as Text).data!;
}

void main() {
  group('PresetCatalogCard teaser', () {
    testWidgets('surfaces popular brands (FOX, RockShox) before smaller ones',
        (tester) async {
      // Alphabetical input, as the real repository provides it.
      await _pumpCard(tester, brands: [
        'Cane Creek',
        'DVO',
        'FOX',
        'RockShox',
      ]);

      // FOX and RockShox jump to the front; the rest keep alpha order.
      // Four brands means the "more" indicator is appended.
      expect(_subtitle(tester), 'FOX · RockShox · Cane Creek · …');
    });

    testWidgets('is case-insensitive when matching popular brands',
        (tester) async {
      await _pumpCard(tester, brands: ['Cane Creek', 'fox', 'rockshox']);

      // Exactly three brands: reordered, no "more" indicator.
      expect(_subtitle(tester), 'fox · rockshox · Cane Creek');
    });

    testWidgets('appends the more indicator only when brands exceed three',
        (tester) async {
      await _pumpCard(tester, brands: ['FOX', 'RockShox', 'DVO']);
      expect(_subtitle(tester), 'FOX · RockShox · DVO');
      expect(_subtitle(tester).contains('…'), isFalse);
    });

    testWidgets('keeps non-popular brands in their original order',
        (tester) async {
      await _pumpCard(tester, brands: ['Cane Creek', 'DVO', 'EXT']);
      expect(_subtitle(tester), 'Cane Creek · DVO · EXT');
    });

    testWidgets('falls back to the generic subtitle when there are no brands',
        (tester) async {
      await _pumpCard(tester, brands: [], type: ComponentType.shock);
      expect(_subtitle(tester), 'Prefill from a shock model');
    });
  });

  group('PresetCatalogCard applied state', () {
    final catalog = parseCatalogFile('''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2: { name: GRIP X2, adjustments: [{ name: HSC, type: step, max: 8 }] }
    grip_x: { name: GRIP X, adjustments: [{ name: LSC, type: step, max: 16 }] }
nodes:
  - label: "38"
    level: model
    children:
      - label: "2021–2024"
        level: generation
        id: "2021"
        years: "2021-2024"
        children:
          - label: Factory
            level: trim
            options:
              damper: [grip_x2, grip_x]
              travel_mm: [170, 180]
''');

    Future<void> pumpApplied(
      WidgetTester tester, {
      required Map<String, Object> preset,
      VoidCallback? onUnlink,
    }) async {
      await tester.pumpWidget(
        Provider<ComponentCatalogRepository>.value(
          value: ComponentCatalogRepository.withCatalogs([catalog]),
          child: MaterialApp(
            home: Scaffold(
              body: PresetCatalogCard(
                componentType: ComponentType.fork,
                onTap: () {},
                applied: resolvePreset([catalog], ComponentPreset(preset)),
                onUnlink: onUnlink ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    const fullPreset = <String, Object>{
      'brand': 'fox',
      'component_type': 'fork',
      'model': '38',
      'generation': '2021',
      'trim': 'factory',
      'damper': 'grip_x2',
      'travel_mm': 180,
    };

    testWidgets('shows the path and the required choice in the title, the optional ones below',
        (tester) async {
      await pumpApplied(tester, preset: fullPreset);

      expect(find.text('FOX 38 Factory GRIP X2'), findsOneWidget);
      expect(_subtitle(tester), '180 mm · 2021-2024 · Tap to change');
      expect(find.text('Choose from catalog'), findsNothing);
    });

    testWidgets('leaves a skipped optional choice out', (tester) async {
      await pumpApplied(tester, preset: {...fullPreset}..remove('travel_mm'));

      expect(_subtitle(tester), '2021-2024 · Tap to change');
    });

    testWidgets('a partial resolution shows the deepest node', (tester) async {
      await pumpApplied(tester, preset: {...fullPreset, 'trim': 'retired'});

      expect(find.text('FOX 38'), findsOneWidget);
      // The generation the map still matches carries the years.
      expect(_subtitle(tester), '2021-2024 · Tap to change');
    });

    testWidgets('unlink button fires onUnlink', (tester) async {
      var unlinked = 0;
      await pumpApplied(tester, preset: fullPreset, onUnlink: () => unlinked++);

      await tester.tap(find.byTooltip('Unlink preset (keeps values)'));
      expect(unlinked, 1);
    });
  });
}
