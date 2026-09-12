import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';

Color resolveDialColor(BuildContext context, StepAdjustmentDialColor color) {
  final primary = Theme.of(context).colorScheme.primary;
  if (color == StepAdjustmentDialColor.primary) return primary;
  return chartColors(primary, StepAdjustmentDialColor.values.length)[color.index];
}

Color resolveDialOnColor(BuildContext context, Color dialColor) {
  final colorScheme = Theme.of(context).colorScheme;
  if (dialColor == colorScheme.primary) return colorScheme.onPrimary;
  return ThemeData.estimateBrightnessForColor(dialColor) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

class RotaryKnob extends StatelessWidget {
  final double value;
  final int? initialValue;
  final double min;
  final double max;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color tickColor;
  final int numberOfTicks;
  final bool clockwise;
  final bool showAllTicks;
  final bool small;

  const RotaryKnob({
    required super.key,
    required this.value,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.numberOfTicks,
    required this.clockwise,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.tickColor,
    this.showAllTicks = true,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = (value - min) / (max - min); // 0..1
    final angleDeg = normalizedValue * 270.0; // in degrees
    final angleRad = angleDeg * (pi / 180.0);

    // Normalized tick positions (0..1 along the sweep). For huge ranges we draw
    // only the endpoints; otherwise one tick per division.
    final List<double> tickFractions = showAllTicks
        ? List<double>.generate(numberOfTicks, (i) => i / (numberOfTicks - 1))
        : const [0.0, 1.0];
    final double? initialFraction = initialValue == null
        ? null
        : ((initialValue! - min) / (max - min)).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: angleRad, end: angleRad),
      duration: const Duration(milliseconds: 100), // Quick, continuous-feeling animation
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(50, 50),
          painter: KnobPainter(
            rotationRadians: value,
            tickFractions: tickFractions,
            initialFraction: initialFraction,
            primaryColor: primaryColor,
            onPrimaryColor: onPrimaryColor,
            tickColor: tickColor,
            clockwise: clockwise,
            small: small,
          ),
        );
      },
    );
  }
}

class KnobPainter extends CustomPainter {
  final double rotationRadians;
  /// Normalized (0..1) positions of the ticks to draw along the sweep.
  final List<double> tickFractions;
  /// Normalized (0..1) position of the initial-value tick, drawn highlighted.
  final double? initialFraction;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color tickColor;
  final bool clockwise;
  final bool small;

  KnobPainter({
    required this.rotationRadians,
    required this.tickFractions,
    required this.initialFraction,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.tickColor,
    required this.clockwise,
    required this.small,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startAngleRad = clockwise ? 3 * pi / 4 :  1/4 * pi;
    final double sweepAngleRad = (clockwise ? 1 : -1) * 270 * (pi / 180.0);


    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final knobRadius = radius * (small ? 0.5 : 0.8);
    final tickRadius = radius * 0.95;
    final tickInnerFactor = small ? 0.67 : 0.9;

    // 1. Draw Ticks
    final tickPaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final initialTickPaint = Paint()
      ..color = primaryColor
      ..style = tickPaint.style
      ..strokeWidth = tickPaint.strokeWidth
      ..strokeCap = tickPaint.strokeCap;

    void drawTick(double fraction, Paint paint) {
      final angle = startAngleRad + sweepAngleRad * fraction;
      final x1 = center.dx + tickRadius * tickInnerFactor * cos(angle);
      final y1 = center.dy + tickRadius * tickInnerFactor * sin(angle);
      final x2 = center.dx + tickRadius * cos(angle);
      final y2 = center.dy + tickRadius * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    for (final fraction in tickFractions) {
      drawTick(fraction, tickPaint);
    }
    // Draw the initial-value tick on top so it stays visible at its exact
    // position even when the surrounding step ticks are hidden.
    if (initialFraction != null) {
      drawTick(initialFraction!, initialTickPaint);
    }

    // -----------------------------------------------------------------
    // START: ROTATING SECTION
    // -----------------------------------------------------------------
    canvas.save();
    
    final double normalizedRotation = rotationRadians / sweepAngleRad.abs(); // Normalized 0 to 1
    
    // The knob's "zero" position is assumed to be pointing up (0 rotation).
    canvas.translate(center.dx, center.dy);
    canvas.rotate(startAngleRad + pi / 2 + normalizedRotation * sweepAngleRad);
    canvas.translate(-center.dx, -center.dy);
    

    // --- Draw the Scalloped Knob Body (Now Rotates) ---
    final knobPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
        
    final Path knobPath = _createScallopedKnobPath(
      center: center,
      mainRadius: knobRadius,
      numScallops: 6, 
      smallCircleRadius: knobRadius / 2.5,
      radialOffset: knobRadius + knobRadius / 2.5 * 0.5,
    );
      
    canvas.drawPath(knobPath, knobPaint);

    // --- Draw the Indicator Line (Now Rotates with the knob) ---
    final indicatorPaint = Paint()
      ..color = onPrimaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final xStart = center.dx;
    final yStart = center.dy;

    final xEnd = center.dx;
    final yEnd = center.dy - 0.85 * knobRadius;
    
    canvas.drawLine(Offset(xStart, yStart), Offset(xEnd, yEnd), indicatorPaint);

    // -----------------------------------------------------------------
    // END: ROTATING SECTION
    // -----------------------------------------------------------------
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant KnobPainter oldDelegate) {
    return oldDelegate.rotationRadians != rotationRadians ||
        oldDelegate.initialFraction != initialFraction ||
        oldDelegate.tickFractions.length != tickFractions.length ||
        oldDelegate.small != small ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.onPrimaryColor != onPrimaryColor ||
        oldDelegate.tickColor != tickColor;
  }

  Path _createScallopedKnobPath({required Offset center, required double mainRadius, required int numScallops, required double smallCircleRadius, required double radialOffset}) {
    final Path mainCirclePath = Path()..addOval(
      Rect.fromCircle(center: center, radius: mainRadius)
    );

    final Path subtractionPath = Path();
    final double angleStep = 2 * pi / numScallops;

    for (int i = 0; i < numScallops; i++) {
      final double angle = i * angleStep;
      final double centerX = center.dx + radialOffset * cos(angle);
      final double centerY = center.dy + radialOffset * sin(angle);
      final Offset smallCircleCenter = Offset(centerX, centerY);
      subtractionPath.addOval(
        Rect.fromCircle(center: smallCircleCenter, radius: smallCircleRadius)
      );
    }

    final Path finalPath = Path.combine(
      PathOperation.difference,
      mainCirclePath,
      subtractionPath,
    );

    return finalPath;
  }
}
