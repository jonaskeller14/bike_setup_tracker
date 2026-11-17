// Renders every state of the catalog update notice on PresetCatalogCard and of
// the merge sheet that "Apply" opens to PNGs in build/gallery/catalog_update/
// (git-ignored), for a quick visual check after changing either widget. Skipped
// by default (see dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/catalog_update_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; the
// card gallery and each sheet are also written on their own.
//
// The scenario is the real data/component_presets/fork/rockshox.yaml: revision 2
// adds the compression adjuster to forks with the Motion Control RC damper, as a
// `review:` change. A saved Yari RC at revision 1 therefore gets the notice.
//
// Names that start with "my" are user data (component and adjustment names the
// rider typed). Anything else on screen (Pressure, Rebound, Update available,
// badges, hints) comes from the catalog or the UI.
//
// Besides the pictures, the second test checks that no state traps the rider:
// every notice can be dismissed, and Review can always be confirmed with the new
// adjuster included and none of the rider's adjustments lost.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/catalog_revisions.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/preset_merge.dart';
import 'package:bike_setup_tracker/widgets/preset_catalog_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/preset_merge_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _cellWidth = 360.0;
const _sheetWidth = 400.0;
const _compressionKey = 'fork:compression';
const _motionControlRc = 'motion_control_rc';

final _yaml = File('data/component_presets/fork/rockshox.yaml').readAsStringSync();
final _catalog = parseCatalogFile(_yaml);
final _catalogDe = parseCatalogFile(_yaml, languageCode: 'de');

/// The first product of [model] whose damper is [damper].
ResolvedPreset _fork(BrandCatalog catalog, String model, String damper) => catalogProducts(catalog).firstWhere(
  (product) =>
      product.path.any((node) => node.label == model) && product.selections[PresetOptionAxes.damper.id]?.id == damper,
);

final _rc = _fork(_catalog, 'Yari', _motionControlRc);
final _rcDe = _fork(_catalogDe, 'Yari', _motionControlRc);
final _otherDamper = _fork(_catalog, 'Reba', 'motion_control_rl');

/// What the rider saved at revision 1: the product's adjusters, without the
/// compression one that revision 2 adds.
List<Adjustment> _savedAdjustments() => [
  for (final adjustment in buildCatalogApplication(_rc, englishL10n).adjustments)
    if (adjustment.presetKey != _compressionKey) adjustment,
];

Map<String, List<AdjustmentValue>> _recordedFor(List<Adjustment> adjustments) => {
  for (final adjustment in adjustments)
    if (adjustment.presetKey == 'fork:rebound')
      adjustment.id: [const StepValue(8)]
    else if (adjustment.presetKey == 'fork:pressure')
      adjustment.id: [const NumericalValue(65)],
};

/// What the rider has on the component when they tap Review.
class _Scene {
  final List<Adjustment> existing;
  final Map<String, List<AdjustmentValue>> recorded;

  const _Scene(this.existing, this.recorded);

  factory _Scene.untouched() {
    final existing = _savedAdjustments();
    return _Scene(existing, _recordedFor(existing));
  }
}

class _CardCase {
  final String label;
  final ResolvedPreset? applied;
  final bool unresolved;
  final List<CatalogReview> updates;

  /// The notice must show, with working buttons.
  final bool expectNotice;
  final double width;
  final double textScale;
  final Locale? locale;

  const _CardCase(
    this.label, {
    required this.applied,
    this.unresolved = false,
    this.updates = const [],
    required this.expectNotice,
    this.width = _cellWidth,
    this.textScale = 1,
    this.locale,
  });
}

final _realUpdates = pendingCatalogReviews(_rc, 1);

final _cardCases = [
  _CardCase('Yari RC at revision 1: the real update', applied: _rc, updates: _realUpdates, expectNotice: true),
  _CardCase(
    'Yari RC at revision 2: up to date, no notice',
    applied: _rc,
    updates: pendingCatalogReviews(_rc, 2),
    expectNotice: false,
  ),
  _CardCase(
    'Reba RL (other damper) at revision 1: the change does not match, no notice',
    applied: _otherDamper,
    updates: pendingCatalogReviews(_otherDamper, 1),
    expectNotice: false,
  ),
  _CardCase(
    'Two updates pending (invented second change)',
    applied: _rc,
    updates: [
      ..._realUpdates,
      const CatalogReview(revision: 3, summary: 'Widens the rebound range to 16 clicks.'),
    ],
    expectNotice: true,
  ),
  _CardCase(
    'Long update text (shown in full)',
    applied: _rc,
    updates: const [
      CatalogReview(
        revision: 2,
        summary:
            'Adds the compression adjuster and corrects the rebound range of the Motion Control RC damper, '
            'which counts from fully open on the 2016-2023 Yari, Revelation and Domain. Check the click '
            'counts you recorded against the new ranges before you confirm the merge in the next step.',
      ),
    ],
    expectNotice: true,
  ),
  _CardCase(
    'German',
    applied: _rcDe,
    updates: pendingCatalogReviews(_rcDe, 1),
    expectNotice: true,
    locale: const Locale('de'),
  ),
  _CardCase(
    'Narrow (260) and text scale 2',
    applied: _rc,
    updates: _realUpdates,
    expectNotice: true,
    width: 260,
    textScale: 2,
  ),
  _CardCase(
    'Product no longer in the catalog: update hidden',
    applied: null,
    unresolved: true,
    updates: _realUpdates,
    expectNotice: false,
  ),
];

class _SheetCase {
  final String slug;
  final String title;
  final _Scene Function() scene;
  final double width;
  final double textScale;

  /// Taps that bring the sheet into the state to capture.
  final Future<void> Function(WidgetTester tester)? then;

  const _SheetCase({
    required this.slug,
    required this.title,
    required this.scene,
    this.width = _sheetWidth,
    this.textScale = 1,
    this.then,
  });
}

Future<void> _choose(WidgetTester tester, String badge, String choice) async {
  await tester.tap(find.text(badge).first);
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(MenuItemButton), matching: find.textContaining(choice)));
  await tester.pumpAndSettle();
}

/// The rider renamed Pressure and wrote their own compression adjuster, whose
/// name the catalog cannot match.
_Scene _ownCompression() {
  final existing = [
    for (final adjustment in _savedAdjustments())
      if (adjustment.presetKey == 'fork:pressure') adjustment.copyWith(name: 'myAirPressure') else adjustment,
    StepAdjustment(
      id: 'my-compression',
      name: 'myCompression',
      notes: null,
      unit: null,
      step: 1,
      min: 0,
      max: 10,
      visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
    ),
  ];
  return _Scene(existing, _recordedFor(existing));
}

final _sheetCases = [
  const _SheetCase(slug: 'untouched', title: 'Untouched component · compression is new', scene: _Scene.untouched),
  _SheetCase(
    slug: 'replace',
    title: 'Replace mode · warns about the recorded values',
    scene: _Scene.untouched,
    then: (tester) async {
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();
    },
  ),
  const _SheetCase(
    slug: 'own-compression',
    title: 'Rider wrote "myCompression" · not matched, offered as new',
    scene: _ownCompression,
  ),
  _SheetCase(
    slug: 'own-compression-merged',
    title: 'Rider wrote "myCompression" · merged into theirs via the badge',
    scene: _ownCompression,
    then: (tester) => _choose(tester, 'New', 'Merge into'),
  ),
  _SheetCase(
    slug: 'dont-add',
    title: 'Compression set to "Don\'t add"',
    scene: _Scene.untouched,
    then: (tester) => _choose(tester, 'New', "Don't add"),
  ),
  _SheetCase(
    slug: 'only-sag-left',
    title: 'Rider deleted everything but SAG · every adjuster is new',
    scene: () {
      final existing = _savedAdjustments().whereType<SagAdjustment>().toList();
      return _Scene(existing, const {});
    },
  ),
  const _SheetCase(
    slug: 'narrow-large-text',
    title: 'Narrow (320) and text scale 1.5',
    scene: _Scene.untouched,
    width: 320,
    textScale: 1.5,
  ),
];

const _galleryKey = ValueKey('card-gallery');

// The card's own Apply button is a FilledButton too, so the sheet's is told apart by its parent.
final _sheetConfirm = find.descendant(of: find.byType(BottomSheet), matching: find.byType(FilledButton));

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('catalog_update'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      tester.view.physicalSize = const Size(2 * _cellWidth + 80, 3000);
      await tester.pumpWidget(_cardGalleryApp(theme));
      await tester.pumpAndSettle();
      await session.add('cards', 'Card states', tester.renderObject(find.byKey(_galleryKey)));

      for (final (index, sheetCase) in _sheetCases.indexed) {
        tester.view.physicalSize = Size(sheetCase.width, 3600);
        await tester.pumpWidget(
          _reviewApp(theme, sheetCase.scene(), ValueKey(index), textScale: sheetCase.textScale, width: sheetCase.width),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        await sheetCase.then?.call(tester);
        await session.add(
          'sheet_${sheetCase.slug}',
          'Sheet · ${sheetCase.title}',
          tester.renderObject(find.byKey(ValueKey(index))),
          crop: tester.getRect(find.byType(BottomSheet)),
        );
      }

      await session.finish();
    });
  }

  testWidgets('every notice can be dismissed and every notice shows exactly when expected', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2 * _cellWidth + 80, 3000);

    for (final (index, c) in _cardCases.indexed) {
      var dismissed = 0;
      var reviewed = 0;
      await tester.pumpWidget(
        _app(
          galleryThemes.first.$2,
          Align(
            alignment: Alignment.topLeft,
            child: _CardCell(
              c,
              onReview: () => reviewed++,
              onDismiss: () => dismissed++,
            ),
          ),
          key: ValueKey(index),
        ),
      );
      await tester.pumpAndSettle();

      final shown = find.byType(FilledButton).evaluate().isNotEmpty;
      expect(shown, c.expectNotice, reason: '"${c.label}" shows the notice: $shown');
      if (!c.expectNotice) continue;

      await tester.tap(find.byType(TextButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(dismissed, 1, reason: '"${c.label}" cannot be dismissed');
      expect(reviewed, 1, reason: '"${c.label}" cannot be reviewed');
    }
  });

  testWidgets('every review can be confirmed with compression added and nothing of the rider lost', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    for (final (index, c) in _sheetCases.indexed) {
      // The states that start from a choice are checked separately below.
      if (c.then != null && c.slug != 'replace') continue;
      tester.view.physicalSize = Size(c.width, 3600);
      final scene = c.scene();
      PresetMergeResult? result;
      await tester.pumpWidget(
        _reviewApp(galleryThemes.first.$2, scene, ValueKey(index), width: c.width, onResult: (r) => result = r),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await c.then?.call(tester);
      await tester.tap(_sheetConfirm);
      await tester.pumpAndSettle();

      expect(result, isNotNull, reason: '"${c.title}" cannot be confirmed');
      expect(
        result!.adjustments.any((a) => a.presetKey == _compressionKey || a.name == 'myCompression'),
        isTrue,
        reason: '"${c.title}" does not end up with a compression adjuster',
      );
      if (c.slug != 'replace') {
        final kept = result!.adjustments.map((a) => a.id).toSet();
        for (final own in scene.existing) {
          expect(kept, contains(own.id), reason: '"${c.title}" loses "${own.name}"');
        }
      }
    }
  });

  testWidgets('a compression set to "Don\'t add" can be added again', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_sheetWidth, 3600);
    PresetMergeResult? result;
    await tester.pumpWidget(
      _reviewApp(galleryThemes.first.$2, _Scene.untouched(), const ValueKey('re-add'), onResult: (r) => result = r),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await _choose(tester, 'New', "Don't add");
    // The section header comes first, the badge last.
    await tester.tap(find.text('Not added').last);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(MenuItemButton), matching: find.text('Add as new')));
    await tester.pumpAndSettle();
    await tester.tap(_sheetConfirm);
    await tester.pumpAndSettle();

    expect(result?.adjustments.any((a) => a.presetKey == _compressionKey), isTrue);
  });
}

Widget _app(ThemeData theme, Widget home, {Key? key, double textScale = 1}) => RepaintBoundary(
  key: key,
  child: localizedTestApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: home),
  ),
);

/// One card as the component page draws it, in the language and size of [c].
class _CardCell extends StatelessWidget {
  final _CardCase c;
  final VoidCallback? onReview;
  final VoidCallback? onDismiss;

  const _CardCell(this.c, {this.onReview, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    Widget card = PresetCatalogCard(
      componentType: ComponentType.fork,
      onTap: () {},
      applied: c.applied,
      unresolved: c.unresolved,
      onUnlink: () {},
      updates: c.updates,
      onReviewUpdate: onReview ?? () {},
      onDismissUpdate: onDismiss ?? () {},
    );
    if (c.locale != null) card = Localizations.override(context: context, locale: c.locale, child: card);
    return SizedBox(
      width: c.width,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.textScale)),
        child: card,
      ),
    );
  }
}

Widget _cardGalleryApp(ThemeData theme) => _app(
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
              for (final c in _cardCases)
                SizedBox(
                  width: c.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(c.label, style: theme.textTheme.labelSmall),
                      ),
                      _CardCell(c),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);

/// The card with the real Review flow of the component page: the merge sheet
/// opens with the adjustments the rider has and the catalog's proposal.
Widget _reviewApp(
  ThemeData theme,
  _Scene scene,
  Key key, {
  double textScale = 1,
  double width = _sheetWidth,
  ValueChanged<PresetMergeResult?>? onResult,
}) => _app(
  theme,
  Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topCenter,
      child: Builder(
        builder: (context) => PresetCatalogCard(
          componentType: ComponentType.fork,
          onTap: () {},
          applied: _rc,
          onUnlink: () {},
          updates: _realUpdates,
          onDismissUpdate: () {},
          onReviewUpdate: () async {
            final app = buildCatalogApplication(_rc, context.l10n);
            final result = await showPresetMergeSheet(
              context,
              productName: app.name,
              existing: scene.existing,
              proposal: proposePresetMerge(scene.existing, app.adjustments),
              recordedValues: scene.recorded,
              unknownMaxKeys: app.unknownMaxKeys,
            );
            onResult?.call(result);
          },
        ),
      ),
    ),
  ),
  key: key,
  textScale: textScale,
);
