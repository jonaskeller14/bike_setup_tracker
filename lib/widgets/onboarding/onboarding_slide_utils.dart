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

class DelayedFade extends StatefulWidget {
  final int delay;
  final String keyId;
  final Widget child;

  const DelayedFade({super.key, required this.delay, required this.keyId, required this.child});

  @override
  State<DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<DelayedFade> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // A cancellable timer, so leaving the slide early does not leave one running.
    _timer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.keyId),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: kOnboardingEntranceDuration,
      curve: kOnboardingEntranceCurve,
      builder: (context, size, child) {
        return Transform.scale(
          scale: size,
          child: child,
        );
      },
      // The slot is held from the start so the staged row does not resize as
      // each card lands, and so a shared element can measure its endpoint.
      child: Visibility.maintain(visible: _visible, child: widget.child),
    );
  }
}
