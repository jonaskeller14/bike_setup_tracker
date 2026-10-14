import 'package:flutter/material.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/setup_guide.dart';
import '../theme.dart';

/// How the rider's value relates to a recommendation.
enum GuideStatusKind {
  /// The recommended value itself.
  matches,

  /// Within the published band or the tolerance around the recommendation.
  inRange,

  /// Outside both.
  off,

  /// No value entered yet.
  notSet,

  /// The guide's value doesn't fit the rider's adjuster.
  unavailable,
}

class GuideStatus {
  final GuideStatusKind kind;

  /// "Matches", "In range", "+6 psi", "Not set", "Can't apply".
  final String label;

  /// "In range: 72–80 psi" for a value that is off, so the rider knows how far
  /// to go; null where [label] says it all.
  final String? detail;

  const GuideStatus(this.kind, this.label, {this.detail});

  /// Null for a recommendation without any value, whose reason the detail text
  /// already gives.
  static GuideStatus? of(GuideRecommendation recommendation) {
    final adjustment = recommendation.adjustment;
    if (recommendation.value == null) {
      return recommendation.unappliedValue == null ? null : const GuideStatus(GuideStatusKind.unavailable, "Can't apply");
    }
    final deviation = recommendation.deviation;
    if (deviation == null) return const GuideStatus(GuideStatusKind.notSet, "Not set");
    if (deviation.exact) return const GuideStatus(GuideStatusKind.matches, "Matches");

    final delta = deviation.delta == null ? null : "${guideSignedDelta(deviation.delta!)}${adjustment.unitSuffix()}";
    final band = guideBandText(recommendation);
    if (deviation.onGuide) return const GuideStatus(GuideStatusKind.inRange, "In range");
    return GuideStatus(GuideStatusKind.off, delta ?? "Differs", detail: band == null ? null : "In range: $band");
  }

  IconData get icon => switch (kind) {
    GuideStatusKind.matches => Icons.check_circle,
    GuideStatusKind.inRange => Icons.check_circle_outline,
    GuideStatusKind.off => Icons.error_outline,
    GuideStatusKind.notSet => Icons.radio_button_unchecked,
    GuideStatusKind.unavailable => Icons.warning_amber_rounded,
  };

  Color color(BuildContext context) {
    final theme = Theme.of(context);
    final highlights = theme.extension<ValueHighlightColors>();
    return switch (kind) {
      GuideStatusKind.matches || GuideStatusKind.inRange => highlights?.initial ?? theme.colorScheme.primary,
      GuideStatusKind.off => highlights?.changed ?? theme.colorScheme.tertiary,
      GuideStatusKind.notSet => theme.colorScheme.onSurfaceVariant,
      GuideStatusKind.unavailable => theme.colorScheme.error,
    };
  }
}

/// [status]'s icon and label, coloured by how close the value is.
class GuideStatusBadge extends StatelessWidget {
  final GuideStatus status;

  /// Overrides the status colour, e.g. on the tooltip's inverse surface.
  final Color? color;

  const GuideStatusBadge(this.status, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? status.color(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(status.icon, size: (style?.fontSize ?? 12) + 2, color: color),
        Flexible(child: Text(status.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// [GuideStatusBadge] on a translucent pill of the status colour.
class GuideStatusPill extends StatelessWidget {
  final GuideStatus status;

  const GuideStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
      ),
      child: Container(
        key: ValueKey((status.kind, status.label)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: GuideStatusBadge(status),
      ),
    );
  }
}

String guideValueText(Adjustment adjustment, AdjustmentValue value) => switch (value) {
  NumericalValue() || StepValue() => "${value.display}${adjustment.unitSuffix()}",
  _ => value.display,
};

String guideSignedDelta(double delta) {
  final rounded = double.parse(delta.toStringAsFixed(1));
  final text = rounded == rounded.roundToDouble() ? rounded.abs().round().toString() : rounded.abs().toString();
  return "${rounded < 0 ? '-' : '+'}$text";
}

/// "72–80 psi": the values that count as on guide; null where only the
/// recommended value does.
String? guideBandText(GuideRecommendation recommendation) {
  final band = recommendation.band;
  if (band == null) return null;
  String number(double value) {
    final rounded = double.parse(value.toStringAsFixed(1));
    return rounded == rounded.roundToDouble() ? rounded.round().toString() : rounded.toString();
  }

  return "${number(band.min)}–${number(band.max)}${recommendation.adjustment.unitSuffix()}";
}
