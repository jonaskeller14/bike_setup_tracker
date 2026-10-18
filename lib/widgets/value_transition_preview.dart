import 'package:flutter/material.dart';

/// One example value and the stages it goes through: "5.8 bar → 84 psi → 10 psi".
/// A `null` stage is a cleared value.
class ValueTransitionRow {
  final String? caption;
  final List<String?> stages;

  const ValueTransitionRow({this.caption, required this.stages});
}

/// A card that shows [rows] of example values before and after a migration. A
/// cleared value shows in the error color.
class ValueTransitionPreview extends StatelessWidget {
  final List<ValueTransitionRow> rows;

  const ValueTransitionPreview({super.key, required this.rows});

  static const String clearedLabel = 'No value';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            rows.length == 1 ? 'Example' : 'Examples',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          for (final row in rows) _Row(row: row),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final ValueTransitionRow row;

  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = row.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (caption != null)
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, stage) in row.stages.indexed) ...[
                if (i > 0) Icon(Icons.arrow_forward, size: 18, color: theme.colorScheme.primary),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    stage ?? ValueTransitionPreview.clearedLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: stage == null ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
