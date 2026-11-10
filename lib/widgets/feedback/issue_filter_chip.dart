import 'package:flutter/material.dart';

import '../../theme.dart';

/// A [FilterChip] that, once picked, takes the colour the feedback list shows
/// it in: red for an issue, green for "No issues" ([noIssues]).
class IssueFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool noIssues;
  final String? tooltip;
  final Widget? avatar;
  final VoidCallback? onDeleted; // Shows a ✕ that deselects, in place of the checkmark.

  const IssueFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.noIssues = false,
    this.tooltip,
    this.avatar,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FeedbackOutcomeColors>()!;
    final color = noIssues ? colors.better : colors.worse;
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      tooltip: tooltip,
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: onDeleted == null,
      onDeleted: onDeleted,
      deleteIconColor: color,
      selectedColor: color.withValues(alpha: 0.12),
      checkmarkColor: color,
      labelStyle: selected ? TextStyle(color: color) : null,
      side: selected ? BorderSide(color: color) : null,
    );
  }
}
