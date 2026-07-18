import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_preset.dart';
import 'package:bike_setup_tracker/repositories/component_preset_repository.dart';
import 'package:bike_setup_tracker/widgets/preset_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';


/// Stub repository that returns one variant per supplied brand, in the exact
/// order given. The real repository loads brands alphabetically, so ordering
/// here mimics that to prove the card reorders popular brands to the front.
class _FakePresetRepository extends ComponentPresetRepository {
  _FakePresetRepository(this.brands);

  final List<String> brands;

  @override
  Future<List<ComponentPresetVariant>> forType(ComponentType type) async {
    return [
      for (final brand in brands)
        ComponentPresetVariant(
          brand: brand,
          model: '$brand model',
          trim: 'base',
          componentType: type,
        ),
    ];
  }
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required List<String> brands,
  ComponentType type = ComponentType.fork,
}) async {
  await tester.pumpWidget(
    Provider<ComponentPresetRepository>.value(
      value: _FakePresetRepository(brands),
      child: MaterialApp(
        home: Scaffold(
          body: PresetCatalogCard(componentType: type, onTap: () {}),
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
}
