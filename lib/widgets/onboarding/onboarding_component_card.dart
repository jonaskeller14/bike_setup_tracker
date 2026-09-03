import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/bike_icons.dart';
import '../../models/adjustment/adjustment.dart';
import 'onboarding_motion.dart';

/// The example component card shown on slide 3.
///
/// The same widget is rendered by the flight that carries the card over from
/// slide 2, so the transition ends on exactly the card the slide keeps — there
/// is no second, drifting copy of this layout.
///
/// [reveal] opens the card itself: the icon leads (it is the element that
/// flew), then the title and the divider. [adjustments] then fills the rows in,
/// staggered, once the card has landed. Hidden steps keep their layout slot, so
/// the card never reflows while it opens.
class OnboardingComponentCard extends StatelessWidget {
  const OnboardingComponentCard({super.key, this.reveal = 1, this.adjustments = 1});

  final double reveal;
  final double adjustments;

  static const double padding = 16;
  static const double iconSize = 40;

  Widget _staged({required double start, required double end, required Widget child}) =>
      _stagedBy(reveal, start: start, end: end, child: child);

  Widget _stagedBy(double value, {required double start, required double end, required Widget child}) {
    if (value >= 1) return child;
    final progress = stageProgress(value, start, end);
    return Opacity(
      opacity: progress,
      child: Transform.translate(offset: Offset(0, (1 - progress) * 8), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Icon(BikeIcons.fork, size: iconSize)),
          _staged(
            start: 0.35,
            end: 0.70,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "Suspension Fork",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          _staged(start: 0.60, end: 0.90, child: const Divider(height: 24)),
          _stagedBy(
            adjustments,
            start: 0,
            end: 0.5,
            child: const _AdjustmentPreview(
              icon: NumericalAdjustment.iconData,
              name: "Pressure",
              type: "Numerical Adjustment",
              detail: "in PSI",
            ),
          ),
          const SizedBox(height: 8),
          _stagedBy(
            adjustments,
            start: 0.25,
            end: 0.75,
            child: const _AdjustmentPreview(
              icon: StepAdjustment.iconData,
              name: "Rebound",
              type: "Step Adjustment",
              detail: "0 to 12 Clicks",
            ),
          ),
          const SizedBox(height: 8),
          _stagedBy(
            adjustments,
            start: 0.5,
            end: 1,
            child: const _AdjustmentPreview(
              icon: BooleanAdjustment.iconData,
              name: "Lockout",
              type: "On/Off Adjustment",
              detail: "Open or Firm",
            ),
          ),
        ],
      ),
    );
  }
}

/// The card in flight between slide 2's component row and slide 3.
///
/// The contents are laid out at the destination card's size and revealed
/// through the growing, clipping box, so nothing reflows or overflows at the
/// intermediate sizes the flight passes through.
class OnboardingComponentCardFlight extends StatelessWidget {
  const OnboardingComponentCardFlight({
    super.key,
    required this.progress,
    required this.targetSize,
  });

  final double progress;
  final Size targetSize;

  static const double borderRadius = 12;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // The flight paints above both pages, so without a lift it composites flat
    // against whichever page scrolls beneath it. Elevation peaks mid-flight and
    // settles onto the destination card's own elevation.
    final lift = math.sin(math.pi * progress);

    return Material(
      clipBehavior: Clip.antiAlias,
      elevation: progress + 8 * lift,
      color: Color.lerp(colors.surface, colors.surfaceContainerLow, progress),
      surfaceTintColor: colors.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        // Slide 2's card is outlined and slide 3's is filled; fading the
        // outline out keeps either endpoint from looking like a mismatch.
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 1 - progress)),
      ),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxWidth: targetSize.width,
        maxHeight: targetSize.height,
        child: SizedBox.fromSize(
          size: targetSize,
          // The rows stay empty in flight; slide 3 fills them once the card has
          // landed, so the reveal is not rushed through the last of the swipe.
          child: OnboardingComponentCard(reveal: progress, adjustments: 0),
        ),
      ),
    );
  }
}

class _AdjustmentPreview extends StatelessWidget {
  const _AdjustmentPreview({
    required this.icon,
    required this.name,
    required this.type,
    required this.detail,
  });

  final IconData icon;
  final String name;
  final String type;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(type, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
