import 'package:flutter/material.dart';

class CurrentSetupHighlight extends StatelessWidget {
  static const double barWidth = 4;

  static const double fillAlpha = 0.08;

  static Color opaqueFill(ColorScheme scheme) =>
      Color.alphaBlend(scheme.primary.withValues(alpha: fillAlpha), scheme.surface);

  final Widget child;
  final double barLeft;
  final EdgeInsets padding;

  const CurrentSetupHighlight({
    super.key,
    required this.child,
    this.barLeft = 0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: primary.withValues(alpha: fillAlpha)),
        ),
        Padding(padding: padding, child: child),
        Positioned(
          left: barLeft,
          top: 0,
          bottom: 0,
          width: barWidth,
          child: ColoredBox(color: primary),
        ),
      ],
    );
  }
}
