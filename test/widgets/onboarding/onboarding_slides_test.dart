import 'package:bike_setup_tracker/icons/bike_icons.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_1.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSlide(
    Widget slide, {
    bool disableAnimations = false,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: SafeArea(child: slide),
        ),
      ),
    );
  }

  /// Shrinks the surface to a narrow phone for the caller's test.
  void useNarrowScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('slide 1', () {
    testWidgets('renders headline, body and its own primary action', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Dial in your ride'), findsOneWidget);
      expect(find.text('Save every change. Learn what works.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
      // The product name is carried by the logo, not repeated underneath it.
      expect(find.textContaining('Bike Setup Tracker'), findsNothing);
    });

    testWidgets('logo animates into place and then holds still', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {})));
      await tester.pump();

      final entering = tester.getRect(find.byType(Image));
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byType(Image));
      expect(entering, isNot(settled));

      // Stillness after the entrance: an incidental rebuild does not replay it.
      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {})));
      await tester.pump();
      expect(tester.getRect(find.byType(Image)), settled);
    });

    testWidgets('renders the settled state on the first frame with reduced motion', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {}), disableAnimations: true));
      await tester.pump();

      final firstFrame = tester.getRect(find.byType(Image));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Image)), firstFrame);
    });

    testWidgets('does not overflow on a narrow screen at 2.0 text scale', (WidgetTester tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(buildSlide(OnboardingSlide1(onNext: () {}), textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dial in your ride'), findsOneWidget);
    });
  });

  group('slide 2', () {
    testWidgets('renders headline, body and its own primary action', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Build your bike'), findsOneWidget);
      expect(find.text('Track only the components you care about.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
    });

    testWidgets('component cards stage in and then hold still', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {})));
      await tester.pump();

      final entering = tester.getRect(find.byIcon(BikeIcons.wheelRear));
      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byIcon(BikeIcons.wheelRear));
      expect(entering, isNot(settled));

      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {})));
      await tester.pump();
      expect(tester.getRect(find.byIcon(BikeIcons.wheelRear)), settled);
    });

    testWidgets('the staged row settles inside the entrance budget', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {})));
      for (var frame = 0; frame < 63; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // No motion is left once the ~1s budget is spent; pumpAndSettle would
      // hide a staged sequence that overran it.
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('renders the settled state on the first frame with reduced motion', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {}), disableAnimations: true));
      await tester.pump();

      final firstFrame = tester.getRect(find.byIcon(BikeIcons.wheelRear));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byIcon(BikeIcons.wheelRear)), firstFrame);
    });

    testWidgets('does not overflow on a narrow screen at 2.0 text scale', (WidgetTester tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {}), textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The FittedBox keeps all four component cards on screen.
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      for (final icon in [BikeIcons.fork, BikeIcons.shock, BikeIcons.wheelFront, BikeIcons.wheelRear]) {
        final rect = tester.getRect(find.byIcon(icon));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(screenWidth));
      }
    });
  });
}
