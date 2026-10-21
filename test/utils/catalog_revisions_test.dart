import 'dart:math';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/utils/catalog_revisions.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// A component built from revision 1 of a brand file, read against later ones.

String _fork({required String header, required String hsc, String extra = ''}) =>
    '''
brand: FOX
component_type: fork
$header
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      adjustments:
        - $hsc
        - { name: Rebound, type: step, max: ~ }
$extra
    grip:
      name: GRIP
      adjustments:
        - { name: HSC, type: step, max: 8 }
nodes:
  - label: "36"
    level: model
    children:
      - label: Factory
        level: trim
        adjustments:
          - { name: Pressure, type: numerical, unit: psi, min: 0 }
        options:
          damper: [grip_x2, grip]
''';

const _hscBefore = '{ name: HSC, type: step, max: 8, notes: High-Speed Compression }';
const _hscNow = '{ name: HSC, type: step, max: 8, notes: High-Speed Compression circuit, dialColor: red }';

final _revision1 = parseCatalogFile(_fork(header: '', hsc: _hscBefore));

/// Revision 2 fixes the HSC notes, revision 3 adds an adjuster to review,
/// revision 4 fixes the HSC dial color.
final _revision4 = parseCatalogFile(
  _fork(
    hsc: _hscNow,
    extra: '        - { name: LSC, type: step, max: 16 }',
    header: '''
revision: 4
changes:
  - revision: 2
    when: { damper: grip_x2 }
    fix: { adjuster: hsc, field: notes, from: High-Speed Compression, to: High-Speed Compression circuit }
  - revision: 3
    when: { damper: grip_x2 }
    review: Adds the low-speed compression adjuster.
  - revision: 4
    when: { damper: grip_x2 }
    fix: { adjuster: hsc, field: dialColor, from: blue, to: red }
''',
  ),
);

/// Built from [catalog] with [damper] chosen, where the product offers one.
Component _component(BrandCatalog catalog, {String damper = 'grip_x2'}) {
  final product = catalogProducts(catalog).single;
  final axis = product.axes.singleOrNull;
  final app = buildCatalogApplication(
    axis == null ? product : product.select(axis, axis.values.firstWhere((value) => value.id == damper)),
  );
  return Component(
    id: 'fork',
    name: app.name,
    componentType: ComponentType.fork,
    installations: const [],
    adjustments: app.adjustments,
    preset: app.preset,
  );
}

ResolvedPreset _resolve(Component component, BrandCatalog catalog) => resolvePreset([catalog], component.preset!)!;

StepAdjustment _hsc(Component component) =>
    component.adjustments.whereType<StepAdjustment>().firstWhere((adjustment) => adjustment.presetKey == 'fork:hsc');

void main() {
  group('ComponentPreset.revision', () {
    test('reads a missing revision as 1 and stores only later ones', () {
      final preset = ComponentPreset(const {'brand': 'fox', 'component_type': 'fork'});

      expect(preset.revision, 1);
      expect(preset.withRevision(3).toJson()['revision'], 3);
      expect(preset.withRevision(3).withRevision(1).toJson().containsKey('revision'), isFalse);
    });

    test('a component built from the catalog stores its revision', () {
      expect(_component(_revision1).preset!.toJson().containsKey('revision'), isFalse);
      expect(_component(_revision4).preset!.revision, 4);
    });
  });

  group('applyCatalogFixes', () {
    test('applies a fix to an untouched field', () {
      final component = _component(_revision1);
      final resolved = _resolve(component, _revision4);

      final fixed = applyCatalogFixes(component.adjustments, resolved, _revision4.changes, const {});

      final hsc = fixed.whereType<StepAdjustment>().firstWhere((adjustment) => adjustment.presetKey == 'fork:hsc');
      expect(hsc.notes, 'High-Speed Compression circuit');
      expect(hsc.dialColor, StepAdjustmentDialColor.red);
      expect(hsc.id, _hsc(component).id, reason: 'Recorded values keep resolving');
    });

    test('skips a field the rider edited', () {
      final component = _component(_revision1);
      final edited = component.copyWith(
        adjustments: [
          for (final adjustment in component.adjustments)
            adjustment.presetKey == 'fork:hsc' ? adjustment.copyWith(notes: 'My notes') : adjustment,
        ],
      );

      final fixed = applyCatalogFixes(edited.adjustments, _resolve(edited, _revision4), _revision4.changes, const {});

      final hsc = fixed.whereType<StepAdjustment>().firstWhere((adjustment) => adjustment.presetKey == 'fork:hsc');
      expect(hsc.notes, 'My notes');
      expect(hsc.dialColor, StepAdjustmentDialColor.red, reason: 'The untouched color is still fixed');
    });

    test('leaves components outside the fix scope alone', () {
      final component = _component(_revision1, damper: 'grip');
      final resolved = _resolve(component, _revision4);

      final fixed = applyCatalogFixes(component.adjustments, resolved, catalogChangesSince(resolved, 1), const {});

      expect(fixed, component.adjustments, reason: 'The GRIP HSC has neither the notes nor the dial color fixed');
    });
  });

  group('migrateCatalogFixes', () {
    test('applies every fix but stops the revision before a pending review', () {
      final component = _component(_revision1);

      final migrated = migrateCatalogFixes(component, _resolve(component, _revision4), const {})!;

      expect(migrated.preset!.revision, 2);
      expect(_hsc(migrated).notes, 'High-Speed Compression circuit');
      expect(_hsc(migrated).dialColor, StepAdjustmentDialColor.red);
      expect(pendingCatalogReviews(_resolve(migrated, _revision4), migrated.preset!.revision).map((r) => r.summary), [
        'Adds the low-speed compression adjuster.',
      ]);
      expect(
        migrateCatalogFixes(migrated, _resolve(migrated, _revision4), const {}),
        isNull,
        reason: 'A second run is a no-op',
      );
    });

    test('raises the revision to the file revision when no review applies', () {
      final component = _component(_revision1, damper: 'grip');

      final migrated = migrateCatalogFixes(component, _resolve(component, _revision4), const {})!;

      expect(migrated.preset!.revision, 4);
      expect(migrated.adjustments, component.adjustments);
    });

    test('is null for a component that is up to date', () {
      final component = _component(_revision4);

      expect(migrateCatalogFixes(component, _resolve(component, _revision4), const {}), isNull);
      expect(pendingCatalogReviews(_resolve(component, _revision4), 4), isEmpty);
    });
  });

  group('range fixes against recorded values', () {
    const before = '''
brand: Acme
component_type: fork
nodes:
  - label: Bolt
    level: model
    adjustments:
      - { name: HSC, type: step, max: 20 }
''';

    /// The HSC max corrected from 20 to 16 in revision 2, by [fix].
    BrandCatalog corrected(String fix, {Map<String, CatalogMigrationStep> steps = const {}}) => parseCatalogFile(
      '''
brand: Acme
component_type: fork
revision: 2
changes:
  - { revision: 2, fix: $fix }
nodes:
  - label: Bolt
    level: model
    adjustments:
      - { name: HSC, type: step, max: 16 }
''',
      steps: steps,
    );

    /// The HSC of a fork built from [before], after [catalog]'s fixes with
    /// [recorded] HSC values.
    StepAdjustment migrated(BrandCatalog catalog, List<int> recorded) {
      final component = _component(parseCatalogFile(before));
      final fixed = applyCatalogFixes(
        component.adjustments,
        _resolve(component, catalog),
        catalog.changes,
        {
          _hsc(component).id: [for (final value in recorded) StepValue(value)],
        },
      );
      final hsc = fixed.whereType<StepAdjustment>().singleWhere((adjustment) => adjustment.presetKey == 'fork:hsc');
      expect(hsc.id, _hsc(component).id);
      return hsc;
    }

    const maxFix = '{ adjuster: hsc, field: max, from: 20, to: 16 }';

    test('a max fix applies while every recorded value fits', () {
      expect(migrated(corrected(maxFix), [3, 16]).max, 16);
    });

    test('a max fix is skipped when a recorded value would fall outside', () {
      expect(migrated(corrected(maxFix), [3, 18]).max, 20);
    });

    test('a step decides on the recorded values', () {
      final catalog = corrected(
        '{ adjuster: hsc, step: keep_recorded }',
        steps: {
          'keep_recorded': (context) {
            final highest = context.recorded.whereType<StepValue>().map((value) => value.value).fold(0, max);
            final catalogMax = (context.catalog as StepAdjustment).max;
            return (context.adjustment as StepAdjustment).copyWith(max: max(catalogMax, highest));
          },
        },
      );

      expect(migrated(catalog, [3, 18]).max, 18);
      expect(migrated(catalog, [3]).max, 16);
    });

    test('an unsafe or failing step leaves the adjustment as it is', () {
      Adjustment? Function(CatalogStepContext) narrowTo(int value) =>
          (context) => (context.adjustment as StepAdjustment).copyWith(max: value);
      final steps = <String, CatalogMigrationStep>{
        'too_narrow': narrowTo(10),
        'empty_range': narrowTo(0),
        'other_id': (context) => context.adjustment.copyWith(id: 'other'),
        'no_preset_key': (context) => context.adjustment.copyWith(presetKey: null),
        'throws': (context) => throw StateError('bug'),
      };

      for (final id in steps.keys) {
        expect(migrated(corrected('{ adjuster: hsc, step: $id }', steps: steps), [12]).max, 20, reason: id);
      }
    });
  });
}
