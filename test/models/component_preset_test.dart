import 'dart:convert';

import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entries = <String, Object>{
    'brand': 'fox',
    'component_type': 'fork',
    'model': '36',
    'trim': 'factory',
    'damper': 'grip_x2',
    'travel_mm': 160,
    'wheel_size': '29',
  };

  group('ComponentPreset', () {
    test('reads the fixed keys and any level or axis by name', () {
      final preset = ComponentPreset(entries);

      expect(preset.brand, 'fox');
      expect(preset.componentType, ComponentType.fork);
      expect(preset['trim'], 'factory');
      expect(preset['travel_mm'], 160);
      expect(preset['generation'], isNull);
    });

    test('an unknown component type reads as null', () {
      expect(ComponentPreset(const {'brand': 'fox', 'component_type': 'hovercraft'}).componentType, isNull);
      expect(ComponentPreset(const {}).componentType, isNull);
    });

    test('is not changed by the map it was built from', () {
      final source = Map<String, Object>.of(entries);
      final preset = ComponentPreset(source);
      source['damper'] = 'grip_x';

      expect(preset['damper'], 'grip_x2');
      expect(() => preset.toJson()['damper'] = 'grip_x', throwsUnsupportedError);
    });

    test('survives a JSON round trip, numbers included', () {
      final restored = ComponentPreset.tryFromJson(jsonDecode(jsonEncode(ComponentPreset(entries).toJson())));

      expect(restored, ComponentPreset(entries));
      expect(restored!['travel_mm'], 160);
    });

    test('tryFromJson rejects anything but an object of strings and numbers', () {
      for (final malformed in <Object?>[
        null,
        'fox',
        [1, 2],
        {
          'brand': 'fox',
          'damper': {'id': 'grip_x2'},
        },
        {'brand': 'fox', 'remote': true},
      ]) {
        expect(ComponentPreset.tryFromJson(malformed), isNull, reason: '$malformed');
      }
    });

    test('compares by value, regardless of key order', () {
      final a = ComponentPreset(entries);
      final reordered = ComponentPreset(Map.fromEntries(entries.entries.toList().reversed));
      final other = ComponentPreset(Map.of(entries)..['damper'] = 'grip_x');

      expect(reordered, a);
      expect(reordered.hashCode, a.hashCode);
      expect(other == a, isFalse);
      expect(other.hashCode == a.hashCode, isFalse);
    });
  });
}
