import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../models/adjustment.dart';

class SetStepAdjustmentWidget extends StatelessWidget {
  final StepAdjustment adjustment;
  final double? initialValue;
  final double value;
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
    onChanged(value-adjustment.step);
    onChangedEnd(value-adjustment.step);
  }

  void onPressedPlusButton() {
    onChanged(value+adjustment.step);
    onChangedEnd(value+adjustment.step);
  }

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor; 
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    final sliderDivisions = ((adjustment.max - adjustment.min) / adjustment.step).floor();
    final sliderMax = (adjustment.min + sliderDivisions * adjustment.step).toDouble();
    
    int nLabels = sliderDivisions;
    int sliderMinorTicksPerInterval = 0;
    while (true) {
      if (nLabels > 5) {
        nLabels = (nLabels / 2).floor();
        sliderMinorTicksPerInterval = sliderMinorTicksPerInterval * 2 + 1;
        continue;
      }
      break;
    }
    int sliderInterval = sliderMinorTicksPerInterval > 0 ? adjustment.step * (sliderMinorTicksPerInterval + 1) : adjustment.step;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? highlightColor?.withValues(alpha: 0.08) : null,
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
                Icon(Icons.format_list_numbered, color: highlightColor),
                SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      adjustment.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
                    ),
                  ),
                ),
              ],
            )
          ),
          if (adjustment.visualization == StepAdjustmentVisualization.slider)
            Flexible(
              flex: 3,
              child: SfSliderTheme(
                data: SfSliderThemeData(
                  thumbRadius: 15,
                  tooltipTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,)
                ),
                child: SfSlider(
                  min: adjustment.min.toDouble(),
                  max: sliderMax,
                  value: value,
                  thumbShape: CustomValueThumbShape(Theme.of(context).colorScheme.primary),
                  showLabels: true,
                  interval: sliderInterval.toDouble(),
                  showTicks: true,
                  stepSize: adjustment.step.toDouble(),
                  minorTicksPerInterval: sliderMinorTicksPerInterval,
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
          if (adjustment.visualization == StepAdjustmentVisualization.minusButtonValuePlusButton)
            Flexible(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 20,
                children: [
                  FilledButton(
                    onPressed: value - adjustment.step >= adjustment.min ? onPressedMinusButton : null,
                    child: Text("- ${adjustment.step}", style: TextStyle(fontFamily: 'monospace')),
                  ),
                  Text(value.toInt().toString(), style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  FilledButton(
                    onPressed: value + adjustment.step <= adjustment.max ? onPressedPlusButton : null,
                    child: Text("+ ${adjustment.step}", style: TextStyle(fontFamily: 'monospace')),
                  )
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

  const CustomValueThumbShape(
    this.primaryColor,
  );
  
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
        color: Colors.white,
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
