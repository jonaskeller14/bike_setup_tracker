import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task/task_template.dart';

/// One horizontally scrolling row of recommended tasks; a tap hands the
/// suggestion to [onSelected] to fill the form. While [appliedKey] is set, its
/// chip turns grey in place and the others collapse away; [onUnlink] brings
/// them back.
class TaskPresetChips extends StatelessWidget {
  final List<TaskSuggestion> suggestions;
  final ValueChanged<TaskSuggestion> onSelected;
  final String? appliedKey;

  /// Name of the applied preset when [suggestions] no longer offers it, e.g.
  /// because another rule already uses its template.
  final String? appliedName;
  final VoidCallback onUnlink;
  final EdgeInsetsGeometry padding;

  const TaskPresetChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.appliedKey,
    this.appliedName,
    required this.onUnlink,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final applied = appliedKey;
    final name = appliedName;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200);

    // Grey like the applied preset card on ComponentPage.
    Widget appliedChip(String label) => InputChip(
          key: const ValueKey('applied'),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: colors.surfaceContainerHighest,
          side: BorderSide.none,
          avatar: const Icon(Icons.auto_awesome),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          deleteIcon: const Icon(Icons.link_off),
          deleteButtonTooltipMessage: 'Unlink preset (keeps values)',
          onDeleted: onUnlink,
        );

    Widget suggestionChip(TaskSuggestion suggestion) => ActionChip(
          key: const ValueKey('suggestion'),
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
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final suggestion in suggestions)
            _PresetChipItem(
              key: ValueKey(suggestion.key),
              visible: applied == null || suggestion.key == applied,
              child: AnimatedSwitcher(
                duration: duration,
                // The default layout centres both chips, and the grey one is wider, so the old chip would slide.
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previousChildren, ?currentChild],
                ),
                child: suggestion.key == applied ? appliedChip(suggestion.name) : suggestionChip(suggestion),
              ),
            ),
          if (applied != null && name != null && suggestions.every((suggestion) => suggestion.key != applied))
            _PresetChipItem(key: ValueKey(applied), visible: true, child: appliedChip(name)),
        ],
      ),
    );
  }
}

/// One chip slot of [TaskPresetChips]. Hidden, it collapses sideways and fades
/// out, then leaves the tree; shown again, it grows back.
class _PresetChipItem extends StatefulWidget {
  final bool visible;
  final Widget child;

  const _PresetChipItem({super.key, required this.visible, required this.child});

  @override
  State<_PresetChipItem> createState() => _PresetChipItemState();
}

class _PresetChipItemState extends State<_PresetChipItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: widget.visible ? 1 : 0,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(_PresetChipItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed) return const SizedBox.shrink();
        return SizeTransition(
          sizeFactor: _animation,
          axis: Axis.horizontal,
          alignment: Alignment.centerLeft,
          child: FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
