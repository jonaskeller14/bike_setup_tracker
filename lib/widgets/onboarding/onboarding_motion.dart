import 'package:flutter/material.dart';

/// Shared timings for onboarding entrances. One rule for every slide: motion is
/// finite, under a second, and never gates the primary action.
const Duration kOnboardingEntranceDuration = Duration(milliseconds: 600);
const Curve kOnboardingEntranceCurve = Curves.easeOutBack;

/// Delay between the items of a staged entrance, small enough that even a
/// four-item row still settles inside the ~1s entrance budget.
const Duration kOnboardingStageDelay = Duration(milliseconds: 90);

const double _kEntranceRise = 28;
const double _kEntranceScale = 0.85;

/// True when the platform asks for reduced motion. Slides then render their
/// settled state immediately instead of animating into it.
bool reduceMotion(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
}

/// The entrance every slide shares: a rise, a fade and a scale with a gentle
/// overshoot that settles and then holds still.
///
/// [progress] is driven by an animation rather than read from build time, so an
/// incidental rebuild — a theme change, the keyboard, a resize — repaints the
/// frame the entrance is on instead of replaying it from the start.
Widget onboardingEntrance({required double progress, required Widget child}) {
  if (progress >= 1) return child;

  final settle = kOnboardingEntranceCurve.transform(progress);
  return Opacity(
    // The back curve overshoots past 1; opacity gets its own curve rather than
    // an out-of-range value.
    opacity: Curves.easeOut.transform(progress),
    child: Transform.translate(
      offset: Offset(0, (1 - settle) * _kEntranceRise),
      child: Transform.scale(
        scale: _kEntranceScale + (1 - _kEntranceScale) * settle,
        child: child,
      ),
    ),
  );
}

/// Progress of one step of a staged sequence, as a 0..1 fraction of the
/// sequence's own 0..1 progress.
///
/// Staging by progress rather than by timers is what lets an interactive swipe
/// be scrubbed backwards: the reveal follows the finger in both directions.
double stageProgress(double progress, double start, double end) => ((progress - start) / (end - start)).clamp(0.0, 1.0);

/// Reveals [child] by growing its slot and fading it in, from [progress] alone.
///
/// Timer-free like [stageProgress]: a reveal driven this way can be scrubbed,
/// fast-forwarded or rendered settled without ever desynchronising from what
/// the user sees.
Widget onboardingReveal({
  required double progress,
  required Widget child,
  Alignment alignment = Alignment.bottomCenter,
}) {
  if (progress >= 1) return child;
  if (progress <= 0) return const SizedBox.shrink();

  return ClipRect(
    child: Align(
      alignment: alignment,
      heightFactor: progress,
      child: Opacity(opacity: progress, child: child),
    ),
  );
}
