import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../widgets/onboarding/onboarding_component_card.dart';
import '../widgets/onboarding/onboarding_shared_element.dart';
import '../widgets/onboarding/onboarding_slide_1.dart';
import '../widgets/onboarding/onboarding_slide_2.dart';
import '../widgets/onboarding/onboarding_slide_3.dart';
import '../widgets/onboarding/onboarding_slide_4.dart';
import '../widgets/onboarding/onboarding_slide_5.dart';
import '../widgets/onboarding/onboarding_slide_6.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  /// The component card travelling from slide 2 into slide 3.
  static const Key componentCardFlightKey = ValueKey('onboarding_component_card_flight');

  /// The adjustment rows travelling from slide 3 into slide 4's setup card.
  static const Key adjustmentRowsFlightKey = ValueKey('onboarding_adjustment_rows_flight');

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

/// One slide plus the secondary action the app bar offers while it is shown.
typedef _OnboardingSlide = ({Widget Function() build, String? secondaryLabel, VoidCallback? onSecondary});

class _OnboardingPageState extends State<OnboardingPage> {
  /// The rider slide exists only where the Person feature does; the rest of
  /// that feature is unfinished and must not ship just because onboarding can
  /// create a record.
  late final bool _showRiderSlide = context.read<AppSettings>().enablePerson;

  /// The rider comes right after the promise, so the teaching slides run
  /// uninterrupted into the closing one. It pushes them — and the flights
  /// between them — one page along.
  static const int _riderSlideIndex = 1;
  int get _componentSlideIndex => _showRiderSlide ? 2 : 1;
  int get _adjustmentSlideIndex => _componentSlideIndex + 1;
  int get _setupSlideIndex => _componentSlideIndex + 2;

  final PageController _controller = PageController();
  int _currentPage = 0;
  late List<_OnboardingSlide> _slides;

  final GlobalKey _forkSourceKey = GlobalKey(debugLabel: 'onboarding_fork_source');
  final GlobalKey _forkTargetKey = GlobalKey(debugLabel: 'onboarding_fork_target');
  final ValueNotifier<bool> _forkInFlight = ValueNotifier<bool>(false);

  final GlobalKey _rowsSourceKey = GlobalKey(debugLabel: 'onboarding_rows_source');
  final GlobalKey _rowsTargetKey = GlobalKey(debugLabel: 'onboarding_rows_target');
  final ValueNotifier<bool> _rowsInFlight = ValueNotifier<bool>(false);

  /// Owned by the page so the typed rider name — and the rider once created —
  /// survive a swipe or a Back within the session.
  final TextEditingController _riderNameController = TextEditingController();
  String? _savedRiderName;

  late final Listenable _flightsChanged = Listenable.merge([_forkInFlight, _rowsInFlight]);

  late final List<OnboardingSharedElement> _sharedElements = [
    OnboardingSharedElement(
      flightKey: OnboardingPage.componentCardFlightKey,
      fromPage: _componentSlideIndex,
      toPage: _adjustmentSlideIndex,
      sourceKey: _forkSourceKey,
      targetKey: _forkTargetKey,
      hidden: _forkInFlight,
      builder: (BuildContext context, double progress, Size targetSize) =>
          OnboardingComponentCardFlight(progress: progress, targetSize: targetSize),
    ),
    OnboardingSharedElement(
      flightKey: OnboardingPage.adjustmentRowsFlightKey,
      fromPage: _adjustmentSlideIndex,
      toPage: _setupSlideIndex,
      sourceKey: _rowsSourceKey,
      targetKey: _rowsTargetKey,
      hidden: _rowsInFlight,
      builder: (BuildContext context, double progress, Size targetSize) =>
          OnboardingAdjustmentRowsFlight(progress: progress, targetSize: targetSize),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final existingRiders = context.read<AppRepository>().persons.values;
    if (existingRiders.isNotEmpty) {
      _savedRiderName = existingRiders.first.name;
    }
    _slides = [
      (
        build: () => OnboardingSlide1(onNext: _next),
        secondaryLabel: "Skip",
        onSecondary: _complete,
      ),
      if (_showRiderSlide)
        (
          build: () => OnboardingSlide5(
            onNext: _next,
            active: _currentPage == _riderSlideIndex,
            controller: _riderNameController,
            savedName: _savedRiderName,
            onSaved: (name) => setState(() => _savedRiderName = name),
          ),
          secondaryLabel: "Not now",
          onSecondary: _next,
        ),
      (
        build: () => OnboardingSlide2(onNext: _next, forkKey: _forkSourceKey, forkHidden: _forkInFlight),
        secondaryLabel: "Skip",
        onSecondary: _complete,
      ),
      (
        build: () => OnboardingSlide3(
          onNext: _next,
          // The card has landed once the flight has handed it back and this is
          // at least the settled page; the rows stay filled beyond it so the
          // flight into slide 4 has something to carry.
          showAdjustments: _currentPage >= _adjustmentSlideIndex && !_forkInFlight.value,
          forkKey: _forkTargetKey,
          forkHidden: _forkInFlight,
          rowsKey: _rowsSourceKey,
          rowsHidden: _rowsInFlight,
        ),
        secondaryLabel: "Skip",
        onSecondary: _complete,
      ),
      (
        build: () => OnboardingSlide4(
          onNext: _next,
          active: _currentPage == _setupSlideIndex && !_rowsInFlight.value,
          rowsKey: _rowsTargetKey,
          rowsHidden: _rowsInFlight,
        ),
        secondaryLabel: "Skip",
        onSecondary: _complete,
      ),
      (
        build: () => OnboardingSlide6(onFinish: _complete),
        secondaryLabel: "Skip",
        onSecondary: _complete,
      ),
    ];
  }

  void _next() {
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
    );
  }

  void _goTo(int index) {
    if (index == _currentPage) return;
    unawaited(
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
    );
  }

  void _complete() => context.read<AppSettings>().showOnboarding = false;

  @override
  void dispose() {
    _riderNameController.dispose();
    _forkInFlight.dispose();
    _rowsInFlight.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                onPressed: () async {
                  await _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : const SizedBox.shrink(),
        centerTitle: true,
        title: Semantics(
          container: true,
          label: "Step ${_currentPage + 1} of ${_slides.length}",
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) => _builProgressIndicatorDot(index)),
            ),
          ),
        ),
        actions: [
          if (_slides[_currentPage].secondaryLabel case final label?)
            TextButton(onPressed: _slides[_currentPage].onSecondary, child: Text(label)),
        ],
      ),
      body: SafeArea(
        child: OnboardingSharedElementFlight(
          controller: _controller,
          elements: _sharedElements,
          // Rebuilds the slides when a flight takes or hands back its element,
          // so the slides know when to fill their rows in and when to start.
          child: ListenableBuilder(
            listenable: _flightsChanged,
            builder: (context, _) => PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _slides.length,
              itemBuilder: (context, index) => _slides[index].build(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _builProgressIndicatorDot(int index) {
    final dot = AnimatedContainer(
      key: ValueKey("onboarding_dot_$index"),
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
    );
    return GestureDetector(
      onTap: () => _goTo(index),
      // Padding for larger tap target
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: dot,
      ),
    );
  }
}
