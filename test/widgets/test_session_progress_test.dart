import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/test_session_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';

const _width = 328.0;
const _gap = TestSessionProgress.gap;

double _segmentWidth(int count, [double width = _width]) => (width - _gap * (count - 1)) / count;

void main() {
  /// Milliseconds pumped since the bar was shown.
  var elapsed = 0;

  /// Shows [progress]; set the returned notifier to change it.
  Future<ValueNotifier<SessionProgress>> pump(
    WidgetTester tester,
    SessionProgress progress, {
    double width = _width,
    double textScale = 1,
    bool reduceMotion = false,
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    final shown = ValueNotifier(progress);
    addTearDown(shown.dispose);
    elapsed = 0;
    await tester.pumpWidget(
      localizedTestApp(
        key: UniqueKey(),
        locale: locale,
        theme: theme ?? materialAppTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: ValueListenableBuilder(
                valueListenable: shown,
                builder: (context, value, _) => TestSessionProgress(progress: value),
              ),
            ),
          ),
        ),
      ),
    );
    return shown;
  }

  /// The first pumps start the clocks of the animations begun in the build.
  Future<void> advance(WidgetTester tester, int milliseconds) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(Duration(milliseconds: milliseconds));
    elapsed += milliseconds;
  }

  /// Past a change (750 ms), at the next still point of the pulse (every 1800 ms).
  Future<void> rest(WidgetTester tester) {
    final toStill = 1800 - elapsed % 1800;
    return advance(tester, toStill < 800 ? toStill + 1800 : toStill);
  }

  /// Also while a page covers it.
  Finder bar() => find.descendant(
    of: find.byType(TestSessionProgress, skipOffstage: false),
    matching: find.byType(CustomPaint, skipOffstage: false),
    skipOffstage: false,
  );

  /// What the bar draws right now.
  List<RecordedInvocation> painted(WidgetTester tester) {
    final box = tester.renderObject<RenderCustomPaint>(bar());
    final canvas = TestRecordingCanvas();
    box.painter!.paint(canvas, box.size);
    return canvas.invocations.toList();
  }

  List<(T, Paint)> drawn<T>(WidgetTester tester, Symbol method) => [
    for (final call in painted(tester))
      if (call.invocation.memberName == method)
        (call.invocation.positionalArguments[0] as T, call.invocation.positionalArguments[1] as Paint),
  ];

  List<(RRect, Paint)> segments(WidgetTester tester) => drawn<RRect>(tester, #drawRRect);
  List<(Rect, Paint)> rects(WidgetTester tester) => drawn<Rect>(tester, #drawRect);

  bool isGlow(Paint paint) => paint.maskFilter != null;

  // A Paint keeps its colour in single precision.
  bool isFill(Paint paint) {
    final fill = materialAppTheme.colorScheme.primary;
    return !isGlow(paint) &&
        [paint.color.r - fill.r, paint.color.g - fill.g, paint.color.b - fill.b].every((d) => d.abs() < 0.001);
  }

  group('TestSessionProgress', () {
    const cases = <(SessionProgress, String)>[
      (SessionProgress.exact(ridden: 5, left: 2), '2 more runs'),
      (SessionProgress.exact(ridden: 5, left: 1), '1 more run'),
      (SessionProgress(ridden: 3, left: 3, maxLeft: 4), '3–4 more runs'),
      (SessionProgress(ridden: 4, pending: true, left: 0, maxLeft: 2), 'Up to 2 more runs'),
      (SessionProgress(ridden: 4, pending: true, left: 0, maxLeft: 1), 'Up to 1 more run'),
      (SessionProgress(ridden: 1, left: 7, maxLeft: null), 'About 7 more runs'),
      (SessionProgress(ridden: 7, pending: true, left: 1, maxLeft: null), 'About 1 more run'),
      (SessionProgress.exact(ridden: 6, left: 1, confirming: true), 'Last run: confirm the best'),
      (
        SessionProgress(ridden: 7, pending: true, left: 0, maxLeft: 0, confirming: true),
        'Last run: confirm the best',
      ),
      (SessionProgress(ridden: 6, pending: true, left: 0, maxLeft: 0), 'Last run'),
      (SessionProgress(ridden: 6, pending: true, left: 0, maxLeft: null), 'Last run'),
      (SessionProgress.exact(ridden: 7, left: 0), 'Done — end the session'),
    ];

    for (final (progress, label) in cases) {
      testWidgets('$progress reads "$label"', (tester) async {
        await pump(tester, progress);

        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('announces the runs ridden and what is left as one label', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const SessionProgress(ridden: 4, pending: true, left: 3, maxLeft: null));

      expect(find.bySemanticsLabel('4 runs, About 3 more runs'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('draws one segment per run across the full width', (tester) async {
      for (final progress in const [
        SessionProgress.exact(ridden: 1, left: 2),
        SessionProgress(ridden: 3, left: 2, maxLeft: 4),
        SessionProgress(ridden: 2, left: 7, maxLeft: null),
      ]) {
        await pump(tester, progress);
        await rest(tester);

        final planned = progress.ridden + progress.left;
        final count = (progress.maxLeft == null ? planned + 3 : progress.ridden + progress.maxLeft!);
        final shapes = segments(tester);
        expect(shapes.length, planned, reason: '$progress');
        expect(shapes.where((s) => isFill(s.$2)).length, progress.ridden, reason: '$progress');
        expect(shapes.first.$1.left, 0, reason: '$progress');
        for (final (segment, _) in shapes) {
          expect(segment.width, closeTo(_segmentWidth(count), 0.001), reason: '$progress');
        }
        // Possible runs and the open tail are dashed, up to the end of the bar.
        final dashes = drawn<Path>(tester, #drawPath);
        expect(dashes.length, count - planned, reason: '$progress');
        if (dashes.isNotEmpty) {
          expect(dashes.last.$1.getBounds().right, closeTo(_width, 1), reason: '$progress');
        } else {
          expect(shapes.last.$1.right, closeTo(_width, 0.001), reason: '$progress');
        }
      }
    });

    testWidgets('fills half of the run that waits for its feedback', (tester) async {
      await pump(tester, const SessionProgress(ridden: 3, pending: true, left: 2, maxLeft: 2));
      await rest(tester);

      expect(segments(tester).where((s) => isFill(s.$2)).length, 2);
      final half = rects(tester).single;
      expect(isFill(half.$2), isTrue);
      expect(half.$1.width, closeTo(_segmentWidth(5) / 2, 0.001));
      expect(half.$1.left, closeTo(2 * (_segmentWidth(5) + _gap), 0.001));
    });

    testWidgets('falls back to one bar where the segments get too thin', (tester) async {
      // 10 ridden + 12 left + 3 fading: 25 segments.
      const progress = SessionProgress(ridden: 10, left: 12, maxLeft: null);
      const fits = 25 * TestSessionProgress.minSegmentWidth + 24 * TestSessionProgress.gap;
      expect(TestSessionProgress.fitsSegments(fits, 25), isTrue);
      expect(TestSessionProgress.fitsSegments(fits - 1, 25), isFalse);

      await pump(tester, progress, width: fits);
      await rest(tester);
      expect(segments(tester).length, 22);

      await pump(tester, progress, width: fits - 1);
      await rest(tester);
      expect(segments(tester), isEmpty);
      // The track and the fill.
      final bars = rects(tester);
      expect(bars.length, 2);
      expect(bars[1].$1.width, closeTo((fits - 1) * 10 / 22, 0.001));
      expect(find.text('About 12 more runs'), findsOneWidget);
    });

    group('on first show', () {
      testWidgets('the fill wipes in while the label is already there', (tester) async {
        await pump(tester, const SessionProgress.exact(ridden: 3, left: 2));
        await tester.pump();

        expect(find.text('2 more runs'), findsOneWidget);
        expect(segments(tester).length, 5);
        expect(segments(tester).where((s) => isFill(s.$2)), isEmpty);

        // Left to right: the first run is full while the second fills.
        await advance(tester, 300);
        expect(segments(tester).where((s) => isFill(s.$2)).length, 1);
        expect(rects(tester).single.$1.left, closeTo(_segmentWidth(5) + _gap, 0.001));

        await rest(tester);
        expect(segments(tester).where((s) => isFill(s.$2)).length, 3);
      });

      testWidgets('a finished session is filled to the end and then holds still', (tester) async {
        await pump(tester, const SessionProgress.exact(ridden: 7, left: 0));
        await tester.pumpAndSettle();

        expect(segments(tester).length, 7);
        expect(segments(tester).every((s) => isFill(s.$2)), isTrue);
        expect(drawn<Path>(tester, #drawPath), isEmpty);
        expect(rects(tester), isEmpty, reason: 'no finish flourish for a session that was done already');
      });
    });

    group('a change', () {
      testWidgets('feedback fills up the run that waited', (tester) async {
        final shown = await pump(tester, const SessionProgress(ridden: 3, pending: true, left: 2, maxLeft: 2));
        await rest(tester);

        shown.value = const SessionProgress.exact(ridden: 3, left: 2);
        await advance(tester, 375);
        final growing = rects(tester).single.$1.width;
        expect(growing, greaterThan(_segmentWidth(5) / 2));
        expect(growing, lessThan(_segmentWidth(5)));

        await rest(tester);
        expect(rects(tester), isEmpty);
        expect(segments(tester).where((s) => isFill(s.$2)).length, 3);
      });

      testWidgets('the label changes with the bar', (tester) async {
        final shown = await pump(tester, const SessionProgress(ridden: 1, left: 7, maxLeft: null));
        await rest(tester);

        shown.value = const SessionProgress(ridden: 2, pending: true, left: 6, maxLeft: null);
        await rest(tester);

        expect(find.text('About 6 more runs'), findsOneWidget);
        expect(find.text('About 7 more runs'), findsNothing);
      });

      testWidgets('more runs make every segment narrower, the new ones slide in', (tester) async {
        // A better run in Fine-tune: 9 segments become 12.
        final shown = await pump(tester, const SessionProgress(ridden: 2, left: 4, maxLeft: null));
        await rest(tester);
        expect(segments(tester).first.$1.width, closeTo(_segmentWidth(9), 0.001));

        shown.value = const SessionProgress(ridden: 3, left: 6, maxLeft: null);
        await advance(tester, 375);
        final between = segments(tester);
        expect(between.first.$1.width, greaterThan(_segmentWidth(12)));
        expect(between.first.$1.width, lessThan(_segmentWidth(9)));
        // The 7th to 9th run turn from dashed to planned.
        expect(between.where((s) => !isFill(s.$2) && s.$2.color.a < 1), isNotEmpty);

        await rest(tester);
        expect(segments(tester).length, 9);
        expect(segments(tester).first.$1.width, closeTo(_segmentWidth(12), 0.001));
      });

      testWidgets('fewer runs make every segment wider', (tester) async {
        final shown = await pump(tester, const SessionProgress(ridden: 3, left: 3, maxLeft: 4));
        await rest(tester);

        // The estimated best was ridden already: 7 segments become 5.
        shown.value = const SessionProgress.exact(ridden: 4, left: 1, confirming: true);
        await rest(tester);

        expect(segments(tester).length, 5);
        expect(segments(tester).last.$1.right, closeTo(_width, 0.001));
        expect(drawn<Path>(tester, #drawPath), isEmpty);
      });

      testWidgets('segments and the single bar cross-fade', (tester) async {
        // 25 segments fit into 328 px, 27 don't.
        final shown = await pump(tester, const SessionProgress(ridden: 10, left: 12, maxLeft: null));
        await rest(tester);
        expect(segments(tester), isNotEmpty);

        shown.value = const SessionProgress(ridden: 11, left: 13, maxLeft: null);
        await advance(tester, 375);
        expect(segments(tester), isNotEmpty);
        expect(rects(tester).where((r) => r.$1.width == _width), isNotEmpty);

        await rest(tester);
        expect(segments(tester), isEmpty);
        expect(rects(tester).length, 2);
      });

      testWidgets('one that comes in meanwhile plays after the first', (tester) async {
        final shown = await pump(tester, const SessionProgress(ridden: 1, left: 7, maxLeft: null));
        await rest(tester);

        shown.value = const SessionProgress(ridden: 2, pending: true, left: 6, maxLeft: null);
        await advance(tester, 300);
        shown.value = const SessionProgress(ridden: 2, left: 6, maxLeft: null);
        await tester.pump();
        // Still on its way to the half-filled second run.
        expect(rects(tester).single.$1.width, lessThanOrEqualTo(_segmentWidth(11) / 2));

        await advance(tester, 700);
        await rest(tester);
        expect(rects(tester), isEmpty);
        expect(segments(tester).where((s) => isFill(s.$2)).length, 2);
      });

      testWidgets('waits until the page on top has left', (tester) async {
        final shown = await pump(tester, const SessionProgress(ridden: 1, pending: true, left: 2, maxLeft: 2));
        await rest(tester);
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));

        navigator.push(MaterialPageRoute<void>(builder: (context) => const Scaffold(body: Text('feedback'))));
        await advance(tester, 500);
        shown.value = const SessionProgress.exact(ridden: 1, left: 2);
        await advance(tester, 1000);
        // Covered: nothing played.
        expect(rects(tester).single.$1.width, closeTo(_segmentWidth(3) / 2, 0.001));

        navigator.pop();
        await advance(tester, 300);
        // The page is still sliding away.
        expect(rects(tester).single.$1.width, closeTo(_segmentWidth(3) / 2, 0.001));

        await advance(tester, 100);
        await advance(tester, 375);
        expect(rects(tester).single.$1.width, greaterThan(_segmentWidth(3) / 2));

        await rest(tester);
        expect(rects(tester), isEmpty);
        expect(segments(tester).where((s) => isFill(s.$2)).length, 1);
      });
    });

    group('while the session runs', () {
      testWidgets('the latest run breathes with a glow', (tester) async {
        await pump(tester, const SessionProgress.exact(ridden: 3, left: 2));
        await rest(tester);
        expect(segments(tester).where((s) => isGlow(s.$2)), isEmpty);
        expect(tester.hasRunningAnimations, isTrue);

        // The low point of the breath, 900 ms after the still point.
        await advance(tester, 900);
        final shapes = segments(tester);
        final glow = shapes.where((s) => isGlow(s.$2)).single;
        expect(glow.$1.left, closeTo(2 * (_segmentWidth(5) + _gap), 0.001));
        final filled = shapes.where((s) => isFill(s.$2)).toList();
        expect(filled.map((s) => s.$2.color.a < 1), [false, false, true]);
      });

      testWidgets('the end of the single bar breathes', (tester) async {
        await pump(tester, const SessionProgress(ridden: 14, left: 19, maxLeft: null));
        await rest(tester);
        await advance(tester, 900);

        // The glow at the end of the fill, the track, and the fill fading out.
        final bars = rects(tester);
        expect(bars.length, 3);
        expect(isGlow(bars.first.$2), isTrue);
        expect(bars.first.$1.width, closeTo(12, 0.001));
        expect(bars.first.$1.right, closeTo(_width * 14 / 33, 0.001));
        expect(bars.last.$2.shader, isNotNull);
        expect(bars.last.$1.width, closeTo(_width * 14 / 33, 0.001));
      });

      testWidgets('reaching the result sweeps a light over the bar once, then all is still', (tester) async {
        final shown = await pump(
          tester,
          const SessionProgress(ridden: 7, pending: true, left: 0, maxLeft: 0, confirming: true),
        );
        await rest(tester);

        shown.value = const SessionProgress.exact(ridden: 7, left: 0);
        await advance(tester, 760);
        await advance(tester, 350);
        expect(rects(tester).where((r) => r.$2.shader != null).length, 1);

        await tester.pumpAndSettle();
        expect(rects(tester), isEmpty);
        expect(segments(tester).length, 7);
        expect(segments(tester).every((s) => isFill(s.$2) && s.$2.color.a == 1), isTrue);
      });
    });

    testWidgets('with reduced motion everything is in place at once and holds still', (tester) async {
      final shown = await pump(
        tester,
        const SessionProgress(ridden: 3, pending: true, left: 2, maxLeft: 2),
        reduceMotion: true,
      );
      await tester.pumpAndSettle();
      expect(segments(tester).where((s) => isFill(s.$2)).length, 2);
      expect(rects(tester).single.$1.width, closeTo(_segmentWidth(5) / 2, 0.001));

      shown.value = const SessionProgress.exact(ridden: 5, left: 0);
      await tester.pump();
      expect(find.text('Done — end the session'), findsOneWidget);
      expect(segments(tester).where((s) => isFill(s.$2)).length, 5);
      expect(rects(tester), isEmpty);
      expect(tester.hasRunningAnimations, isFalse);
    });

    for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('fits a narrow screen with large text in every language ($name)', (tester) async {
        for (final locale in AppLocalizations.supportedLocales) {
          for (final (progress, _) in cases) {
            await pump(tester, progress, width: 288, textScale: 2, locale: locale, theme: theme);
            await rest(tester);

            expect(tester.takeException(), isNull, reason: '$progress in ${locale.languageCode}');
          }
        }
      });
    }
  });
}
