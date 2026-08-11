import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/flash_highlight.dart';
import '../../widgets/items/task_entry_list_item.dart';
import '../../widgets/task_rule_display_card.dart';
import '../../widgets/text/section_title.dart';

class TaskRuleDetailsPage extends StatefulWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;

  const TaskRuleDetailsPage({super.key, required this.taskRuleId, this.highlightTaskEntryId});

  @override
  State<TaskRuleDetailsPage> createState() => _TaskRuleDetailsPageState();
}

class _TaskRuleDetailsPageState extends State<TaskRuleDetailsPage> {
  final Set<String> _selectedTaskEntries = {};
  bool _isDeleting = false;

  bool get _isSelectionMode => _selectedTaskEntries.isNotEmpty;

  void _clearTaskEntrySelection() {
    setState(() => _selectedTaskEntries.clear());
  }

  void _toggleTaskEntrySelection(String taskEntryId) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_selectedTaskEntries.remove(taskEntryId)) {
        _selectedTaskEntries.add(taskEntryId);
      }
    });
  }

  Future<void> _deleteSelectedTaskEntries() async {
    if (_isDeleting) return;

    final selectedTaskEntries = Set<String>.of(_selectedTaskEntries);
    setState(() => _isDeleting = true);

    try {
      await TaskActions.removeTaskEntries(context, taskEntryIds: selectedTaskEntries);
      if (!mounted) return;
      setState(() => _selectedTaskEntries.clear());
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clearTaskEntrySelection();
      },
      child: Scaffold(
        appBar: _isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearTaskEntrySelection,
                ),
                title: Text('${_selectedTaskEntries.length} selected'),
                actions: [
                  IconButton(
                    onPressed: _isDeleting ? null : _deleteSelectedTaskEntries,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete selected',
                  ),
                ],
              )
            : AppBar(
                title: const Text("Task"),
                actions: [
                  IconButton(
                    onPressed: () async {
                      final appRepository = context.read<AppRepository>();
                      final taskRule = appRepository.taskRules[widget.taskRuleId];
                      if (taskRule == null) return;
                      await TaskActions.editTaskRule(context, taskRule: taskRule);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TaskRuleDetailsPageContent(
              taskRuleId: widget.taskRuleId,
              highlightTaskEntryId: widget.highlightTaskEntryId,
              selectedTaskEntries: _selectedTaskEntries,
              onTaskEntrySelectionChanged: _toggleTaskEntrySelection,
            ),
          ),
        ),
      ),
    );
  }
}

class TaskRuleDetailsPageContent extends StatefulWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;
  final Set<String> selectedTaskEntries;
  final ValueChanged<String>? onTaskEntrySelectionChanged;

  const TaskRuleDetailsPageContent({
    super.key,
    required this.taskRuleId,
    this.highlightTaskEntryId,
    this.selectedTaskEntries = const {},
    this.onTaskEntrySelectionChanged,
  });

  @override
  State<TaskRuleDetailsPageContent> createState() => _TaskRuleDetailsPageContentState();
}

class _TaskRuleDetailsPageContentState extends State<TaskRuleDetailsPageContent> {
  final GlobalKey _highlightKey = GlobalKey();
  bool _didScrollToHighlight = false;

  void _scrollToHighlight() {
    if (_didScrollToHighlight) return;
    final context = _highlightKey.currentContext;
    if (context == null) return;
    _didScrollToHighlight = true;
    unawaited(
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final taskRule = appRepository.taskRules[widget.taskRuleId];
    if (taskRule == null) return const SizedBox.shrink();

    final taskEntries = appRepository.taskEntries.values
        .where((te) => te.taskRule == taskRule.id)
        .sortedBy((te) => te.dateTimeUTC);
    final reversedTaskEntries = taskEntries.reversed.toList();

    // After the list is laid out, bring the highlighted entry into view.
    if (widget.highlightTaskEntryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TaskRuleDisplayCard(taskRule: taskRule, showStatus: true),
          ),
          const SizedBox(height: 16),

          const SectionTitle(
            title: "Entries",
            infoText:
                "The card above is the Task — the rule defining what to do and when it's due. "
                "Each time you complete it, an entry is logged below. "
                "A recurring task collects multiple entries, one per completion.",
          ),

          if (taskEntries.isEmpty)
            EmptyStatePlaceholder(
              icon: Icons.history,
              title: 'No entries yet',
              subtitle: 'Complete this task to log your first entry.',
              actionLabel: 'Add entry',
              onAction: () => TaskActions.addTaskEntry(context, taskRule: taskRule),
            )
          else
            ...reversedTaskEntries.mapIndexed((index, te) {
              // previousSnapshot is the snapshot of the entry that occurred BEFORE this one in time.
              // Since taskEntries is sorted ASC, the previous entry is at [index - 1] in taskEntries if we weren't reversing.
              // But we are reversed for display (latest first).
              // So for taskEntries.reversed[index], the 'previous' in time is actually taskEntries.reversed[index + 1].
              final previousEntry = (index + 1 < reversedTaskEntries.length) ? reversedTaskEntries[index + 1] : null;

              final isHighlighted = widget.highlightTaskEntryId != null && te.id == widget.highlightTaskEntryId;
              final isSelected = widget.selectedTaskEntries.contains(te.id);
              final isSelectionMode = widget.selectedTaskEntries.isNotEmpty;
              final toggleSelection = widget.onTaskEntrySelectionChanged == null
                  ? null
                  : () => widget.onTaskEntrySelectionChanged!(te.id);

              return FlashHighlight(
                key: isHighlighted ? _highlightKey : null,
                highlighted: isHighlighted,
                child: TaskEntryListItem(
                  taskEntryId: te.id,
                  previousSnapshot: previousEntry?.snapshot,
                  onTap: isSelectionMode ? toggleSelection : null,
                  onLongPress: toggleSelection,
                  selectionMode: isSelectionMode,
                  showTaskRule: false,
                  selected: isSelected,
                  showStats: true,
                ),
              );
            }),
        ],
      ),
    );
  }
}
