import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/repositories/component_preset_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// `byKey` resolves the provenance stored on a component
/// (`Component.presetKey`) back to its catalog entry.

ComponentPresetVariant _variant(String key, {bool complete = true}) =>
    ComponentPresetVariant(
      key: key,
      brand: 'FOX',
      model: '36',
      trim: 'Factory',
      componentType: ComponentType.fork,
      complete: complete,
    );

void main() {
  group('byKey', () {
    test('resolves a key to its variant', () async {
      final repository = ComponentPresetRepository.withVariants([
        _variant('fork-fox-36-factory-2025'),
        _variant('fork-fox-36-performance-2025'),
      ]);

      final variant = await repository.byKey('fork-fox-36-factory-2025');
      expect(variant?.key, 'fork-fox-36-factory-2025');
    });

    test('returns null for a key retired from the catalog', () async {
      final repository = ComponentPresetRepository.withVariants([
        _variant('fork-fox-36-factory-2025'),
      ]);

      expect(await repository.byKey('fork-fox-36-rhythm-2019'), isNull);
    });

    test('still resolves a trim that has gone incomplete', () async {
      // `complete: false` hides a trim from the picker, but a component saved
      // while it was complete has to keep resolving its provenance.
      final repository = ComponentPresetRepository.withVariants([
        _variant('fork-fox-36-factory-2025', complete: false),
      ]);

      expect(await repository.byKey('fork-fox-36-factory-2025'), isNotNull);
      expect(await repository.all(), isEmpty);
    });
  });
}
