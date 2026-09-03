import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_numerical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_setup_card.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_1.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_2.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_3.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_4.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_5.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_6.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockStravaService extends Mock implements StravaService {}

/// The motion rules every onboarding slide shares: nothing keeps moving once
/// the entrance has settled, motion never stands between the rider and the
/// primary action, and reduced motion skips straight to the settled state.
void main() {
  late AppSettings appSettings;
  late MockSubscriptionService subscription;
  late MockStravaService strava;
  late TextEditingController riderName;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings();
    subscription = MockSubscriptionService();
    strava = MockStravaService();
    riderName = TextEditingController();

    when(() => subscription.hasStravaEntitlement).thenReturn(false);
    when(() => subscription.offersReady).thenReturn(false);
    when(() => strava.isConnected).thenReturn(false);
    when(() => strava.availability).thenReturn(null);
  });

  tearDown(() {
    riderName.dispose();
    appSettings.dispose();
  });

  Widget host(
    Widget slide, {
    bool disableAnimations = false,
    bool accessibleNavigation = false,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
        ChangeNotifierProvider<StravaService>.value(value: strava),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              disableAnimations: disableAnimations,
              accessibleNavigation: accessibleNavigation,
            ),
            child: SafeArea(child: slide),
          ),
        ),
      ),
    );
  }

  /// Every slide of the flow, built the way the page builds it, together with
  /// the label of the primary action that leaves it.
  ///
  /// The rider slide arrives with a rider already saved: its field would
  /// otherwise take focus, and a blinking caret never settles.
  List<({String name, String nextLabel, Widget Function(VoidCallback onNext) build})> slides() => [
    (name: 'slide 1', nextLabel: 'Next', build: (onNext) => OnboardingSlide1(onNext: onNext)),
    (name: 'slide 2', nextLabel: 'Next', build: (onNext) => OnboardingSlide2(onNext: onNext)),
    (
      name: 'slide 3',
      nextLabel: 'Next',
      build: (onNext) => OnboardingSlide3(onNext: onNext, showAdjustments: true),
    ),
    (name: 'slide 4', nextLabel: 'Next', build: (onNext) => OnboardingSlide4(onNext: onNext, active: true)),
    (
      name: 'slide 5',
      nextLabel: 'Next',
      build: (onNext) => OnboardingSlide5(
        onNext: onNext,
        active: false,
        controller: riderName,
        savedName: 'Jonas',
        onSaved: (_) {},
      ),
    ),
    (name: 'slide 6', nextLabel: 'Continue free', build: (onNext) => OnboardingSlide6(onFinish: onNext)),
  ];

  for (final slide in slides()) {
    group(slide.name, () {
      testWidgets('renders settled on the first frame with animations disabled', (WidgetTester tester) async {
        await tester.pumpWidget(host(slide.build(() {}), disableAnimations: true));
        await tester.pump();

        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders settled on the first frame with a screen reader', (WidgetTester tester) async {
        await tester.pumpWidget(host(slide.build(() {}), accessibleNavigation: true));
        await tester.pump();

        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the entrance settles and then holds still', (WidgetTester tester) async {
        await tester.pumpWidget(host(slide.build(() {})));
        // Every entrance is finite and inside the ~1s budget; slide 4's scripted
        // sequence is the one deliberate exception and settles on its own.
        await tester.pumpAndSettle();

        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('the primary action never waits for motion', (WidgetTester tester) async {
        var advanced = false;
        await tester.pumpWidget(host(slide.build(() => advanced = true)));
        // The very first frame, with the entrance still on its way in.
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, slide.nextLabel));
        expect(advanced, isTrue);

        await tester.pumpAndSettle();
      });
    });
  }

  testWidgets('slide 4 pauses its sequence while the rider is on another slide', (WidgetTester tester) async {
    double pressure() => tester
        .widget<DisplayNumericalAdjustmentWidget>(find.byType(DisplayNumericalAdjustmentWidget))
        .value!
        .toDouble();

    await tester.pumpWidget(host(OnboardingSlide4(onNext: () {}, active: true)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));

    final midScript = pressure();
    expect(midScript, greaterThan(OnboardingSetupExample.startPressure));
    expect(midScript, lessThan(OnboardingSetupExample.editedPressure));

    // Swiped away: the sequence stops rather than performing to nobody.
    await tester.pumpWidget(host(OnboardingSlide4(onNext: () {}, active: false)));
    await tester.pump(const Duration(seconds: 2));

    expect(pressure(), midScript);
    expect(tester.hasRunningAnimations, isFalse);

    // Swiped back: it resumes where it stopped instead of replaying.
    await tester.pumpWidget(host(OnboardingSlide4(onNext: () {}, active: true)));
    await tester.pump();

    expect(pressure(), greaterThanOrEqualTo(midScript));

    await tester.pumpAndSettle();
    expect(pressure(), OnboardingSetupExample.editedPressure);
    expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));
  });
}
