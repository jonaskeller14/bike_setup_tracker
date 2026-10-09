import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';

/// A step adjustment's range as one pip per step, filled up to [value], so a
/// change reads as a count of clicks. Where the pips would get too thin to
/// count, the range is drawn as one continuous bar instead.
class StepPips extends StatelessWidget {
  static const double height = 8;
  static const double gap = 2;

  /// The narrowest pip still worth drawing; below it the bar takes over.
  static const double minPipWidth = 4;

  final StepAdjustment adjustment;
  final StepValue? value;

  /// Picks out the steps between this and [value] in [changeColor]: solid for
  /// an increase, faded for a decrease. Null draws no change.
  final StepValue? previousValue;
  final Color color;
  final Color? changeColor;

  const StepPips({
    super.key,
    required this.adjustment,
    required this.value,
    this.previousValue,
    required this.color,
    this.changeColor,
  });

  /// Whether [divisions] pips fit into [width] at [minPipWidth] or wider.
  static bool fitsPips(double width, int divisions) =>
      divisions > 0 && (width - gap * (divisions - 1)) / divisions >= minPipWidth;

  @override
  Widget build(BuildContext context) {
    final divisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    int? stepsOf(StepValue? stepValue) => stepValue == null
        ? null
        : ((stepValue.value - adjustment.min) / adjustment.step).round().clamp(0, math.max(divisions, 0));

    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _StepPipsPainter(
          divisions: divisions,
          current: stepsOf(value),
          previous: stepsOf(previousValue),
          fillColor: color,
          changeColor: changeColor ?? color,
          trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _StepPipsPainter extends CustomPainter {
  final int divisions;
  final int? current;
  final int? previous;
  final Color fillColor;
  final Color changeColor;
  final Color trackColor;

  _StepPipsPainter({
    required this.divisions,
    required this.current,
    required this.previous,
    required this.fillColor,
    required this.changeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final current = this.current;
    final previous = this.previous;
    final low = current == null || previous == null ? current ?? 0 : math.min(current, previous);
    final high = current == null || previous == null ? current ?? 0 : math.max(current, previous);
    // An increase is drawn solid, a decrease as the faded stretch taken away.
    final stretchColor = current != null && previous != null && current < previous
        ? changeColor.withValues(alpha: 0.35)
        : changeColor;

    if (StepPips.fitsPips(size.width, divisions)) {
      final pipWidth = (size.width - StepPips.gap * (divisions - 1)) / divisions;
      for (var i = 0; i < divisions; i++) {
        final rect = Rect.fromLTWH(i * (pipWidth + StepPips.gap), 0, pipWidth, size.height);
        final color = i < low
            ? fillColor
            : i < high
            ? stretchColor
            : trackColor;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = color);
      }
      return;
    }

    double x(int steps) => divisions <= 0 ? size.width : size.width * steps / divisions;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)));
    canvas.drawRect(Offset.zero & size, Paint()..color = trackColor);
    if (current != null) {
      if (high > low) canvas.drawRect(Rect.fromLTRB(0, 0, x(high), size.height), Paint()..color = stretchColor);
      canvas.drawRect(Rect.fromLTRB(0, 0, x(low), size.height), Paint()..color = fillColor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StepPipsPainter oldDelegate) {
    return oldDelegate.divisions != divisions ||
        oldDelegate.current != current ||
        oldDelegate.previous != previous ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.changeColor != changeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
