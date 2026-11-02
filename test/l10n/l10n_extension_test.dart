import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/l10n/locale_resolution.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';

void main() {
  Future<BuildContext> pumpApp(WidgetTester tester, {Locale? locale}) async {
    late BuildContext context;
    final home = Builder(
      builder: (builderContext) {
        context = builderContext;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      locale == null ? localizedTestApp(home: home) : localizedTestApp(locale: locale, home: home),
    );
    return context;
  }

  testWidgets('context.l10n resolves English by default', (tester) async {
    final context = await pumpApp(tester);

    expect(context.l10n.cancel, 'Cancel');
    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Cancel');
  });

  testWidgets('context.l10n resolves German together with the Material strings', (tester) async {
    final context = await pumpApp(tester, locale: const Locale('de'));

    expect(context.l10n.cancel, 'Abbrechen');
    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Abbrechen');
  });

  testWidgets('a device region leaves the language and its text alone', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de', 'CH'),
        localeResolutionCallback: keepRegionLocale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(context.untrackedLocale, const Locale('de', 'CH'));
    expect(context.untrackedLocaleName, 'de_CH');
    expect(lookupAppLocalizations(context.untrackedLocale).cancel, 'Abbrechen');
    expect(context.l10n.cancel, 'Abbrechen');
  });
}
