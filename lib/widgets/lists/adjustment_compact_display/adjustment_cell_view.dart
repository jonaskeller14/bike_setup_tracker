import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../../theme.dart';
import '../../tooltips/info_tooltip.dart';
import '../../tooltips/tooltip_style.dart';
import 'adjustment_cell.dart';
import 'adjustment_cell_layout.dart';

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

  /// What a screen reader announces for [cell]; the rendered `previous →
  /// current` line would otherwise be read out with the arrow glyph.
  String get _semanticsLabel {
    final adjustment = cell.adjustment;
    final value = Adjustment.formatValue(cell.value) + adjustment.unitSuffix();
    return switch (cell) {
      ChangedCell(:final previousValue) =>
        '${adjustment.name}, changed from ${Adjustment.formatValue(previousValue)} to $value',
      _ => '${adjustment.name}, $value',
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

    // The value line mirrors the cell's, down to its line height. The arrow
    // is placed on the middle of its line box, and only at the cell's 1.25
    // leading does that middle coincide with the optical centre of the
    // digits; bodyLarge's 1.5 would leave the glyph about a pixel high.
    final valueLine = theme.textTheme.bodyLarge?.copyWith(height: CellTextStyles.value.height);
    final previousStyle = valueLine?.copyWith(color: onInverse.withValues(alpha: 0.7));

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
              // The same `previous → current` shape the cell prints, down to
              // the arrow icon, but with both values untruncated — this is
              // where a bounded previous value is recovered in full.
              if (cell case ChangedCell(:final previousValue)) ...[
                TextSpan(text: Adjustment.formatValue(previousValue), style: previousStyle),
                WidgetSpan(
                  // Aligns the glyph with the middle of the text run, the
                  // tooltip's equivalent of the cell row's centred segments.
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      cellChangeArrowIcon,
                      size: cellChangeArrowSizeFor(previousStyle?.fontSize ?? 16),
                      color: previousStyle?.color,
                    ),
                  ),
                ),
              ],
              TextSpan(
                text: Adjustment.formatValue(cell.value),
                style: valueLine?.copyWith(color: valueColor, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: adjustment.unitSuffix(),
                style: valueLine?.copyWith(color: onInverse),
              ),
            ],
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
    // The segments are centred, not bottom-aligned: the value line mixes three
    // font sizes, and bottom-aligning boxes of different heights pushes the
    // smaller ones' optical centres down, so the arrow could only ever line up
    // with one of them. Centring makes all three coincide.
    Widget scrollableLine(List<Widget> children) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: cellValueRowSpacing,
            children: children,
          ),
        );

    return Semantics(
      container: true,
      label: _semanticsLabel,
      excludeSemantics: true,
      child: infoTooltip(
        context: context,
        style: TooltipStyle.inverse(context),
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
                if (display.hasPrevious) ...[
                  Text(
                    display.previous!,
                    style: CellTextStyles.change.copyWith(color: changeColor),
                    maxLines: 1,
                  ),
                  cellChangeArrow(context, color: changeColor),
                ],
                Text(
                  display.value,
                  style: CellTextStyles.value.copyWith(color: valueColor),
                  maxLines: 1,
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
      ),
    );
  }
}
