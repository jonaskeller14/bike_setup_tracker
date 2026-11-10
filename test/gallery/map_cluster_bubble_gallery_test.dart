// Renders every state of MapClusterBubble to PNGs in
// build/gallery/map_cluster_bubble/ (git-ignored), for a quick visual check
// after changing the bubble. Skipped by default (see dart_test.yaml); run it
// on demand with:
//
//   flutter test test/gallery/map_cluster_bubble_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page: the
// states at their real 40 px on a map-coloured background, then the same
// states magnified 3x (painted at 40 px, then scaled) to judge ring and gaps.
//
// The bubble shows no user data; every number on it is a pin count.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/widgets/map/map_cluster_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _bubbleSize = 40.0;
const _zoom = 3.0;

/// Roughly the land colour of the light and dark map tiles.
const _mapLight = Color(0xFFE9E5DC);
const _mapDark = Color(0xFF2C2F33);

class _Case {
  final String label;
  final Map<MapPinKind, int> counts;
  final double textScale;

  const _Case(this.label, this.counts, {this.textScale = 1});
}

const _setup = MapPinKind.setup;
const _activity = MapPinKind.activity;
const _feedback = MapPinKind.feedback;

const _cases = [
  _Case('Setups only', {_setup: 12}),
  _Case('Activities only', {_activity: 12}),
  _Case('Feedback only', {_feedback: 12}),
  _Case('Setups + activities, 1:1', {_setup: 6, _activity: 6}),
  _Case('Setups + feedback, 2:1', {_setup: 8, _feedback: 4}),
  _Case('Activities + feedback, 3:1', {_activity: 9, _feedback: 3}),
  _Case('All three, equal', {_setup: 4, _activity: 4, _feedback: 4}),
  _Case('All three, 8:3:1', {_setup: 8, _activity: 3, _feedback: 1}),
  _Case('Tiny share, 79:1 (lifted to 20°)', {_setup: 79, _feedback: 1}),
  _Case('Re-clamp, 376:23:1', {_activity: 376, _setup: 23, _feedback: 1}),
  _Case('Smallest cluster, 2', {_setup: 1, _activity: 1}),
  _Case('Count 99', {_activity: 99}),
  _Case('Count 999', {_activity: 900, _setup: 99}),
  _Case('Count 1234', {_activity: 1200, _setup: 30, _feedback: 4}),
  _Case('Large text (2x)', {_setup: 8, _activity: 4}, textScale: 2),
  _Case('Large text (2x), count 999', {_activity: 999}, textScale: 2),
  _Case('A kind with count 0 (no segment)', {_setup: 5, _activity: 0}),
  _Case('No counts (unreachable)', {}),
];

const _realKey = ValueKey('real-size');
const _zoomKey = ValueKey('zoomed');

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('map_cluster_bubble'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 2400);
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);
      final map = name == 'dark' ? _mapDark : _mapLight;

      await tester.pumpWidget(
        localizedTestApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _grid(_realKey, theme, map, textColor, scale: 1, cellWidth: 120),
                  _grid(_zoomKey, theme, map, textColor, scale: _zoom, cellWidth: 160),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await session.add('real_size', 'Real size (40 px) on the map', tester.renderObject(find.byKey(_realKey)));
      await session.add('zoomed', 'Magnified 3x', tester.renderObject(find.byKey(_zoomKey)));
      await session.finish();
    });
  }
}

Widget _grid(
  Key key,
  ThemeData theme,
  Color map,
  Color labelColor, {
  required double scale,
  required double cellWidth,
}) {
  final side = _bubbleSize * scale;
  return RepaintBoundary(
    key: key,
    child: ColoredBox(
      color: map,
      child: SizedBox(
        width: 6 * cellWidth + 33,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 16,
            children: [
              for (final c in _cases)
                SizedBox(
                  width: cellWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Text(
                          c.label,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox.square(
                        dimension: side,
                        child: FittedBox(
                          child: SizedBox.square(
                            dimension: _bubbleSize,
                            child: MediaQuery.withClampedTextScaling(
                              minScaleFactor: c.textScale,
                              maxScaleFactor: c.textScale,
                              child: MapClusterBubble(counts: c.counts),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
