import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../../theme.dart';
import 'adjustment_cell_layout.dart';
import 'adjustment_table_shared.dart';

class AdjustmentTableCell extends StatelessWidget {
  final double maxWidth;
  final Adjustment adjustment;
  final dynamic value;
  final dynamic previousValue;
  final bool highlightInitialValues;
  final bool isError;

  const AdjustmentTableCell({
    super.key,
    required this.adjustment,
    required this.value,
    required this.previousValue,
    required this.highlightInitialValues,
    this.isError = false,
    this.maxWidth = 120.0,
  });

  Tooltip _cellToolTip({
    required BuildContext context,
    required bool valueHasChanged,
    required Color? highlightColor,
    required Widget child,
  }) {
    return infoTooltip(
      context: context,
      child: child,
      message: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: adjustment.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (adjustment is StepAdjustment)
                    TextSpan(
                      text: "  [${Adjustment.formatValue((adjustment as StepAdjustment).min)}..${Adjustment.formatValue((adjustment as StepAdjustment).max)}]",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Adjustment.formatValue(value),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: (highlightInitialValues ? highlightColor : null) ?? Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: adjustment.unitSuffix(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ]
              ),
            ),
            if (valueHasChanged)
              Text(
                Adjustment.formatValue(previousValue) + adjustment.unitSuffix(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                  decoration: TextDecoration.lineThrough,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = cellDisplayText(adjustment, value, previousValue);
    final bool valueHasChanged = display.hasChange;
    final bool valueIsInitial = previousValue == null;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    final Color? highlightColor = isError
        ? Theme.of(context).colorScheme.error
        : (highlightInitialValues
            ? (valueIsInitial
                ? (highlights?.initial ?? Colors.green)
                : (valueHasChanged ? (highlights?.changed ?? Colors.orange) : null))
            : null);

    // The tooltip renders on colorScheme.inverseSurface, which is the opposite
    // brightness of the current theme, so it needs the highlight variant made
    // for that opposite brightness rather than the current theme's.
    final tooltipHighlights = Theme.of(context).brightness == Brightness.dark
        ? ValueHighlightColors.light
        : ValueHighlightColors.dark;
    final Color? tooltipHighlightColor = isError
        ? null
        : (highlightInitialValues
            ? (valueIsInitial
                ? tooltipHighlights.initial
                : (valueHasChanged ? tooltipHighlights.changed : null))
            : null);

    final finalValueWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // The Row is necessary to ensure the SingleChildScrollView's child
        // (the Text.rich) only takes the space it needs when it's shorter
        // than _max_value_width.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: cellValueRowSpacing,
        children: [
          Flexible(
            child: Text(
              display.value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: highlightColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
            ),
          ),
          if (valueHasChanged) ...[
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                display.change!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  decoration: display.changeDecoration,
                  decorationThickness: 2,
                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
              ),
            ),
          ],
          if (adjustment.unit != null)
            Text(
              adjustment.unit!.label,
              style: isError
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
        ],
      ),
    );

    final finalLabelWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The Row is necessary to ensure the SingleChildScrollView's child
      // (the Text.rich) only takes the space it needs when it's shorter
      // than _max_value_width.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            adjustment.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    return _cellToolTip(
      context: context,
      highlightColor: tooltipHighlightColor,
      valueHasChanged: valueHasChanged,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: cellHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            finalLabelWidget,
            finalValueWidget,
          ],
        ),
      ),
    );
  }
}
