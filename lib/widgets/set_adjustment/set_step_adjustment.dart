import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../utils/automation_ids.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';
import '../display_adjustment/previous_value_line.dart';
import '../display_adjustment/step_pips.dart';
import 'set_step_adjustment_dial.dart';

class SetStepAdjustmentWidget extends StatelessWidget {
  static const int maxRenderedTicks = 50;

  /// Two buttons plus room for a three-digit value between them.
  static const double _minStepperWidth = 2 * 48 + 40;

  /// Holds the knob, and below it the previous value, at a fixed width, so
  /// the buttons do not shift when the previous value first appears.
  static const double _slotWidth = 56;
  static const double _previousLineHeight = 20;
  static const double _resetWidth = 40;

  final StepAdjustment adjustment;
  final StepValue? initialValue;
  final StepValue? value;
  final ValueChanged<StepValue?> onChanged;
  final ValueChanged<StepValue?> onChangedEnd;
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
    onChanged(StepValue(value!.value - adjustment.step));
    onChangedEnd(StepValue(value!.value - adjustment.step));
  }

  void onPressedPlusButton() {
    onChanged(StepValue(value!.value + adjustment.step));
    onChangedEnd(StepValue(value!.value + adjustment.step));
  }

  void onLongPressedMinusButton() {
    final minValue = StepValue(adjustment.min);
    onChanged(minValue);
    onChangedEnd(minValue);
  }

  void onLongPressedPlusButton() {
    final divisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final maxValue = StepValue(adjustment.min + divisions * adjustment.step);
    onChanged(maxValue);
    onChangedEnd(maxValue);
  }

  /// The buttons around the value with the range as pips below them, the
  /// [knob] beside the buttons and the [previousLine] beside the pips.
  /// Narrower than its natural width the button row scales down as a whole
  /// instead of overflowing. The reset button stays outside the scaling, so it
  /// matches the slider's.
  Widget _buildStepper({
    required Color accentColor,
    required Color onAccentColor,
    required Color? valueColor,
    required Color? changeColor,
    required bool showReset,
    required Widget? knob,
    required Widget? previousLine,
  }) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: accentColor,
      foregroundColor: onAccentColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      minimumSize: const Size(48, 36),
    );
    final buttons = Row(
      children: [
        FilledButton(
          onPressed: value!.value - adjustment.step >= adjustment.min ? onPressedMinusButton : null,
          onLongPress: value!.value - adjustment.step >= adjustment.min ? onLongPressedMinusButton : null,
          style: buttonStyle,
          child: Text("- ${adjustment.step}"),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value!.value.toString(),
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: valueColor),
              ),
            ),
          ),
        ),
        FilledButton(
          onPressed: value!.value + adjustment.step <= adjustment.max ? onPressedPlusButton : null,
          onLongPress: value!.value + adjustment.step <= adjustment.max ? onLongPressedPlusButton : null,
          style: buttonStyle,
          child: Text("+ ${adjustment.step}"),
        ),
        if (knob != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: SizedBox(width: _slotWidth, child: Center(child: knob)),
          ),
      ],
    );
    final minWidth = _minStepperWidth + (knob == null ? 0 : _slotWidth + 6);
    final resetExtent = showReset ? _resetWidth + 6 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(1.0, (constraints.maxWidth - resetExtent) / minWidth);
        // With a knob the previous value spans its slot and the reset button,
        // so the pips stay level with the buttons above. Without one the
        // buttons run full width and the pips make room for the previous value.
        final Widget? trailing = knob != null
            ? SizedBox(
                width: (_slotWidth + 6) * scale + resetExtent,
                child: previousLine == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: previousLine),
                      ),
              )
            : previousLine != null
                ? ConstrainedBox(
                    constraints: BoxConstraints(minWidth: resetExtent, maxWidth: constraints.maxWidth / 2),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Align(alignment: Alignment.centerRight, widthFactor: 1, child: previousLine),
                    ),
                  )
                : showReset
                    ? SizedBox(width: resetExtent)
                    : null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Row(
              spacing: 6,
              children: [
                Expanded(
                  child: scale < 1
                      ? FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: minWidth, child: buttons))
                      : buttons,
                ),
                if (showReset)
                  IconButton(
                    onPressed: () {onChanged(null); onChangedEnd(null);},
                    icon: const Icon(Icons.replay),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            ConstrainedBox(
              // Room for the previous value up front, so the row does not grow
              // when it first appears.
              constraints: BoxConstraints(minHeight: highlighting && initialValue != null ? _previousLineHeight : 0),
              child: Row(
                children: [
                  Expanded(
                    child: StepPips(
                      adjustment: adjustment,
                      value: value,
                      previousValue: changeColor == null ? null : initialValue,
                      color: accentColor,
                      changeColor: changeColor,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ],
        );
      },
    );
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
    final accentColor = resolveStepAccentColor(context, adjustment);
    final onAccentColor = resolveDialOnColor(context, accentColor);
    final previousLine = highlighting && PreviousValueLine.appliesTo(adjustment, initialValue, value)
        ? PreviousValueLine(adjustment: adjustment, previousValue: initialValue!, value: value!)
        : null;
    final isSlider = const {
      StepAdjustmentVisualization.slider,
      StepAdjustmentVisualization.sliderWithClockwiseDial,
      StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
    }.contains(adjustment.visualization);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? (isInitial ? highlights?.initialFill ?? Colors.green.withValues(alpha: 0.08) : highlights?.changedFill ?? Colors.orange.withValues(alpha: 0.08)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 20,
            children: [
              Flexible(
                flex: 2,
                child: AdjustmentIconNameNotes(adjustment: adjustment, value: value, color: highlightColor),
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
                      onPressed: () {onChanged(StepValue(adjustment.min)); onChangedEnd(StepValue(adjustment.min));},
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
                          child: Semantics(
                            container: true,
                            identifier: AutomationIds.setAdjustment(adjustment.id),
                            child: SfSliderTheme(
                              data: SfSliderThemeData(
                                thumbRadius: 15,
                                overlayRadius: 0,
                                activeTrackColor: accentColor,
                                tooltipBackgroundColor: accentColor,
                                tooltipTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onAccentColor,)
                              ),
                              child: SfSlider(
                                min: adjustment.min.toDouble(),
                                max: sliderMax,
                                value: value!.value.toDouble(),
                                thumbShape: CustomValueThumbShape(
                                  primaryColor: accentColor,
                                  onPrimaryColor: onAccentColor,
                                ),
                                showLabels: true,
                                interval: sliderInterval.toDouble(),
                                showTicks: true,
                                stepSize: adjustment.step.toDouble(),
                                minorTicksPerInterval: showStepTicks ? sliderDivisions - 1 : 0,
                                enableTooltip: true,
                                tooltipShape: const SfPaddleTooltipShape(),
                                onChanged: (dynamic newValue) {
                                  onChanged(StepValue((newValue as double).round()));
                                },
                                onChangeEnd: (dynamic newValue) {
                                  onChangedEnd(StepValue((newValue as double).round()));
                                },
                              ),
                            ),
                          ),
                        ),
                        if (adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial || adjustment.visualization == StepAdjustmentVisualization.sliderWithCounterclockwiseDial)
                          RotaryKnob(
                            key: const ValueKey('RotaryKnob'),
                            value: value!.value.toDouble(),
                            initialValue: initialValue?.value,
                            min: adjustment.min.toDouble(),
                            max: sliderMax,
                            numberOfTicks: knobTicks,
                            showAllTicks: showStepTicks,
                            clockwise: adjustment.visualization == StepAdjustmentVisualization.sliderWithClockwiseDial,
                            primaryColor: accentColor,
                            onPrimaryColor: onAccentColor,
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
                    StepAdjustmentVisualization.minusButtonValuePlusButton ||
                    StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial ||
                    StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial => _buildStepper(
                      accentColor: accentColor,
                      onAccentColor: onAccentColor,
                      valueColor: highlightColor,
                      changeColor: isChanged && !isInitial ? highlights?.changed ?? Colors.orange : null,
                      showReset: isInitial || optional,
                      knob: adjustment.visualization.hasDial
                          ? RotaryKnob(
                              key: const ValueKey('RotaryKnob'),
                              value: value!.value.toDouble(),
                              initialValue: initialValue?.value,
                              min: adjustment.min.toDouble(),
                              max: sliderMax,
                              numberOfTicks: knobTicks,
                              showAllTicks: showStepTicks,
                              clockwise: adjustment.visualization.isClockwiseDial,
                              primaryColor: accentColor,
                              onPrimaryColor: onAccentColor,
                              tickColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              small: adjustment.dialSize == StepAdjustmentDialSize.small,
                            )
                          : null,
                      previousLine: previousLine,
                    ),
                  },
                ),
            ],
          ),
          if (isSlider && previousLine != null) previousLine,
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
