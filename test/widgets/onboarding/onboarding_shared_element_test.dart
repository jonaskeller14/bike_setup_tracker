import 'package:bike_setup_tracker/icons/bike_icons.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/onboarding_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_shared_element.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_2.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_3.dart';
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

  final flightFinder = find.byKey(OnboardingSharedElementFlight.flightKey);

  /// Whether [slide] shows its own fork icon; false while the flight owns it.
  bool forkVisible(WidgetTester tester, Finder slide) {
    final visibility = find
        .ancestor(
          of: find.descendant(of: slide, matching: find.byIcon(BikeIcons.fork)),
          matching: find.byType(Visibility),
        )
        .first;
    return tester.widget<Visibility>(visibility).visible;
  }

  /// Advances from slide 1 to slide 2, where the fork's flight starts.
  Future<TestGesture> swipeFromSlide2(WidgetTester tester, {bool disableAnimations = false}) async {
    await tester.pumpWidget(buildTestApp(disableAnimations: disableAnimations));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    // The first move is absorbed by touch slop and the gesture arena; the
    // second scrolls far enough for slide 3 to be built and laid out.
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-280, 0));
    await tester.pump();
    await tester.pump();
    return gesture;
  }

  testWidgets('fork flies while swiping and lands on slide 3', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester);

    // Mid-swipe the flight owns the fork and both endpoints hide it.
    expect(flightFinder, findsOneWidget);
    expect(forkVisible(tester, find.byType(OnboardingSlide2)), isFalse);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isFalse);

    // The element keeps the endpoints' size and stays on screen instead of
    // drifting sideways with the page scroll.
    final flightRect = tester.getRect(flightFinder);
    expect(flightRect.size, const Size(40, 40));
    expect(flightRect.left, greaterThanOrEqualTo(0));
    expect(flightRect.right, lessThanOrEqualTo(tester.view.physicalSize.width / tester.view.devicePixelRatio));

    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Nothing is stranded: the flight is gone and slide 3 owns its fork again.
    expect(flightFinder, findsNothing);
    expect(find.text("STEP 2"), findsOneWidget);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isTrue);
  });

  testWidgets('interrupted swipe back to slide 2 lands the fork', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester);
    expect(flightFinder, findsOneWidget);

    // Drag back to the starting page instead of completing the swipe.
    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(flightFinder, findsNothing);
    expect(find.text("STEP 1"), findsOneWidget);
    expect(forkVisible(tester, find.byType(OnboardingSlide2)), isTrue);
  });

  testWidgets('no flight when animations are disabled', (WidgetTester tester) async {
    final gesture = await swipeFromSlide2(tester, disableAnimations: true);

    expect(flightFinder, findsNothing);
    expect(forkVisible(tester, find.byType(OnboardingSlide2)), isTrue);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isTrue);

    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(flightFinder, findsNothing);
    expect(forkVisible(tester, find.byType(OnboardingSlide3)), isTrue);
  });
}
