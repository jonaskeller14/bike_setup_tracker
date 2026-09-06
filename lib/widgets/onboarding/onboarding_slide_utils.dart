import 'dart:async';

import 'package:flutter/material.dart';

import 'onboarding_motion.dart';

Widget stepWidget({required BuildContext context, required int step}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "STEP $step",
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Runs the shared onboarding entrance on one slide element, [delay] after the
/// slide is built, so a group of them can be staged.
class DelayedFade extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const DelayedFade({super.key, required this.delay, required this.child});

  @override
  State<DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<DelayedFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kOnboardingEntranceDuration,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A cancellable timer, so leaving the slide early does not leave one running.
    _timer = Timer(widget.delay, () => unawaited(_controller.forward()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion has nothing to stage: drop the pending entrance instead
    // of running an animation the build below never reads.
    if (!reduceMotion(context)) return;
    _timer?.cancel();
    _controller.value = 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      // The slot is held from the first frame so the staged row does not resize
      // as each item lands, and so a shared element can measure its endpoint.
      child: widget.child,
      builder: (context, child) => onboardingEntrance(progress: _controller.value, child: child!),
    );
  }
}
