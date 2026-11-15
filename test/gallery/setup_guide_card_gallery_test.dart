// Renders the states of SetupGuideCard (the columns layout, collapsed and
// expanded) and its info sheet to PNGs in build/gallery/setup_guide_card/
// (git-ignored), for a quick visual check after changing either widget. Skipped
// by default (see dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/setup_guide_card_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; the
// cards and the sheet are also written on their own.
//
// Names that start with "my" are user data (Component.name, the rider). Anything
// else on screen (Pressure, LSC, hints, reasons) comes from the catalog or the UI.
//
// Besides the pictures, the second test checks that no state traps the user:
// every row that can be applied can be, and every row that cannot says why.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_actions.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _cellWidth = 360.0;
const _sheetWidth = 400.0;

const _catalog = '''
brand: Acme
component_type: fork
guides:
  acme:
    label: Acme owner's manual (2027)
    source: https://example.com/acme
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
      - { target: lsc, value: 4 }
nodes:
  - label: Guided
    level: model
    guide: acme
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
      - { name: LSC, type: step, max: 10 }
''';

final _preset = catalogProducts(parseCatalogFile(_catalog)).single;

/// The guided fork. [pressureMax] narrows the pressure adjuster, so that the
/// guide's value lies beyond it.
GuidedComponent _guided({String name = 'myFork', double? pressureMax}) {
  final application = buildCatalogApplication(_preset, englishL10n);
  return GuidedComponent(
    Component(
      name: name,
      componentType: application.componentType,
      installations: const [],
      adjustments: [
        for (final adjustment in application.adjustments)
          if (pressureMax != null && adjustment is NumericalAdjustment && adjustment.name == 'Pressure')
            adjustment.copyWith(max: pressureMax)
          else
            adjustment,
      ],
      preset: application.preset,
    ),
    _preset,
  );
}

class _Case {
  final String label;
  final GuidedComponent guided;
  final GuideInputs inputs;

  /// What is set now, by adjuster name.
  final Map<String, num> current;
  final bool expanded;

  /// No riding weight on the rider: the card asks for one.
  final bool askForWeight;
  final double width;
  final double textScale;

  _Case(
    this.label, {
    GuidedComponent? guided,
    this.inputs = const GuideInputs(riderWeight: 82),
    this.current = const {},
    this.expanded = true,
    this.askForWeight = false,
    this.width = _cellWidth,
    this.textScale = 1,
  }) : guided = guided ?? _guided();

  Map<String, AdjustmentValue> get values => {
    for (final adjustment in guided.component.adjustments)
      if (current[adjustment.name] case final number?)
        adjustment.id: adjustment is StepAdjustment ? StepValue(number.toInt()) : NumericalValue(number.toDouble()),
  };

  List<GuideRecommendation> get recommendations => guided.evaluate(inputs, values, englishL10n);

  bool get canApplyAny => recommendations.any((r) => r.value != null && r.current != r.value);

  Widget card({
    void Function(GuideRecommendation)? onApply,
    VoidCallback? onApplyAll,
    ValueChanged<double?>? onWeight,
  }) {
    return SetupGuideCard(
      sections: [SetupGuideSection(guided, recommendations)],
      inputs: inputs,
      onApply: onApply ?? (_) {},
      onApplyAll: canApplyAny ? (onApplyAll ?? () {}) : null,
      initiallyExpanded: expanded,
      weightInput: askForWeight
          ? GuideWeightInput(
              weight: null,
              unit: const GuideInputs().riderWeightUnit,
              onChanged: onWeight ?? (_) {},
              hint: 'Saved with this setup as myRider\'s riding weight',
              onAddToRider: () {},
              addToRiderLabel: 'Add riding weight to myRider',
            )
          : null,
    );
  }
}

final _cases = [
  _Case('Nothing set yet'),
  _Case('Matches the guide', current: {'Pressure': 77, 'LSC': 4}),
  _Case('In range of the guide', current: {'Pressure': 80, 'LSC': 4}),
  _Case('Off: small step down, large step up', current: {'Pressure': 90, 'LSC': 0}),
  _Case('Off: large step down, small step up', current: {'Pressure': 110, 'LSC': 3}),
  _Case("Can't apply: guide beyond the adjuster's maximum", guided: _guided(pressureMax: 70)),
  _Case('Outside the published weights (130 kg)', inputs: const GuideInputs(riderWeight: 130)),
  _Case('No riding weight yet', inputs: const GuideInputs(), current: {'Pressure': 80}, askForWeight: true),
  _Case('Collapsed, everything matches', current: {'Pressure': 77, 'LSC': 4}, expanded: false),
  _Case('Collapsed, a value differs', current: {'Pressure': 90, 'LSC': 4}, expanded: false),
  _Case(
    'Narrow screen, long name, text scale 1.5',
    guided: _guided(name: 'myForkWithAVeryLongNameThatWillNeverFitOnOneLine'),
    current: {'Pressure': 90, 'LSC': 0},
    width: 320,
    textScale: 1.5,
  ),
];

const _galleryKey = ValueKey('card-gallery');

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('setup_guide_card'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      tester.view.physicalSize = const Size(2 * _cellWidth + 80, 5000);
      await tester.pumpWidget(_galleryApp(theme));
      await tester.pumpAndSettle();
      await session.add('cards', 'Card states', tester.renderObject(find.byKey(_galleryKey)));

      tester.view.physicalSize = const Size(_sheetWidth, 1800);
      await tester.pumpWidget(_sheetApp(theme));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Learn more'));
      await tester.pumpAndSettle();
      await session.add(
        'sheet',
        'Info sheet',
        tester.renderObject(find.byKey(const ValueKey('sheet'))),
        crop: tester.getRect(find.byType(BottomSheet)),
      );

      await session.finish();
    });
  }

  testWidgets('every row can be applied or says why it cannot', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_sheetWidth, 3000);

    for (final (index, c) in _cases.indexed) {
      final applied = <GuideRecommendation>[];
      var applyAllCalls = 0;
      double? enteredWeight;
      await tester.pumpWidget(
        _app(
          galleryThemes.first.$2,
          SingleChildScrollView(
            child: c.card(
              onApply: applied.add,
              onApplyAll: () => applyAllCalls++,
              onWeight: (weight) => enteredWeight = weight,
            ),
          ),
          key: ValueKey(index),
        ),
      );
      await tester.pumpAndSettle();
      if (!c.expanded) {
        await tester.tap(find.text('SETUP GUIDE'));
        await tester.pumpAndSettle();
      }

      for (final r in c.recommendations) {
        final name = find.text(r.adjustment.name);
        if (r.value == null) {
          expect(r.issue, isNotNull, reason: '"${c.label}": ${r.adjustment.name} has no value and no reason');
          expect(
            find.text(guideDetailText(r, c.guided.component, englishL10n)),
            findsWidgets,
            reason: '"${c.label}": ${r.adjustment.name} does not say why it has no value',
          );
        } else if (r.current != r.value) {
          await tester.tap(name);
          expect(applied.last.adjustment, r.adjustment, reason: '"${c.label}": ${r.adjustment.name} cannot be applied');
          expect(applied.last.value, r.value, reason: c.label);
        }
      }

      final applyAll = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text('Apply all'), matching: find.bySubtype<ButtonStyleButton>()),
      );
      expect(applyAll.onPressed != null, c.canApplyAny, reason: '"${c.label}": Apply all is on when nothing applies');
      if (c.canApplyAny) {
        await tester.tap(find.text('Apply all'));
        expect(applyAllCalls, 1, reason: c.label);
      }

      if (c.askForWeight) {
        await tester.enterText(find.byType(TextField), '82');
        expect(enteredWeight, 82, reason: '"${c.label}": the riding weight cannot be entered on the card');
      }
    }
  });
}

Widget _app(ThemeData theme, Widget home, {Key? key}) => RepaintBoundary(
  key: key,
  child: localizedTestApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(body: home),
  ),
);

Widget _galleryApp(ThemeData theme) {
  return _app(
    theme,
    Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _galleryKey,
        child: ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final c in _cases)
                  SizedBox(
                    width: c.width,
                    child: MediaQuery(
                      data: MediaQueryData(textScaler: TextScaler.linear(c.textScale)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(c.label, style: theme.textTheme.labelSmall),
                          ),
                          c.card(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _sheetApp(ThemeData theme) => _app(
  theme,
  Padding(
    padding: const EdgeInsets.all(16),
    child: Align(alignment: Alignment.topCenter, child: _cases.first.card()),
  ),
  key: const ValueKey('sheet'),
);
