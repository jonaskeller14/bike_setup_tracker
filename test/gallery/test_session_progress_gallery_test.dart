// Renders every state of TestSessionProgress (the run bar of a running test
// session) to PNGs in build/gallery/test_session_progress/ (git-ignored), for
// a quick visual check after changing the widget. Skipped by default (see
// dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/test_session_progress_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; the
// bar states and the pinned area of the sheet are also written on their own.
//
// The states are the estimates the three strategies return (see
// SessionProgress); the labels under the bars come from the UI. "myRun…" is a
// run name the rider gave.
//
// The pinned area is shown as the sheet builds it (bar above
// TestSessionNextStep), and for a converged session also without the bar, to
// compare the two ways of ending a session.
//
// Besides the pictures, the second test checks that no state breaks: every
// state says how many runs are left, in every language, on a narrow screen
// with large text, without overflowing.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
import 'package:bike_setup_tracker/widgets/test_session_next_step.dart';
import 'package:bike_setup_tracker/widgets/test_session_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

class _MockAppRepository extends Mock implements AppRepository {}

/// The sheet is as wide as the phone and pads its pinned area by 16.
const _cellWidth = 360.0 - 32;
const _narrowWidth = 320.0 - 32;

class _Case {
  final String label;
  final SessionProgress progress;
  final double width;
  final double textScale;
  final Locale locale;

  const _Case(
    this.label,
    this.progress, {
    this.width = _cellWidth,
    this.textScale = 1,
    this.locale = const Locale('en'),
  });
}

const _cases = [
  _Case('Explore: run 1 waits for feedback', SessionProgress(ridden: 1, pending: true, left: 5, maxLeft: 6)),
  _Case('Explore: mid-pattern, estimated best open', SessionProgress(ridden: 3, left: 3, maxLeft: 4)),
  _Case('Explore: estimated best next (exact)', SessionProgress.exact(ridden: 5, left: 2)),
  _Case('Explore: one knob, run 2 waits (exact)', SessionProgress(ridden: 2, pending: true, left: 2, maxLeft: 2)),
  _Case('Confirmation next', SessionProgress.exact(ridden: 6, left: 1, confirming: true)),
  _Case(
    'Confirmation waits for feedback',
    SessionProgress(ridden: 7, pending: true, left: 0, maxLeft: 0, confirming: true),
  ),
  _Case('Done: the strategy has its result', SessionProgress.exact(ridden: 7, left: 0)),
  _Case('Compare: 3 setups, round robin + tie-break', SessionProgress(ridden: 1, left: 3, maxLeft: 5)),
  _Case('Compare: 2 setups', SessionProgress(ridden: 1, left: 1, maxLeft: 2)),
  _Case('Compare: last pair waits, tie-break open', SessionProgress(ridden: 4, pending: true, left: 0, maxLeft: 2)),
  _Case('Compare: tie-break', SessionProgress(ridden: 4, left: 1, maxLeft: 2)),
  _Case('Compare: 1 run left (exact)', SessionProgress.exact(ridden: 5, left: 1)),
  _Case('Compare: last tie-break run waits', SessionProgress(ridden: 6, pending: true, left: 0, maxLeft: 0)),
  _Case('Compare: 6 setups', SessionProgress(ridden: 1, left: 6, maxLeft: 9)),
  _Case('Fine-tune: one knob, fresh', SessionProgress(ridden: 1, left: 7, maxLeft: null)),
  _Case('Fine-tune: run 5 waits', SessionProgress(ridden: 5, pending: true, left: 3, maxLeft: null)),
  _Case('Fine-tune: 1 poll left', SessionProgress(ridden: 7, left: 2, maxLeft: null)),
  _Case('Fine-tune: two knobs (segments shrink)', SessionProgress(ridden: 4, left: 13, maxLeft: null)),
  _Case('Fine-tune: three knobs (too many: one bar)', SessionProgress(ridden: 6, left: 19, maxLeft: null)),
  _Case(
    'Fine-tune: long session, run waits (one bar)',
    SessionProgress(ridden: 23, pending: true, left: 6, maxLeft: null),
  ),
  _Case('Explore: 8 knobs', SessionProgress(ridden: 3, left: 7, maxLeft: 8)),
  _Case('German: range', SessionProgress(ridden: 3, left: 3, maxLeft: 4), locale: Locale('de')),
  _Case('German: estimate', SessionProgress(ridden: 2, left: 6, maxLeft: null), locale: Locale('de')),
  _Case(
    'French: done, 320 px, text scale 1.5',
    SessionProgress.exact(ridden: 7, left: 0),
    width: _narrowWidth,
    textScale: 1.5,
    locale: Locale('fr'),
  ),
  _Case(
    'German: confirmation, 320 px, text scale 2',
    SessionProgress.exact(ridden: 6, left: 1, confirming: true),
    width: _narrowWidth,
    textScale: 2,
    locale: Locale('de'),
  ),
  _Case('Fine-tune: two knobs, 320 px', SessionProgress(ridden: 4, left: 13, maxLeft: null), width: _narrowWidth),
];

/// The pinned area of the sheet: the bar above the next step.
class _Pinned {
  final String slug;
  final String title;
  final SessionProgress? progress;
  final bool rated;
  final double width;
  final double textScale;
  final Locale locale;

  const _Pinned(
    this.slug,
    this.title, {
    required this.progress,
    required this.rated,
    this.width = 360,
    this.textScale = 1,
    this.locale = const Locale('en'),
  });
}

const _pinned = [
  _Pinned(
    'pinned_waiting',
    'Pinned area: run waits for feedback',
    progress: SessionProgress(ridden: 3, pending: true, left: 4, maxLeft: null),
    rated: false,
  ),
  _Pinned(
    'pinned_next',
    'Pinned area: ready for the next run',
    progress: SessionProgress(ridden: 3, left: 3, maxLeft: 4),
    rated: true,
  ),
  _Pinned(
    'pinned_done_bar',
    'Pinned area, converged: full bar + "Done" (as built)',
    progress: SessionProgress.exact(ridden: 7, left: 0),
    rated: true,
  ),
  _Pinned('pinned_done_no_bar', 'Pinned area, converged: without the bar', progress: null, rated: true),
  _Pinned(
    'pinned_narrow',
    'Pinned area: German, 320 px, text scale 1.5',
    progress: SessionProgress(ridden: 4, pending: true, left: 0, maxLeft: 2),
    rated: false,
    width: 320,
    textScale: 1.5,
    locale: Locale('de'),
  ),
];

final _session = TestSession(
  id: 'session',
  bike: 'bike',
  adjustmentIds: const [],
  startedAtUTC: DateTime.utc(2026, 5, 2, 9),
  startedAtLocal: DateTime(2026, 5, 2, 9),
);

AppRepository _repository({required bool rated}) {
  final run = Setup(
    id: 'run',
    name: 'myRun3',
    datetime: DateTime.utc(2026, 5, 2, 10),
    datetimeLocal: DateTime(2026, 5, 2, 10),
    tags: const {},
    bike: 'bike',
    person: null,
    bikeAdjustmentValues: const {},
    personAdjustmentValues: const {},
    testSessionId: _session.id,
  );
  final repository = _MockAppRepository();
  when(() => repository.setupsInSession(any())).thenReturn([run]);
  when(() => repository.feedbacksForSetup(any())).thenReturn([
    if (rated)
      RideFeedback(
        bike: 'bike',
        setupId: run.id,
        dateTimeUTC: DateTime.utc(2026, 5, 2, 11),
        dateTimeLocal: DateTime(2026, 5, 2, 11),
      ),
  ]);
  return repository;
}

const _galleryKey = ValueKey('bar-gallery');
const _pinnedKey = ValueKey('pinned');

Widget _scaled(double textScale, Locale locale, Widget child) => Builder(
  builder: (context) => Localizations.override(
    context: context,
    locale: locale,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  ),
);

Widget _galleryApp(ThemeData theme) => localizedTestApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _galleryKey,
        child: ColoredBox(
          // The sheet's background.
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 32,
              runSpacing: 20,
              children: [
                for (final (i, c) in _cases.indexed)
                  SizedBox(
                    key: ValueKey('cell$i'),
                    width: c.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(c.label, style: theme.textTheme.labelSmall),
                        ),
                        _scaled(c.textScale, c.locale, TestSessionProgress(progress: c.progress)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

Widget _pinnedApp(ThemeData theme, _Pinned pinned) => ChangeNotifierProvider<AppRepository>.value(
  value: _repository(rated: pinned.rated),
  child: localizedTestApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _pinnedKey,
          child: ColoredBox(
            color: theme.colorScheme.surface,
            child: SizedBox(
              width: pinned.width,
              child: _scaled(
                pinned.textScale,
                pinned.locale,
                // As in TestSessionSheetContent.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      if (pinned.progress case final progress?) TestSessionProgress(progress: progress),
                      TestSessionNextStep(session: _session),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('test_session_progress'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      tester.view.physicalSize = const Size(3 * _cellWidth + 2 * 32 + 32, 3000);
      await tester.pumpWidget(_galleryApp(theme));
      await tester.pump();
      await session.add('bars', 'Bar states', tester.renderObject(find.byKey(_galleryKey)));

      for (final pinned in _pinned) {
        tester.view.physicalSize = Size(pinned.width, 600);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_pinnedApp(theme, pinned));
        await tester.pump();
        await session.add(pinned.slug, pinned.title, tester.renderObject(find.byKey(_pinnedKey)));
        expect(tester.takeException(), isNull, reason: '"${pinned.title}" overflows or throws');
      }

      await session.finish();
    });
  }

  testWidgets('every state says what is left, in every language, narrow and with large text', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 400);

    for (final locale in AppLocalizations.supportedLocales) {
      for (final c in _cases) {
        await tester.pumpWidget(
          localizedTestApp(
            key: ValueKey('${locale.languageCode}-${c.label}'),
            locale: locale,
            theme: galleryThemes.first.$2,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: _scaled(2, locale, TestSessionProgress(progress: c.progress)),
              ),
            ),
          ),
        );
        await tester.pump();

        final reason = '"${c.label}" in ${locale.languageCode}';
        final text = tester.widget<Text>(find.byType(Text)).data!;
        expect(text, isNotEmpty, reason: reason);
        expect(text, isNot(contains('{')), reason: reason);
        expect(tester.takeException(), isNull, reason: '$reason overflows or throws');
      }
    }
  });
}
