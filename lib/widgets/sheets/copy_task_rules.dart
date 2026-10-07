import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_template.dart';
import '../../models/task/task_threshold/task_threshold.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_preset_resolver.dart';
import '../items/task_rule_list_card.dart';
import '../task_priority_badge.dart';
import 'sheet_header.dart';

@immutable
class TaskRulesSheetResult {
  final List<TaskRule> copied;
  final List<TaskSuggestion> suggested;

  const TaskRulesSheetResult({required this.copied, required this.suggested});
}

Future<List<TaskRule>?> showCopyTaskRulesSheet(BuildContext context, {
  required List<TaskRule> taskRules,
  required String sourceName,
  required String componentName,
}) async {
  final result = await showTaskRulesSheet(
    context,
    copyFrom: sourceName,
    copyRules: taskRules,
    componentName: componentName,
  );
  return result?.copied;
}

Future<TaskRulesSheetResult?> showTaskRulesSheet(BuildContext context, {
  String? copyFrom,
  List<TaskRule> copyRules = const [],
  List<TaskSuggestion> suggestions = const [],
  required String componentName,
  String? componentTypeLabel,
}) async {
  assert(copyRules.isNotEmpty || suggestions.isNotEmpty);
  assert(copyRules.isEmpty || copyFrom != null);
  assert(suggestions.isEmpty || componentTypeLabel != null);

  return showModalBottomSheet<TaskRulesSheetResult>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return _TaskRulesSheet(
        copyFrom: copyFrom,
        copyRules: copyRules,
        suggestions: suggestions,
        componentName: componentName,
        componentTypeLabel: componentTypeLabel,
      );
    },
  );
}

enum _Mode { copy, recommend, merged }

class _TaskRulesSheet extends StatefulWidget {
  final String? copyFrom;
  final List<TaskRule> copyRules;
  final List<TaskSuggestion> suggestions;
  final String componentName;
  final String? componentTypeLabel;

  const _TaskRulesSheet({
    required this.copyFrom,
    required this.copyRules,
    required this.suggestions,
    required this.componentName,
    required this.componentTypeLabel,
  });

  @override
  State<_TaskRulesSheet> createState() => _TaskRulesSheetState();
}

class _TaskRulesSheetState extends State<_TaskRulesSheet> {
  late final List<TaskRule> _openRules;
  late final List<TaskRule> _doneRules;
  late final Set<TaskRule> _selectedCopies;
  late final Set<TaskSuggestion> _selectedSuggestions;

  _Mode get _mode => switch ((widget.copyRules.isNotEmpty, widget.suggestions.isNotEmpty)) {
    (true, true) => _Mode.merged,
    (true, false) => _Mode.copy,
    _ => _Mode.recommend,
  };

  /// A copy carries its source's key, so the matching template would be a duplicate.
  List<TaskSuggestion> get _visibleSuggestions =>
      widget.suggestions.where((suggestion) => !isTaskPresetConsumed(suggestion.key, _selectedCopies)).toList();

  static int _byPriorityThenName(TaskRule a, TaskRule b) {
    final byPriority = b.priority.index.compareTo(a.priority.index);
    return byPriority != 0 ? byPriority : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    final appRepository = context.read<AppRepository>();
    bool isDone(TaskRule rule) => appRepository.getTaskRuleStatus(rule).type == TaskStatusType.completed;
    _openRules = widget.copyRules.where((rule) => !isDone(rule)).toList()..sort(_byPriorityThenName);
    _doneRules = widget.copyRules.where(isDone).toList()..sort(_byPriorityThenName);
    _selectedCopies = {..._openRules};
    // Copying is the default way to carry a task over, so the source's rules
    // win over the template's preselection.
    _selectedSuggestions = {
      ...widget.suggestions.where(
        (suggestion) => suggestion.preselected && !isTaskPresetConsumed(suggestion.key, widget.copyRules),
      ),
    };
  }

  /// Also unchecks the suggestions these copies hide, so a suggestion revealed
  /// by unchecking a copy later never starts checked.
  void _selectCopies(Iterable<TaskRule> rules) {
    _selectedCopies.addAll(rules);
    _selectedSuggestions.removeWhere((suggestion) => isTaskPresetConsumed(suggestion.key, rules));
  }

  String get _title => switch (_mode) {
    _Mode.copy => 'Copy tasks?',
    _Mode.recommend => "Recommended tasks for '${widget.componentName}'",
    _Mode.merged => "Tasks for '${widget.componentName}'",
  };

  String get _description => switch (_mode) {
    _Mode.copy =>
      "Pick the tasks to copy to '${widget.componentName}'. Copies start fresh — the completion history stays with the original component.",
    _Mode.recommend => 'Pick the tasks to add. Each one becomes a normal task you can edit later.',
    _Mode.merged =>
      "Copies start fresh — the completion history stays with '${widget.copyFrom}'. Recommended tasks become normal tasks you can edit later.",
  };

  Widget _copySection() {
    final allRules = [..._openRules, ..._doneRules];

    Widget tile(TaskRule rule, {required bool isDone}) => _TaskRuleSheetTile(
      name: rule.name,
      priority: rule.priority,
      interval: rule.interval,
      delay: rule.delay,
      repeat: rule.repeat,
      tags: rule.tags,
      isDone: isDone,
      isSelected: _selectedCopies.contains(rule),
      onChanged: (checked) => setState(() {
        if (checked == true) {
          _selectCopies([rule]);
        } else {
          _selectedCopies.remove(rule);
        }
      }),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: _mode == _Mode.merged ? "Copy from '${widget.copyFrom}'" : 'Tasks',
          selected: _selectedCopies.length,
          total: allRules.length,
          onChanged: (selectAll) => setState(() {
            _selectedCopies.clear();
            if (selectAll) _selectCopies(allRules);
          }),
        ),
        ..._openRules.map((rule) => tile(rule, isDone: false)),
        if (_openRules.isNotEmpty && _doneRules.isNotEmpty) const SizedBox(height: 8),
        ..._doneRules.map((rule) => tile(rule, isDone: true)),
      ],
    );
  }

  Widget _suggestionSection(BuildContext context, List<TaskSuggestion> visible) {
    final appSettings = context.watch<AppSettings>();
    final selectedVisible = visible.where(_selectedSuggestions.contains).length;

    String origin(TaskSuggestion suggestion) {
      final strava = suggestion.stravaInterval;
      final parts = [
        if (strava != null)
          'Time-based · ${taskIntervalLabel(strava, distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit)} with Strava',
        ?suggestion.source,
      ];
      return parts.isEmpty ? 'Typical interval' : parts.join(' · ');
    }

    final colors = Theme.of(context).colorScheme;
    // Tinted like the catalog card on the component form, so recommendations
    // read apart from the copied rules.
    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Recommended for ${widget.componentTypeLabel}',
              icon: Icons.auto_awesome,
              color: colors.onPrimaryContainer,
              selected: selectedVisible,
              total: visible.length,
              onChanged: (selectAll) => setState(() {
                if (selectAll) {
                  _selectedSuggestions.addAll(visible);
                } else {
                  _selectedSuggestions.removeAll(visible);
                }
              }),
            ),
            ...widget.suggestions.map((suggestion) => _AnimatedReveal(
              child: !visible.contains(suggestion) ? const SizedBox.shrink() : _TaskRuleSheetTile(
                name: suggestion.name,
                priority: suggestion.priority,
                interval: suggestion.interval,
                delay: null,
                repeat: suggestion.repeat,
                tags: const {},
                origin: origin(suggestion),
                isDone: false,
                isSelected: _selectedSuggestions.contains(suggestion),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selectedSuggestions.add(suggestion);
                  } else {
                    _selectedSuggestions.remove(suggestion);
                  }
                }),
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = _visibleSuggestions;
    final result = TaskRulesSheetResult(
      copied: [..._openRules, ..._doneRules].where(_selectedCopies.contains).toList(),
      suggested: visibleSuggestions.where(_selectedSuggestions.contains).toList(),
    );
    final count = result.copied.length + result.suggested.length;
    final taskLabel = "$count task${count == 1 ? '' : 's'}";
    final isCopyMode = _mode == _Mode.copy;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: _title, leadingIcon: const Icon(Icons.checklist)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.copyRules.isNotEmpty) _copySection(),
                  _AnimatedReveal(
                    child: visibleSuggestions.isEmpty ? const SizedBox.shrink() : Padding(
                      padding: EdgeInsets.only(top: widget.copyRules.isNotEmpty ? 24 : 0),
                      child: _suggestionSection(context, visibleSuggestions),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                FilledButton.icon(
                  icon: Icon(isCopyMode ? Icons.copy : Icons.add),
                  onPressed: count == 0 ? null : () => Navigator.pop(context, result),
                  label: Text(isCopyMode ? 'Copy $taskLabel' : 'Add $taskLabel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isCopyMode ? 'Continue without copying tasks' : 'Skip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grows and fades [child] in, or shrinks and fades it out, when it switches to
/// or from an empty box. Unlike [AnimatedSize], the outgoing content stays
/// visible while it collapses.
class _AnimatedReveal extends StatelessWidget {
  static const _duration = Duration(milliseconds: 200);
  final Widget child;

  const _AnimatedReveal({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : _duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final int selected;
  final int total;
  final ValueChanged<bool> onChanged;

  const _SectionHeader({
    required this.title,
    this.icon,
    this.color,
    required this.selected,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color);
    return Padding(
      padding: EdgeInsets.only(left: icon == null ? 0 : 8, right: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(title, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(' ($selected / $total)', style: style),
              ],
            ),
          ),
          Checkbox(
            tristate: true,
            value: selected == total ? true : (selected == 0 ? false : null),
            onChanged: (bool? newValue) => onChanged(newValue == true),
          ),
        ],
      ),
    );
  }
}

/// One selectable row: what the created rule will be, without the source's
/// progress (a copy starts at 0 %) or its component (the same on every row).
class _TaskRuleSheetTile extends StatelessWidget {
  final String name;
  final TaskPriority priority;
  final TaskThreshold? interval;
  final TaskThreshold? delay;
  final bool repeat;
  final Set<String> tags;

  /// Where a recommended interval comes from; `null` for copied rules.
  final String? origin;
  final bool isDone;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _TaskRuleSheetTile({
    required this.name,
    required this.priority,
    required this.interval,
    required this.delay,
    required this.repeat,
    required this.tags,
    this.origin,
    required this.isDone,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final showTags = appSettings.enableTaskTags && tags.isNotEmpty;
    final hasSubtitle = interval != null || showTags || origin != null;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Opacity(
      opacity: isDone && !isSelected ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: CheckboxListTile(
          title: Row(
            spacing: 6,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationThickness: 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (appSettings.enableTaskPriority)
                TaskPriorityBadge(priority: priority),
            ],
          ),
          subtitle: !hasSubtitle ? null : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (interval != null)
                TaskIntervalText(interval: interval!, delay: delay, repeat: repeat),
              if (showTags)
                TaskRuleListCard.tagsWidget(context, tags: tags),
              if (origin != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    spacing: 6,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: mutedColor),
                      Expanded(
                        child: Text(
                          origin!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          dense: true,
          value: isSelected,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
