import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';

class AdjustmentTypeIcon extends StatelessWidget {
  final Adjustment adjustment;
  final double size;
  final Color? color;

  const AdjustmentTypeIcon(this.adjustment, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final base = Icon(adjustment.getIconData(), size: size, color: color);
    if (adjustment is! SagAdjustment) return base;

    // A small travel glyph nudged into the top-left corner, in the same colour
    // as the base, so sag reads as "a specialized numerical".
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          base,
          Positioned(
            left: -size * 0.125,
            top: -size * 0.125,
            child: Icon(SagAdjustment.badgeIconData, size: size * 0.46, color: color),
          ),
        ],
      ),
    );
  }
}
