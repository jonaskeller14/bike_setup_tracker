import 'package:bike_setup_tracker/icons/bike_icons.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_numerical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_setup_card.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_1.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_2.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_4.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings();
  });

  tearDown(() => appSettings.dispose());

  Widget buildSlide(
    Widget slide, {
    bool disableAnimations = false,
    double textScale = 1.0,
  }) {
    return ChangeNotifierProvider<AppSettings>.value(
      value: appSettings,
      child: MaterialApp(
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

      expect(find.text('Ready to Dial It In?'), findsOneWidget);
      expect(find.textContaining('Stop guessing your settings', findRichText: true), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
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
      expect(find.text('Ready to Dial It In?'), findsOneWidget);
    });
  });

  group('slide 2', () {
    testWidgets('renders headline, body and its own primary action', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide2(onNext: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Build Your Bike'), findsOneWidget);
      expect(find.textContaining('digital twin', findRichText: true), findsOneWidget);
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

  group('slide 4', () {
    double rebound(WidgetTester tester) =>
        tester.widget<SetStepAdjustmentWidget>(find.byType(SetStepAdjustmentWidget)).value!;

    double pressure(WidgetTester tester) => tester
        .widget<DisplayNumericalAdjustmentWidget>(find.byType(DisplayNumericalAdjustmentWidget))
        .value!
        .toDouble();

    /// A touch that lands on the card without reaching a control.
    Future<void> touchCard(WidgetTester tester) async {
      final row = tester.getRect(find.byKey(const ValueKey('onboarding_pressure_row')));
      await tester.tapAt(Offset(row.left + 8, row.center.dy));
    }

    testWidgets('the sequence ends with the setup dropped into the timeline', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide4(onNext: () {}, active: true)));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingSetupCard), findsOneWidget);
      expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));
      // The stamped header arrived with the setup.
      expect(find.text("My new Setup"), findsOneWidget);
      expect(find.text("Whistler, CA"), findsOneWidget);
      expect(pressure(tester), OnboardingSetupExample.editedPressure);
      expect(rebound(tester), OnboardingSetupExample.editedRebound);
    });

    testWidgets('the pressure ramps in before the rebound clicks over', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide4(onNext: () {}, active: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      final ramping = pressure(tester);
      expect(ramping, greaterThan(OnboardingSetupExample.startPressure));
      expect(ramping, lessThan(OnboardingSetupExample.editedPressure));
      // One edit at a time: the rebound waits for the pressure to land.
      expect(rebound(tester), OnboardingSetupExample.startRebound);

      await tester.pump(const Duration(milliseconds: 800));
      expect(pressure(tester), OnboardingSetupExample.editedPressure);
      expect(rebound(tester), greaterThan(OnboardingSetupExample.startRebound));
    });

    testWidgets('the diary compresses into a stack a beat after it opens', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide4(onNext: () {}, active: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3800));

      // Open: every entry shows its values and where it was ridden.
      final opened = tester.getRect(find.byType(OnboardingSetupSnapshotCard).first);
      expect(find.text("Finale Ligure, IT"), findsOneWidget);

      await tester.pumpAndSettle();

      final stacked = tester.getRect(find.byType(OnboardingSetupSnapshotCard).first);
      expect(stacked.height, lessThan(opened.height));
      // The titles survive the tuck; the values and the context row do not.
      expect(find.text("Enduro Day"), findsOneWidget);
      expect(find.text("Finale Ligure, IT"), findsNothing);
    });

    testWidgets('a touch stops the script and keeps the value it had', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide4(onNext: () {}, active: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2300));

      final touched = rebound(tester);
      expect(touched, greaterThan(OnboardingSetupExample.startRebound));
      expect(touched, lessThan(OnboardingSetupExample.editedRebound));

      await touchCard(tester);
      await tester.pumpAndSettle();

      // The script stops driving the value, but still hands over a settled
      // slide rather than one frozen half-way.
      expect(rebound(tester), touched);
      expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));
    });

    testWidgets('advancing never waits for the sequence', (WidgetTester tester) async {
      var advanced = false;
      await tester.pumpWidget(buildSlide(OnboardingSlide4(onNext: () => advanced = true, active: true)));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      expect(advanced, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('renders the settled timeline on the first frame with reduced motion', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildSlide(OnboardingSlide4(onNext: () {}, active: true), disableAnimations: true),
      );
      await tester.pump();

      expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));
      expect(rebound(tester), OnboardingSetupExample.editedRebound);
      // Settled means stacked too, not merely expanded.
      expect(find.text("Finale Ligure, IT"), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('does not start until the slide is the active page', (WidgetTester tester) async {
      await tester.pumpWidget(buildSlide(OnboardingSlide4(onNext: () {}, active: false)));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(pressure(tester), OnboardingSetupExample.startPressure);
      expect(rebound(tester), OnboardingSetupExample.startRebound);
      expect(find.byType(OnboardingSetupSnapshotCard), findsNothing);
    });

    testWidgets('does not overflow on a narrow screen at 2.0 text scale', (WidgetTester tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(
        buildSlide(OnboardingSlide4(onNext: () {}, active: true), textScale: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));
    });
  });
}
