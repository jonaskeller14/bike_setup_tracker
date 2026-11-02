import 'package:bike_setup_tracker/pages/calendar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
