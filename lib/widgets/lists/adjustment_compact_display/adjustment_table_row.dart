import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import '../../notes_text.dart';
import 'adjustment_cell_layout.dart';
import 'adjustment_display_item.dart';
import 'adjustment_table_cell.dart';
import 'adjustment_table_shared.dart';

class AdjustmentTableRow extends StatelessWidget {
  static const double errorBorderWidth = 1;
  static const double errorContentPadding = 6;
  static const double rowIndent = errorBorderWidth + errorContentPadding;
  static const double _lineSpacing = 2;

  final AdjustmentDisplayItem item;
  final List<MapEntry<Adjustment, dynamic>> entries;
  final Map<Adjustment, dynamic> previousAdjustmentValues;
  final bool showRowIcons;
  final bool highlightInitialValues;

  const AdjustmentTableRow({
    super.key,
    required this.item,
    required this.entries,
    this.previousAdjustmentValues = const {},
    required this.showRowIcons,
    required this.highlightInitialValues,
  });

  Widget _iconTooltip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return infoTooltip(
      context: context,
      message: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            item.name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.notes != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(
                    Icons.notes,
                    size: 13,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: NotesText(
                    item.notes!,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    maxLines: 10,
                  ),
                ),
              ],
            ),
          if (item.errorDescription != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 15,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  Text(
                    item.errorDescription!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(top: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: item.isError
              ? colorScheme.errorContainer
              : colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(5),
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            size: 18,
            color: item.isError ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant,
          ),
          child: item.buildIcon(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = colorScheme.outlineVariant;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (showRowIcons)
          _iconTooltip(context),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lines = layoutAdjustmentCells(
                context: context,
                entries: entries,
                previousAdjustmentValues: previousAdjustmentValues,
                availableWidth: constraints.maxWidth,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: _lineSpacing,
                children: [
                  for (final line in lines)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var pos = 0; pos < line.length; pos++) ...[
                          AdjustmentTableCell(
                            adjustment: line[pos].entry.key,
                            value: line[pos].entry.value,
                            previousValue: previousAdjustmentValues[line[pos].entry.key],
                            highlightInitialValues: highlightInitialValues,
                            isError: item.isError,
                            maxWidth: line[pos].maxWidth,
                          ),
                          if (pos < line.length - 1)
                            AdjustmentTableDivider(color: dividerColor),
                        ],
                      ],
                    ),
                ],
              );
            },
          ),
        )
      ],
    );

    if (item.isError) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: errorContentPadding,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            width: errorBorderWidth,
            color: colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: content,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: rowIndent,
          vertical: 3,
        ),
        child: content,
      );
    }
  }
}
