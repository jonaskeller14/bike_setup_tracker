import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../../theme.dart';
import 'adjustment_cell.dart';
import 'adjustment_cell_layout.dart';
import 'adjustment_info_tooltip.dart';

class AdjustmentCellView extends StatelessWidget {
  final AdjustmentCell cell;
  final bool highlightInitialValues;

  const AdjustmentCellView({
    super.key,
    required this.cell,
    required this.highlightInitialValues,
  });

  /// The value colour for [cell], or null for the default text colour.
  static Color? _valueColor({
    required AdjustmentCell cell,
    required ValueHighlightColors highlights,
    required ColorScheme colorScheme,
    required bool highlight,
  }) {
    return switch (cell) {
      ErrorCell() => colorScheme.error,
      ConstantCell() => null,
      InitialCell() => highlight ? highlights.initial : null,
      ChangedCell() => highlight ? highlights.changed : null,
    };
  }

  Widget _tooltipMessage(BuildContext context) {
    final theme = Theme.of(context);
    final onInverse = theme.colorScheme.onInverseSurface;
    final adjustment = cell.adjustment;
    // The tooltip renders on colorScheme.inverseSurface, which is the opposite
    // brightness of the current theme, so it needs the highlight variant made
    // for that opposite brightness rather than the current theme's.
    final Color valueColor = cell is ErrorCell
        ? onInverse
        : _valueColor(
                cell: cell,
                highlights: theme.brightness == Brightness.dark ? ValueHighlightColors.light : ValueHighlightColors.dark,
                colorScheme: theme.colorScheme,
                highlight: highlightInitialValues,
              ) ??
              onInverse;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: adjustment.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: onInverse,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (adjustment is StepAdjustment)
                TextSpan(
                  text: "  [${Adjustment.formatValue(adjustment.min)}..${Adjustment.formatValue(adjustment.max)}]",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onInverse.withValues(alpha: 0.7),
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
                text: Adjustment.formatValue(cell.value),
                style: theme.textTheme.bodyLarge?.copyWith(color: valueColor, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: adjustment.unitSuffix(),
                style: theme.textTheme.bodyLarge?.copyWith(color: onInverse),
              ),
            ],
          ),
        ),
        if (cell case ChangedCell(:final previousValue))
          Text(
            Adjustment.formatValue(previousValue) + adjustment.unitSuffix(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: onInverse.withValues(alpha: 0.7),
              decoration: TextDecoration.lineThrough,
              decorationThickness: 2,
              decorationColor: onInverse.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final display = cell.displayText;
    final bool isError = cell is ErrorCell;
    final highlights = theme.extension<ValueHighlightColors>() ?? ValueHighlightColors.light;
    final Color? valueColor = _valueColor(
      cell: cell,
      highlights: highlights,
      colorScheme: colorScheme,
      highlight: highlightInitialValues,
    );
    final changeColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    // Each line scrolls horizontally when the cell is narrower than its text;
    // the Row keeps short content at its natural width so it stays centered.
    Widget scrollableLine(List<Widget> children) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: cellValueRowSpacing,
            children: children,
          ),
        );

    return infoTooltip(
      context: context,
      message: _tooltipMessage(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: cellHorizontalPadding, vertical: 3),
        // A raised surface, lighter than the group's tinted container.
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            scrollableLine([
              Text(
                cell.adjustment.name,
                style: CellTextStyles.label(context).copyWith(
                  color: isError ? colorScheme.error : colorScheme.onSurfaceVariant,
                ),
              ),
            ]),
            scrollableLine([
              Text(
                display.value,
                style: CellTextStyles.value.copyWith(color: valueColor),
                maxLines: 1,
              ),
              if (display.hasChange)
                Transform.translate(
                  offset: const Offset(0, -5),
                  child: Text(
                    display.change!,
                    style: CellTextStyles.change.copyWith(
                      color: changeColor,
                      decoration: display.changeDecoration,
                      decorationThickness: 2,
                      decorationColor: changeColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              if (cell.adjustment.unit != null)
                Text(
                  cell.adjustment.unit!.label,
                  style: CellTextStyles.unit.copyWith(color: isError ? colorScheme.error : null),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
