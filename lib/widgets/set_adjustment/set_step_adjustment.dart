import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../models/adjustment/adjustment.dart';

class SetStepAdjustmentWidget extends StatelessWidget {
  final StepAdjustment adjustment;
  final double? initialValue;
  final double? value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangedEnd;
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

  @override
  Widget build(BuildContext context) {
    bool isChanged = false;
    bool isInitial = false;
    Color? highlightColor;
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    }

    final sliderDivisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final sliderMax = (adjustment.min + sliderDivisions * adjustment.step).toDouble();
    final sliderInterval = sliderMax - adjustment.min;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isChanged
          ? BoxDecoration(color: highlightColor?.withValues(alpha: 0.08))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(Icons.stairs_outlined, color: highlightColor),
                SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: adjustment.notes == null 
                        ? Text(adjustment.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor))
                        : Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            showDuration: const Duration(seconds: 5),
                            message: adjustment.notes!,
                            child: Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
                                children: [
                                  TextSpan(text: adjustment.name),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Icon(
                                          Icons.info_outline,
                                          color: highlightColor,
                                          size: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            )
          ),
          if (value == null)
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => onChanged(adjustment.min.toDouble()),
                  child: const Text("Set value"),
                ),
              ),
            ),
          if (value != null && (adjustment.visualization == StepAdjustmentVisualization.slider || adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial || adjustment.visualization == StepAdjustmentVisualization.sliderWithCounterclockwiseDial))
            Flexible(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: SfSliderTheme(
                      data: SfSliderThemeData(
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
                        minorTicksPerInterval: sliderDivisions - 1,
                        enableTooltip: true,
                        tooltipShape: SfPaddleTooltipShape(),
                        onChanged: (dynamic newValue) {
                          onChanged(newValue);
                        },
                        onChangeEnd: (dynamic newValue) {
                          onChangedEnd(newValue);
                        },
                      ),
                    ),
                  ),
                  if (adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial || adjustment.visualization == StepAdjustmentVisualization.sliderWithCounterclockwiseDial)
                    RotaryKnob(
                      key: const ValueKey('RotaryKnob'),
                      value: value!,
                      min: adjustment.min.toDouble(),
                      max: sliderMax,
                      numberOfTicks: sliderDivisions + 1,
                      clockwise: adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial,
                      primaryColor: Theme.of(context).colorScheme.primary,
                      onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                ],
              ),
            ),
          if (value != null && (adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButton || adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial || adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial))
            Flexible(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: value! - adjustment.step >= adjustment.min ? onPressedMinusButton : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: const Size(48, 36), 
                    ),
                    child: Text("- ${adjustment.step}"),
                  ),
                  Text(value!.toInt().toString(), style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  FilledButton(
                    onPressed: value! + adjustment.step <= adjustment.max ? onPressedPlusButton : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: const Size(48, 36), 
                    ),
                    child: Text("+ ${adjustment.step}"),
                  ),
                  if (adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial || adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial)
                    RotaryKnob(
                      key: const ValueKey('RotaryKnob'),
                      value: value!,
                      min: adjustment.min.toDouble(),
                      max: sliderMax,
                      numberOfTicks: sliderDivisions + 1,
                      clockwise: adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial,
                      primaryColor: Theme.of(context).colorScheme.primary,
                      onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                ],
              ),
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
  final double min;
  final double max;
  final Color primaryColor;
  final Color onPrimaryColor;
  final int numberOfTicks;
  final bool clockwise;

  const RotaryKnob({
    required super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.numberOfTicks,
    required this.clockwise,
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = (value - min) / (max - min); // 0..1
    final angleDeg = (normalizedValue * 270.0); // in degrees
    final angleRad = angleDeg * (pi / 180.0);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: angleRad, end: angleRad),
      duration: const Duration(milliseconds: 100), // Quick, continuous-feeling animation
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(50, 50),
          painter: KnobPainter(
            rotationRadians: value,
            primaryColor: primaryColor,
            onPrimaryColor: onPrimaryColor,
            tickColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            numberOfTicks: numberOfTicks,
            clockwise: clockwise,
          ),
        );
      },
    );
  }
}

class KnobPainter extends CustomPainter {
  final double rotationRadians;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color tickColor;
  final int numberOfTicks;
  final bool clockwise;

  KnobPainter({
    required this.rotationRadians,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.tickColor,
    required this.numberOfTicks,
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
        
    for (int i = 0; i < numberOfTicks; i++) {
      final angle = startAngleRad + sweepAngleRad * (i / (numberOfTicks - 1));
      
      final x1 = center.dx + tickRadius * 0.9 * cos(angle);
      final y1 = center.dy + tickRadius * 0.9 * sin(angle);
      final x2 = center.dx + tickRadius * cos(angle);
      final y2 = center.dy + tickRadius * sin(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
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
    return oldDelegate.rotationRadians != rotationRadians;
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
