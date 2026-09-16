import 'package:flutter/material.dart';

/// Background/foreground pairing for a themed long-press tooltip. Callers
/// pick the variant that contrasts with whatever the tooltip is triggered
/// from (e.g. a tinted card vs. a plain surface).
class TooltipStyle {
  final Color background;
  final Color foreground;

  const TooltipStyle({required this.background, required this.foreground});

  /// Inverted surface: contrasts with tinted/light containers (e.g. the
  /// compact adjustment display's grey owner card).
  factory TooltipStyle.inverse(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TooltipStyle(background: colorScheme.inverseSurface, foreground: colorScheme.onInverseSurface);
  }

  /// Elevated surface: for tooltips triggered from plain containers where an
  /// inverted popup would look out of place.
  factory TooltipStyle.surface(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TooltipStyle(background: colorScheme.surfaceContainerHighest, foreground: colorScheme.onSurface);
  }
}
