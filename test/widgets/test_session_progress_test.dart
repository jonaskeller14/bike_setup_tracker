import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/test_session_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    SessionProgress progress, {
    double width = 328,
    double textScale = 1,
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      localizedTestApp(
        key: UniqueKey(),
        locale: locale,
        theme: theme ?? materialAppTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: TestSessionProgress(progress: progress),
            ),
          ),
        ),
      ),
    );
  }

  Finder bar() => find.descendant(of: find.byType(TestSessionProgress), matching: find.byType(CustomPaint));

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

    testWidgets('draws one segment per run: ridden, planned and possible', (tester) async {
      await pump(tester, const SessionProgress(ridden: 3, left: 2, maxLeft: 4));

      // 3 filled and 2 planned segments; the 2 possible ones are dashed paths.
      expect(bar(), paintsExactlyCountTimes(#drawRRect, 5));
      expect(bar(), paints..path(style: PaintingStyle.stroke));
    });

    testWidgets('fills half of the run that waits for its feedback', (tester) async {
      await pump(tester, const SessionProgress(ridden: 3, pending: true, left: 2, maxLeft: 2));

      expect(bar(), paintsExactlyCountTimes(#drawRRect, 4));
      expect(bar(), paintsExactlyCountTimes(#clipRRect, 1));
    });

    testWidgets('a finished session is filled to the end', (tester) async {
      await pump(tester, const SessionProgress.exact(ridden: 7, left: 0));

      expect(bar(), paintsExactlyCountTimes(#drawRRect, 7));
      expect(bar(), isNot(paints..path()));
    });

    testWidgets('falls back to one bar where the segments get too thin', (tester) async {
      // 10 ridden + 12 left + 3 fading: 25 segments.
      const progress = SessionProgress(ridden: 10, left: 12, maxLeft: null);
      const fits = 25 * TestSessionProgress.minSegmentWidth + 24 * TestSessionProgress.gap;
      expect(TestSessionProgress.fitsSegments(fits, 25), isTrue);
      expect(TestSessionProgress.fitsSegments(fits - 1, 25), isFalse);

      await pump(tester, progress, width: fits);
      expect(bar(), paintsExactlyCountTimes(#drawRRect, 22));

      await pump(tester, progress, width: fits - 1);
      expect(bar(), paintsExactlyCountTimes(#drawRRect, 0));
      expect(bar(), paintsExactlyCountTimes(#drawRect, 2));
      expect(find.text('About 12 more runs'), findsOneWidget);
    });

    for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('fits a narrow screen with large text in every language ($name)', (tester) async {
        for (final locale in AppLocalizations.supportedLocales) {
          for (final (progress, _) in cases) {
            await pump(tester, progress, width: 288, textScale: 2, locale: locale, theme: theme);

            expect(tester.takeException(), isNull, reason: '$progress in ${locale.languageCode}');
          }
        }
      });
    }
  });
}
