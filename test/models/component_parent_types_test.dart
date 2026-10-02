import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_parent_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const unfilteredTypes = {ComponentType.other, ComponentType.equipment};

  group('isSuggestedParent', () {
    test('tire fits on wheels but not on a brake pad or the frame', () {
      expect(isSuggestedParent(ComponentType.tire, ComponentType.wheelFront), isTrue);
      expect(isSuggestedParent(ComponentType.tire, ComponentType.wheelRear), isTrue);
      expect(isSuggestedParent(ComponentType.tire, ComponentType.brakePad), isFalse);
      expect(isSuggestedParent(ComponentType.tire, ComponentType.frame), isFalse);
    });

    test('saddle fits on the frame', () {
      expect(isSuggestedParent(ComponentType.saddle, ComponentType.frame), isTrue);
    });

    test('chain and frame have no suggested component parent', () {
      for (final parent in ComponentType.values) {
        expect(isSuggestedParent(ComponentType.chain, parent), isFalse);
        expect(isSuggestedParent(ComponentType.frame, parent), isFalse);
      }
    });

    test('unknown child type allows every parent', () {
      for (final parent in ComponentType.values) {
        expect(isSuggestedParent(null, parent), isTrue);
      }
    });

    test('other and equipment allow every parent', () {
      for (final child in unfilteredTypes) {
        for (final parent in ComponentType.values) {
          expect(isSuggestedParent(child, parent), isTrue);
        }
      }
    });
  });

  group('kSuggestedParentTypes', () {
    test('every type is either a key or explicitly unfiltered', () {
      for (final type in ComponentType.values) {
        expect(
          kSuggestedParentTypes.containsKey(type) ^ unfilteredTypes.contains(type),
          isTrue,
          reason: '$type must be a key or in unfilteredTypes, not both',
        );
      }
    });

    test('no type lists itself as a parent', () {
      kSuggestedParentTypes.forEach((child, parents) {
        expect(parents, isNot(contains(child)), reason: '$child');
      });
    });

    test('frame is a parent for every child except the excluded ones', () {
      const withoutFrame = {
        ComponentType.frame,
        ComponentType.chain,
        ComponentType.tire,
        ComponentType.brakePad,
        ComponentType.casette,
        ComponentType.chainring,
      };
      kSuggestedParentTypes.forEach((child, parents) {
        expect(
          parents.contains(ComponentType.frame),
          !withoutFrame.contains(child),
          reason: '$child',
        );
      });
    });
  });
}
