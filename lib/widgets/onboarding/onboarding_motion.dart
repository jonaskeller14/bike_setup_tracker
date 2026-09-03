import 'package:flutter/material.dart';

/// Shared timings for onboarding entrances. One rule for every slide: motion is
/// finite, under a second, and never gates the primary action.
const Duration kOnboardingEntranceDuration = Duration(milliseconds: 600);
const Curve kOnboardingEntranceCurve = Curves.easeOutBack;

/// True when the platform asks for reduced motion. Slides then render their
/// settled state immediately instead of animating into it.
bool reduceMotion(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
}

/// Progress of one step of a staged sequence, as a 0..1 fraction of the
/// sequence's own 0..1 progress.
///
/// Staging by progress rather than by timers is what lets an interactive swipe
/// be scrubbed backwards: the reveal follows the finger in both directions.
double stageProgress(double progress, double start, double end) => ((progress - start) / (end - start)).clamp(0.0, 1.0);
