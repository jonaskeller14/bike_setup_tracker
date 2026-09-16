import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../notes_text.dart';
import 'adjustment_cell.dart';
import 'adjustment_cell_layout.dart';
import 'adjustment_cell_view.dart';
import 'adjustment_info_tooltip.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final owner = group.owner;
    return infoTooltip(
      context: context,
      message: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            owner.name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onInverseSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (owner.notes != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(Icons.notes, size: 13, color: colorScheme.onInverseSurface),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: NotesText(
                    owner.notes!,
                    fontSize: 13,
                    color: colorScheme.onInverseSurface,
                    maxLines: 10,
                  ),
                ),
              ],
            ),
          if (owner.errorDescription != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Icon(Icons.error_outline, size: 15, color: colorScheme.onErrorContainer),
                  Flexible(
                    child: Text(
                      owner.errorDescription!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
