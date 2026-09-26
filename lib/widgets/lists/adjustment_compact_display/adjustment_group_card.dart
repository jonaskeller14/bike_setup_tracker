import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tooltips/tooltip_style.dart';
import 'adjustment_cell.dart';
import 'adjustment_cell_layout.dart';
import 'adjustment_cell_view.dart';

/// A tinted container for one owner (component or person): its icon top left
/// and its value cells packed into rows that each span the full width.
class AdjustmentGroupCard extends StatelessWidget {
  static const double _padding = 4;
  static const double _cellSpacing = 4;

  final AdjustmentCellGroup group;
  final bool showIcon;
  final bool highlightInitialValues;

  const AdjustmentGroupCard({
    super.key,
    required this.group,
    required this.showIcon,
    required this.highlightInitialValues,
  });

  Widget _ownerIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final owner = group.owner;
    return owner.wrapTooltip(
      context,
      style: TooltipStyle.inverse(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
        child: IconTheme.merge(
          data: IconThemeData(size: 18, color: colorScheme.onSurfaceVariant),
          child: owner.buildIcon(context),
        ),
      ),
    );
  }

  Widget _cellRows(BuildContext context, double rowWidth) {
    final cells = group.cells;
    final cap = cellWidthCap(rowWidth: rowWidth, spacing: _cellSpacing);
    final widths = [for (final cell in cells) math.min(measureCellNaturalWidth(context, cell), cap)];
    final rows = packCellRows(widths: widths, rowWidth: rowWidth, spacing: _cellSpacing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: _cellSpacing,
      children: [
        for (final row in rows)
          Row(
            spacing: _cellSpacing,
            children: [
              // Flex proportional to each cell's packed width stretches the
              // row to full width while keeping the cells' relative sizes.
              for (final i in row)
                Expanded(
                  flex: math.max(1, (widths[i] * 10).round()),
                  child: AdjustmentCellView(cell: cells[i], highlightInitialValues: highlightInitialValues),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: group.owner.isError
            ? colorScheme.errorContainer.withValues(alpha: 0.5)
            : colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIcon) _ownerIcon(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => _cellRows(context, constraints.maxWidth),
            ),
          ),
        ],
      ),
    );
  }
}
