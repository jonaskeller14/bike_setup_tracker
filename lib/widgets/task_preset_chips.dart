import 'package:flutter/material.dart';

import '../models/task/task_template.dart';

/// One horizontally scrolling row of recommended tasks; a tap hands the
/// suggestion to [onSelected] to fill the form.
class TaskPresetChips extends StatelessWidget {
  final List<TaskSuggestion> suggestions;
  final ValueChanged<TaskSuggestion> onSelected;
  final EdgeInsetsGeometry padding;

  const TaskPresetChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        spacing: 8,
        children: [
          for (final suggestion in suggestions)
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // Filled and tinted like the recommended panel in the task sheet,
              // so suggestions stand apart from the outlined field chips.
              backgroundColor: colors.primaryContainer,
              side: BorderSide.none,
              avatar: Icon(Icons.auto_awesome, color: colors.onPrimaryContainer),
              // A chip in a horizontal scroll view has unbounded width, so a
              // long name needs a cap to ellipsize.
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  suggestion.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ),
              onPressed: () => onSelected(suggestion),
            ),
        ],
      ),
    );
  }
}
