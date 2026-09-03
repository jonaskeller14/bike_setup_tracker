import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'onboarding_component_card.dart';
import 'onboarding_motion.dart';
import 'onboarding_shared_element.dart';
import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

class OnboardingSlide3 extends StatefulWidget {
  const OnboardingSlide3({
    super.key,
    required this.onNext,
    required this.showAdjustments,
    this.forkKey,
    this.forkHidden,
  });

  final VoidCallback onNext;

  /// True once the card has landed on this slide. The adjustment rows fill in
  /// then, and empty again if the user drags back towards slide 2.
  final bool showAdjustments;

  /// Target endpoint of the fork card's flight from slide 2.
  final GlobalKey? forkKey;
  final ValueListenable<bool>? forkHidden;

  @override
  State<OnboardingSlide3> createState() => _OnboardingSlide3State();
}

class _OnboardingSlide3State extends State<OnboardingSlide3> with SingleTickerProviderStateMixin {
  late final AnimationController _adjustments = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: widget.showAdjustments ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant OnboardingSlide3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAdjustments == widget.showAdjustments) return;

    if (reduceMotion(context)) {
      _adjustments.value = widget.showAdjustments ? 1 : 0;
    } else if (widget.showAdjustments) {
      unawaited(_adjustments.forward());
    } else {
      unawaited(_adjustments.reverse());
    }
  }

  @override
  void dispose() {
    _adjustments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingSlideScaffold(
      onNext: widget.onNext,
      nextLabel: "Next",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The card itself is fully open here: arriving from slide 2 the
          // flight opened it, and arriving any other way it should just be there.
          SharedElementEndpoint(
            endpointKey: widget.forkKey,
            hidden: widget.forkHidden,
            child: Card(
              margin: EdgeInsets.zero,
              child: AnimatedBuilder(
                animation: _adjustments,
                builder: (context, child) => OnboardingComponentCard(adjustments: _adjustments.value),
              ),
            ),
          ),
          const SizedBox(height: 60),
          stepWidget(context: context, step: 2),
          const SizedBox(height: 12),
          Text(
            'Virtual Dials for Physical Knobs',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text.rich(
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            const TextSpan(
              children: [
                TextSpan(text: "Every component is built from a few simple "),
                TextSpan(text: "Adjustments", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ". This modular design lets you track anything. "),
                TextSpan(text: "Adjustments", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: " define the rules—like limits and units—not the actual values."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
