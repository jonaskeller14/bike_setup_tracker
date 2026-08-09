import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import 'set_adjustment.dart';

class SetStepAdjustmentWidget extends StatelessWidget {
  static const int maxRenderedTicks = 50;
  final StepAdjustment adjustment;
  final double? initialValue;
  final double? value;
  final ValueChanged<double?> onChanged;
  final ValueChanged<double?> onChangedEnd;
  final bool highlighting;

  const SetStepAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    required this.onChangedEnd,
    this.highlighting = true,
  });

  void onPressedMinusButton() {
    onChanged(value!-adjustment.step);
    onChangedEnd(value!-adjustment.step);
  }

  void onPressedPlusButton() {
    onChanged(value!+adjustment.step);
    onChangedEnd(value!+adjustment.step);
  }

  void onLongPressedMinusButton() {
    final minValue = adjustment.min.toDouble();
    onChanged(minValue);
    onChangedEnd(minValue);
  }

  void onLongPressedPlusButton() {
    final divisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final maxValue = (adjustment.min + divisions * adjustment.step).toDouble();
    onChanged(maxValue);
    onChangedEnd(maxValue);
  }

  @override
  Widget build(BuildContext context) {
    bool isChanged = false;
    bool isInitial = false;
    Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    }

    final sliderDivisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final sliderMax = (adjustment.min + sliderDivisions * adjustment.step).toDouble();
    final sliderInterval = sliderMax - adjustment.min;

    // Cap the rendered ticks
    final bool showStepTicks = sliderDivisions <= maxRenderedTicks;
    final int knobTicks = showStepTicks ? sliderDivisions + 1 : maxRenderedTicks + 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? (isInitial ? highlights?.initialFill ?? Colors.green.withValues(alpha: 0.08) : highlights?.changedFill ?? Colors.orange.withValues(alpha: 0.08)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(StepAdjustment.iconData, color: highlightColor),
                const SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          if (value == null)
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {onChanged(adjustment.min.toDouble()); onChangedEnd(adjustment.min.toDouble());},
                  child: const Text("Set value"),
                ),
              ),
            )
          else
            Flexible(
              flex: 3,
              child: switch (adjustment.visualization) {
                StepAdjustmentVisualization.slider ||
                StepAdjustmentVisualization.sliderWithClockwiseDial ||
                StepAdjustmentVisualization.sliderWithCounterclockwiseDial => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: SfSliderTheme(
                        data: const SfSliderThemeData(
                          thumbRadius: 15,
                          overlayRadius: 0,
                          tooltipTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,)
                        ),
                        child: SfSlider(
                          min: adjustment.min.toDouble(),
                          max: sliderMax,
                          value: value,
                          thumbShape: CustomValueThumbShape(
                            primaryColor: Theme.of(context).colorScheme.primary,
                            onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          showLabels: true,
                          interval: sliderInterval.toDouble(),
                          showTicks: true,
                          stepSize: adjustment.step.toDouble(),
                          minorTicksPerInterval: showStepTicks ? sliderDivisions - 1 : 0,
                          enableTooltip: true,
                          tooltipShape: const SfPaddleTooltipShape(),
                          onChanged: (dynamic newValue) {
                            onChanged(newValue as double?);
                          },
                          onChangeEnd: (dynamic newValue) {
                            onChangedEnd(newValue as double?);
                          },
                        ),
                      ),
                    ),
                    if (adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial || adjustment.visualization == StepAdjustmentVisualization.sliderWithCounterclockwiseDial)
                      RotaryKnob(
                        key: const ValueKey('RotaryKnob'),
                        value: value!,
                        initialValue: initialValue?.toInt(),
                        min: adjustment.min.toDouble(),
                        max: sliderMax,
                        numberOfTicks: knobTicks,
                        showAllTicks: showStepTicks,
                        clockwise: adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial,
                        primaryColor: Theme.of(context).colorScheme.primary,
                        onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    if (isInitial)
                      IconButton(
                        onPressed: () {onChanged(null); onChangedEnd(null);},
                        icon: const Icon(Icons.replay),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                StepAdjustmentVisualization.minusButtonValuePlusButton => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FilledButton(
                      onPressed: value! - adjustment.step >= adjustment.min ? onPressedMinusButton : null,
                      onLongPress: value! - adjustment.step >= adjustment.min ? onLongPressedMinusButton : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        minimumSize: const Size(48, 36),
                      ),
                      child: Text("- ${adjustment.step}"),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value!.toInt().toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: value! + adjustment.step <= adjustment.max ? onPressedPlusButton : null,
                      onLongPress: value! + adjustment.step <= adjustment.max ? onLongPressedPlusButton : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        minimumSize: const Size(48, 36),
                      ),
                      child: Text("+ ${adjustment.step}"),
                    ),
                    if (isInitial)
                      IconButton(
                        onPressed: () {onChanged(null); onChangedEnd(null);},
                        icon: const Icon(Icons.replay),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial ||
                StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: value! - adjustment.step >= adjustment.min ? onPressedMinusButton : null,
                        onLongPress: value! - adjustment.step >= adjustment.min ? onLongPressedMinusButton : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          minimumSize: const Size(48, 36),
                        ),
                        child: Text("- ${adjustment.step}"),
                      ),
                      const SizedBox(width: 6),
                      Text(value!.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: value! + adjustment.step <= adjustment.max ? onPressedPlusButton : null,
                        onLongPress: value! + adjustment.step <= adjustment.max ? onLongPressedPlusButton : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          minimumSize: const Size(48, 36),
                        ),
                        child: Text("+ ${adjustment.step}"),
                      ),
                      const SizedBox(width: 6),
                      RotaryKnob(
                        key: const ValueKey('RotaryKnob'),
                        value: value!,
                        initialValue: initialValue?.toInt(),
                        min: adjustment.min.toDouble(),
                        max: sliderMax,
                        numberOfTicks: knobTicks,
                        showAllTicks: showStepTicks,
                        clockwise: adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial,
                        primaryColor: Theme.of(context).colorScheme.primary,
                        onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      if (isInitial)
                        IconButton(
                          onPressed: () {onChanged(null); onChangedEnd(null);},
                          icon: const Icon(Icons.replay),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              },
            ),
        ],
      ),
    );
  }
}

class CustomValueThumbShape extends SfThumbShape {
  final Color primaryColor;
  final Color onPrimaryColor;

  const CustomValueThumbShape({
    required this.primaryColor,
    required this.onPrimaryColor,
  });
  
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required RenderBox? child,
    required SfSliderThemeData themeData,
    SfRangeValues? currentValues,
    dynamic currentValue,
    required Paint? paint,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required SfThumb? thumb,
  }) {
    final Canvas canvas = context.canvas;
    final String text = currentValue.toInt().toString();

    final Paint thumbPaint = Paint()..color = primaryColor;
    canvas.drawCircle(center, 15.0, thumbPaint);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: text.length <= 1 ? 16 : text.length <= 2 ? 14 : text.length <= 3 ? 12 : text.length <= 4  ? 10 : 8,
        color: onPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final Offset textCenter = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textCenter);
  }
}

class RotaryKnob extends StatelessWidget {
  final double value;
  final int? initialValue;
  final double min;
  final double max;
  final Color primaryColor;
  final Color onPrimaryColor;
  final int numberOfTicks;
  final bool clockwise;
  final bool showAllTicks;

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
    this.showAllTicks = true,
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
            tickColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            clockwise: clockwise,
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

  KnobPainter({
    required this.rotationRadians,
    required this.tickFractions,
    required this.initialFraction,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.tickColor,
    required this.clockwise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startAngleRad = clockwise ? 3 * pi / 4 :  1/4 * pi;
    final double sweepAngleRad = (clockwise ? 1 : -1) * 270 * (pi / 180.0);


    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final knobRadius = radius * 0.8;
    final tickRadius = radius * 0.95;

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
      final x1 = center.dx + tickRadius * 0.9 * cos(angle);
      final y1 = center.dy + tickRadius * 0.9 * sin(angle);
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
    final yEnd = center.dy - 0.8 * knobRadius;
    
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
        oldDelegate.tickFractions.length != tickFractions.length;
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
