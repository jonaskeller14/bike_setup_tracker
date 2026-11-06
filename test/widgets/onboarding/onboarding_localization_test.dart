import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_1.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  Widget buildSlide(Widget slide, Locale locale) {
    return localizedTestApp(
      theme: materialAppTheme,
      locale: locale,
      home: Scaffold(body: SafeArea(child: slide)),
    );
  }

  group('slide 1', () {
    testWidgets('speaks German with the app name in italics', (tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {}), const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('Bereit zum Einstellen?'), findsOneWidget);
      expect(find.textContaining('Schluss mit Raten', findRichText: true), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Weiter'), findsOneWidget);
      expect(find.textContaining('<', findRichText: true), findsNothing);
    });

    testWidgets('keeps the English wording', (tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {}), const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Ready to Dial It In?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
    });
  });

  group('slide 2', () {
    testWidgets('sets the emphasized German words bold in place', (tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {}), const Locale('de')));
      await tester.pumpAndSettle();

      final body = tester.widget<RichText>(find.textContaining('digitalen Zwilling', findRichText: true));
      final bold = <String>[];
      body.text.visitChildren((span) {
        if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) bold.add(span.text!);
        return true;
      });

      expect(bold, ['Bikes', 'Komponenten']);
      expect(body.text.toPlainText(), startsWith('Füge deine Bikes und deren Komponenten hinzu'));
      expect(find.text('Baue dein Bike'), findsOneWidget);
    });

    testWidgets('keeps the English wording', (tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {}), const Locale('en')));
      await tester.pumpAndSettle();

      final body = tester.widget<RichText>(find.textContaining('digital twin', findRichText: true));
      expect(body.text.toPlainText(), startsWith('Add your bikes and their components that you want to track.'));
    });
  });
}
