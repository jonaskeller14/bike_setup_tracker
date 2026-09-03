import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../widgets/onboarding/onboarding_component_card.dart';
import '../widgets/onboarding/onboarding_shared_element.dart';
import '../widgets/onboarding/onboarding_slide_1.dart';
import '../widgets/onboarding/onboarding_slide_2.dart';
import '../widgets/onboarding/onboarding_slide_3.dart';
import '../widgets/onboarding/onboarding_slide_4.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

/// One slide plus the secondary action the app bar offers while it is shown.
typedef _OnboardingSlide = ({Widget Function() build, String? secondaryLabel, VoidCallback? onSecondary});

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _componentSlideIndex = 1;
  static const int _adjustmentSlideIndex = 2;

  final PageController _controller = PageController();
  int _currentPage = 0;
  late List<_OnboardingSlide> _slides;

  final GlobalKey _forkSourceKey = GlobalKey(debugLabel: 'onboarding_fork_source');
  final GlobalKey _forkTargetKey = GlobalKey(debugLabel: 'onboarding_fork_target');
  final ValueNotifier<bool> _forkInFlight = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _slides = [
      (
        build: () => OnboardingSlide1(onNext: _next),
        secondaryLabel: "Skip",
        onSecondary: _complete,
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
          // the settled page; only then do the adjustment rows fill in.
          showAdjustments: _currentPage == _adjustmentSlideIndex && !_forkInFlight.value,
          forkKey: _forkTargetKey,
          forkHidden: _forkInFlight,
        ),
        secondaryLabel: "Skip",
        onSecondary: _complete,
      ),
      (
        build: () => OnboardingSlide4(onFinish: _complete),
        secondaryLabel: null,
        onSecondary: null,
      ),
    ];
  }

  void _next() {
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  void _complete() => context.read<AppSettings>().showOnboarding = false;

  @override
  void dispose() {
    _forkInFlight.dispose();
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
              )
            : const SizedBox.shrink(),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) => _builProgressIndicatorDot(index)),
        ),
        actions: [
          if (_slides[_currentPage].secondaryLabel case final label?)
            TextButton(onPressed: _slides[_currentPage].onSecondary, child: Text(label)),
        ],
      ),
      body: SafeArea(
        child: OnboardingSharedElementFlight(
          controller: _controller,
          fromPage: _componentSlideIndex,
          toPage: _adjustmentSlideIndex,
          sourceKey: _forkSourceKey,
          targetKey: _forkTargetKey,
          hidden: _forkInFlight,
          flightBuilder: (BuildContext context, double progress, Size targetSize) =>
              OnboardingComponentCardFlight(progress: progress, targetSize: targetSize),
          // Rebuilds the slides when the flight takes or hands back the card,
          // so slide 3 knows when to fill in its adjustment rows.
          child: ValueListenableBuilder<bool>(
            valueListenable: _forkInFlight,
            builder: (context, _, _) => PageView.builder(
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
    return AnimatedContainer(
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
  }
}
