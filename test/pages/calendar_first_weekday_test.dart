import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/l10n/locale_resolution.dart';
import 'package:bike_setup_tracker/pages/calendar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('calendarFirstWeekday', () {
    test('maps Sunday (0) to DateTime.sunday', () {
      expect(calendarFirstWeekday(0), DateTime.sunday);
    });

    test('keeps Monday to Saturday as they are', () {
      expect(calendarFirstWeekday(1), DateTime.monday);
      expect(calendarFirstWeekday(6), DateTime.saturday);
    });
  });

  group('first day of the week per locale', () {
    Future<int> firstWeekday(WidgetTester tester, Locale locale) async {
      late int weekday;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: [locale],
          home: Builder(
            builder: (context) {
              weekday = calendarFirstWeekday(MaterialLocalizations.of(context).firstDayOfWeekIndex);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return weekday;
    }

    testWidgets('German starts on Monday', (tester) async {
      expect(await firstWeekday(tester, const Locale('de')), DateTime.monday);
    });

    testWidgets('English starts on Sunday', (tester) async {
      expect(await firstWeekday(tester, const Locale('en')), DateTime.sunday);
    });
  });

  group('first day of the week with the device region', () {
    // The app's own setup: language-only supported locales, every delegate, and
    // the callback that keeps the region.
    Future<({Locale locale, int weekday})> pumpApp(WidgetTester tester, Locale locale) async {
      late Locale resolved;
      late int weekday;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localeResolutionCallback: keepRegionLocale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              resolved = Localizations.localeOf(context);
              weekday = calendarFirstWeekday(MaterialLocalizations.of(context).firstDayOfWeekIndex);
              // The pattern of the about page: a date formatted for the full locale.
              DateFormat.yMMMM(resolved.toString()).format(DateTime(2026, 11, 2));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (locale: resolved, weekday: weekday);
    }

    testWidgets('the region survives the resolution', (tester) async {
      expect((await pumpApp(tester, const Locale('en', 'GB'))).locale, const Locale('en', 'GB'));
    });

    testWidgets('English in the UK and Australia starts on Monday', (tester) async {
      expect((await pumpApp(tester, const Locale('en', 'GB'))).weekday, DateTime.monday);
      expect((await pumpApp(tester, const Locale('en', 'AU'))).weekday, DateTime.monday);
    });

    testWidgets('English in the US and Canada starts on Sunday', (tester) async {
      expect((await pumpApp(tester, const Locale('en', 'US'))).weekday, DateTime.sunday);
      expect((await pumpApp(tester, const Locale('en', 'CA'))).weekday, DateTime.sunday);
    });

    testWidgets('German starts on Monday in every region', (tester) async {
      expect((await pumpApp(tester, const Locale('de', 'DE'))).weekday, DateTime.monday);
      expect((await pumpApp(tester, const Locale('de', 'CH'))).weekday, DateTime.monday);
    });

    // Flutter has no en_DE data. The region must not break anything; the
    // week start is the one of plain English.
    testWidgets('a region without Flutter data falls back to the language', (tester) async {
      final app = await pumpApp(tester, const Locale('en', 'DE'));
      expect(app.locale, const Locale('en', 'DE'));
      expect(app.weekday, DateTime.sunday);
      expect(tester.takeException(), isNull);
    });
  });
}
