import 'package:bike_setup_tracker/icons/bike_icons.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/onboarding_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_component_card.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_setup_card.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_2.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_3.dart';
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

  Widget buildTestApp({bool disableAnimations = false}) {
    return ChangeNotifierProvider<AppSettings>.value(
      value: appSettings,
      child: MaterialApp(
        theme: materialAppTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: const OnboardingPage(),
      ),
    );
  }

  final cardFlightFinder = find.byKey(OnboardingPage.componentCardFlightKey);
  final rowsFlightFinder = find.byKey(OnboardingPage.adjustmentRowsFlightKey);

  /// Whether [slide] shows its own copy of [element]; false while a flight owns it.
  bool endpointVisible(WidgetTester tester, Finder slide, Finder element) {
    final visibility = find
        .ancestor(
          of: find.descendant(of: slide, matching: element),
          matching: find.byType(Visibility),
        )
        .first;
    return tester.widget<Visibility>(visibility).visible;
  }

  bool forkVisible(WidgetTester tester, Finder slide) =>
      endpointVisible(tester, slide, find.byIcon(BikeIcons.fork));

  /// A step per frame, the way a real drag arrives: the flight reads the
  /// geometry the previous frame laid out, so a swipe made of a few huge jumps
  /// would leave it interpolating pages that have since moved on.
  Future<TestGesture> startSwipe(WidgetTester tester) async {
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
    }
    return gesture;
  }

  Future<void> finishSwipe(WidgetTester tester, TestGesture gesture) async {
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Advances from slide 1 to slide 2, where the fork's flight starts.
  Future<TestGesture> swipeFromSlide2(WidgetTester tester, {bool disableAnimations = false}) async {
    await tester.pumpWidget(buildTestApp(disableAnimations: disableAnimations));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    return startSwipe(tester);
  }

  /// Advances to slide 3, where the adjustment rows' flight starts.
  Future<TestGesture> swipeFromSlide3(WidgetTester tester, {bool disableAnimations = false}) async {
    final gesture = await swipeFromSlide2(tester, disableAnimations: disableAnimations);
    await finishSwipe(tester, gesture);
    return startSwipe(tester);
  }

  testWidgets('fork flies while swiping and lands on slide 3', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester);

    // Mid-swipe the flight owns the fork and both endpoints hide it.
    expect(cardFlightFinder, findsOneWidget);
    expect(forkVisible(tester, find.byType(OnboardingSlide2)), isFalse);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isFalse);

    // The card grows between the two endpoints and stays on screen instead of
    // drifting sideways with the page scroll.
    final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final flightRect = tester.getRect(cardFlightFinder);
    expect(flightRect.width, greaterThan(OnboardingComponentCard.iconSize));
    expect(flightRect.left, greaterThanOrEqualTo(0));
    expect(flightRect.right, lessThanOrEqualTo(screenWidth));

    // It carries the destination card's content, not a bare icon, and leaves
    // the adjustment rows to the landed slide.
    final flightCard = find.descendant(of: cardFlightFinder, matching: find.byType(OnboardingComponentCard));
    expect(flightCard, findsOneWidget);
    expect(tester.widget<OnboardingComponentCard>(flightCard).adjustments, 0);

    await finishSwipe(tester, gesture);

    // Nothing is stranded: the flight is gone and slide 3 owns its fork again.
    expect(cardFlightFinder, findsNothing);
    expect(find.text("STEP 2"), findsOneWidget);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isTrue);
  });

  testWidgets('interrupted swipe back to slide 2 lands the fork', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester);
    expect(cardFlightFinder, findsOneWidget);

    // Drag back to the starting page instead of completing the swipe.
    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(cardFlightFinder, findsNothing);
    expect(find.text("STEP 1"), findsOneWidget);
    expect(forkVisible(tester, find.byType(OnboardingSlide2)), isTrue);
  });

  testWidgets('no flight when animations are disabled', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester, disableAnimations: true);

    expect(cardFlightFinder, findsNothing);
    expect(forkVisible(tester, find.byType(OnboardingSlide2)), isTrue);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isTrue);

    await finishSwipe(tester, gesture);

    expect(cardFlightFinder, findsNothing);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isTrue);
  });

  /// How far slide 3's adjustment rows have filled in, 0..1.
  double adjustments(WidgetTester tester) {
    final card = find.descendant(
      of: find.byType(OnboardingSlide3),
      matching: find.byType(OnboardingComponentCard),
    );
    return tester.widget<OnboardingComponentCard>(card).adjustments;
  }

  testWidgets('adjustment rows fill in after the card lands', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester);
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();

    // Let the page settle, but stop short of settling the reveal it triggers.
    await tester.pump();
    for (var frame = 0; frame < 60 && cardFlightFinder.evaluate().isNotEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cardFlightFinder, findsNothing);
    expect(adjustments(tester), 0);

    // The rows fill in over their own animation rather than snapping in.
    await tester.pump(const Duration(milliseconds: 200));
    expect(adjustments(tester), greaterThan(0));
    expect(adjustments(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(adjustments(tester), 1.0);
  });

  testWidgets('dragging back towards slide 2 empties the rows again', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester);
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(adjustments(tester), 1.0);

    // Starting back towards slide 2 hands the card to the flight again.
    final back = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await back.moveBy(const Offset(120, 0));
    await tester.pump();
    await back.moveBy(const Offset(120, 0));
    await tester.pump();
    await tester.pump();

    expect(cardFlightFinder, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(adjustments(tester), lessThan(1));

    await back.up();
    await tester.pumpAndSettle();
  });

  bool definitionRowsVisible(WidgetTester tester) =>
      endpointVisible(tester, find.byType(OnboardingSlide3), find.byType(OnboardingComponentCardRows));

  bool valueRowsVisible(WidgetTester tester) =>
      endpointVisible(tester, find.byType(OnboardingSlide4), find.byType(OnboardingSetupRows));

  double rebound(WidgetTester tester) => tester
      .widget<SetStepAdjustmentWidget>(
        find.descendant(of: find.byType(OnboardingSlide4), matching: find.byType(SetStepAdjustmentWidget)),
      )
      .value!;

  testWidgets('adjustment rows fly on into the setup card', (WidgetTester tester) async {
    final gesture = await swipeFromSlide3(tester);

    expect(rowsFlightFinder, findsOneWidget);
    expect(cardFlightFinder, findsNothing);
    // The rows exist on both sides and both hand them to the flight.
    expect(definitionRowsVisible(tester), isFalse);
    expect(valueRowsVisible(tester), isFalse);

    // The flight cross-fades the definitions over to the recorded values.
    expect(find.descendant(of: rowsFlightFinder, matching: find.byType(OnboardingComponentCardRows)), findsOneWidget);
    expect(find.descendant(of: rowsFlightFinder, matching: find.byType(OnboardingSetupRows)), findsOneWidget);

    // It glides between the two resting positions instead of drifting sideways
    // with the page scroll.
    final screen = Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
    expect(screen.contains(tester.getRect(rowsFlightFinder).center), isTrue);

    await finishSwipe(tester, gesture);

    expect(rowsFlightFinder, findsNothing);
    expect(find.text("STEP 3"), findsOneWidget);
    expect(valueRowsVisible(tester), isTrue);
  });

  testWidgets('no rows flight when animations are disabled', (WidgetTester tester) async {
    final gesture = await swipeFromSlide3(tester, disableAnimations: true);

    expect(rowsFlightFinder, findsNothing);
    expect(definitionRowsVisible(tester), isTrue);
    expect(valueRowsVisible(tester), isTrue);

    await finishSwipe(tester, gesture);

    expect(rowsFlightFinder, findsNothing);
    expect(valueRowsVisible(tester), isTrue);
  });

  testWidgets('the setup sequence waits for the flight and never replays', (WidgetTester tester) async {
    final gesture = await swipeFromSlide3(tester);

    // Nothing is recorded while the rows are still travelling.
    expect(rebound(tester), OnboardingSetupExample.startRebound);

    await finishSwipe(tester, gesture);
    expect(rebound(tester), OnboardingSetupExample.editedRebound);
    expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));

    // Back to slide 3 and forward again: the diary stays as it was left.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text("STEP 2"), findsOneWidget);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(rebound(tester), OnboardingSetupExample.editedRebound);
    expect(find.byType(OnboardingSetupSnapshotCard), findsNWidgets(2));
  });
}
