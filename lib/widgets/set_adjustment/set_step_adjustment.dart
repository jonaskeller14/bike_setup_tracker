import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';
import 'set_step_adjustment_dial.dart';

class SetStepAdjustmentWidget extends StatelessWidget {
  static const int maxRenderedTicks = 50;
  final StepAdjustment adjustment;
  final double? initialValue;
  final double? value;
  final ValueChanged<double?> onChanged;
  final ValueChanged<double?> onChangedEnd;
  final bool highlighting;

  /// The value is not pre-filled from [initialValue], so it may be left unset
  /// and stays clearable even when a previous value exists.
  final bool optional;

  const SetStepAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    required this.onChangedEnd,
    this.highlighting = true,
    this.optional = false,
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
      isChanged = value == null ? false : initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    }

    final sliderDivisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final sliderMax = (adjustment.min + sliderDivisions * adjustment.step).toDouble();
    final sliderInterval = sliderMax - adjustment.min;

    // Cap the rendered ticks
    final bool showStepTicks = sliderDivisions <= maxRenderedTicks;
    final int knobTicks = showStepTicks ? sliderDivisions + 1 : maxRenderedTicks + 1;
    final dialColor = resolveDialColor(context, adjustment.dialColor);
    
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
            child: AdjustmentIconNameNotes(adjustment: adjustment, color: highlightColor),
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
                        primaryColor: dialColor,
                        onPrimaryColor: resolveDialOnColor(context, dialColor),
                        tickColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        small: adjustment.dialSize == StepAdjustmentDialSize.small,
                      ),
                    if (isInitial || optional)
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
                    if (isInitial || optional)
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
                        primaryColor: dialColor,
                        onPrimaryColor: resolveDialOnColor(context, dialColor),
                        tickColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        small: adjustment.dialSize == StepAdjustmentDialSize.small,
                      ),
                      if (isInitial || optional)
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
