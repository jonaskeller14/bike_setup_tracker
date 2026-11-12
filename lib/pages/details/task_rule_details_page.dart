import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../repositories/app_repository.dart';
import '../../services/attachment_storage_service.dart';
import '../../utils/task_actions.dart';
import '../../widgets/animated_app_bar_switcher.dart';
import '../../widgets/attachment_strip.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/flash_highlight.dart';
import '../../widgets/items/task_entry_list_item.dart';
import '../../widgets/items/task_rule_display_card.dart';
import '../../widgets/text/section_title.dart';

class TaskRuleDetailsPage extends StatefulWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;
  final String? heroTag;

  const TaskRuleDetailsPage({
    super.key,
    required this.taskRuleId,
    this.highlightTaskEntryId,
    this.heroTag,
  });

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
        appBar: AnimatedAppBarSwitcher(
          child: _isSelectionMode
              ? AppBar(
                  key: const ValueKey('task-entry-selection-app-bar'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearTaskEntrySelection,
                  ),
                  title: Text(context.l10n.selectionCount(_selectedTaskEntries.length)),
                  actions: [
                    IconButton(
                      onPressed: _isDeleting ? null : _deleteSelectedTaskEntries,
                      icon: const Icon(Icons.delete),
                      tooltip: context.l10n.deleteSelectedTooltip,
                    ),
                  ],
                )
              : AppBar(
                  key: const ValueKey('task-details-app-bar'),
                  title: Text(context.l10n.taskDetailsTitle),
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
        ),
        body: SafeArea(
          child: TaskRuleDetailsPageContent(
            taskRuleId: widget.taskRuleId,
            highlightTaskEntryId: widget.highlightTaskEntryId,
            heroTag: widget.heroTag ?? 'task-rule-card-${widget.taskRuleId}',
            selectedTaskEntries: _selectedTaskEntries,
            onTaskEntrySelectionChanged: _toggleTaskEntrySelection,
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        ),
      ),
    );
  }
}

class TaskRuleDetailsPageContent extends StatefulWidget {
  final String taskRuleId;
  final String? highlightTaskEntryId;
  final String? heroTag;
  final Set<String> selectedTaskEntries;
  final ValueChanged<String>? onTaskEntrySelectionChanged;
  final EdgeInsets padding;

  const TaskRuleDetailsPageContent({
    super.key,
    required this.taskRuleId,
    this.highlightTaskEntryId,
    this.heroTag,
    this.selectedTaskEntries = const {},
    this.onTaskEntrySelectionChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<TaskRuleDetailsPageContent> createState() => _TaskRuleDetailsPageContentState();
}

class _TaskRuleDetailsPageContentState extends State<TaskRuleDetailsPageContent> {
  final GlobalKey _highlightKey = GlobalKey();
  bool _didScrollToHighlight = false;
  String? _attachmentsDirPath;

  @override
  void initState() {
    super.initState();
    unawaited(_initAttachmentsDir());
  }

  Future<void> _initAttachmentsDir() async {
    try {
      final path = await AttachmentStorageService().getAttachmentsPath();
      if (!mounted) return;
      setState(() => _attachmentsDirPath = path);
    } catch (_) {
      // Without the directory the rule and its entries show their attachment count instead of a strip.
    }
  }

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
    if (taskRule == null) {
      return EmptyStatePlaceholder.error(
        title: context.l10n.taskDetailsNotFoundTitle,
        subtitle: context.l10n.taskDetailsNotFoundSubtitle,
      );
    }
    final attachments = taskRule.attachments;

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
            padding: widget.padding,
            child: TaskRuleDisplayCard(
              taskRule: taskRule,
              showStatus: true,
              heroTag: widget.heroTag,
            ),
          ),
          if (attachments.isNotEmpty && _attachmentsDirPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: AttachmentStrip(
                attachments: attachments,
                attachmentsDir: _attachmentsDirPath!,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            )
          else
            const SizedBox(height: 16),

          SectionTitle(
            title: context.l10n.taskDetailsEntriesTitle,
            infoText: context.l10n.taskDetailsEntriesInfo,
          ),

          if (taskEntries.isEmpty)
            EmptyStatePlaceholder(
              icon: Icons.history,
              title: context.l10n.taskDetailsEmptyTitle,
              subtitle: context.l10n.taskDetailsEmptySubtitle,
              actionLabel: context.l10n.taskDetailsEmptyAction,
              onAction: () => TaskActions.addTaskEntry(
                context,
                taskRule: taskRule,
                heroTag: widget.heroTag,
              ),
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
                  showAttachments: true,
                  attachmentsDir: _attachmentsDirPath,
                  heroTag: widget.heroTag,
                ),
              );
            }),
        ],
      ),
    );
  }
}
