import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_template.dart';
import '../../repositories/app_repository.dart';
import '../../theme.dart';
import '../../utils/task_preset_resolver.dart';
import '../app_snackbar.dart';
import '../items/task_rule_sheet_tile.dart';
import 'sheet_header.dart';

enum TaskRulesTrigger { added, duplicated, replaced }

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
  ComponentType? componentType,
  String? presetName,
  TaskRulesTrigger? trigger,
}) async {
  assert(copyRules.isNotEmpty || suggestions.isNotEmpty);
  assert(copyRules.isEmpty || copyFrom != null);
  assert(suggestions.isEmpty || componentType != null);

  final theme = Theme.of(context);
  final success = theme.extension<SnackBarColors>()!.success;

  return showModalBottomSheet<TaskRulesSheetResult>(
    useSafeArea: true,
    isScrollControlled: true,
    // The success tint replaces the default handle, which cannot be recolored per sheet.
    showDragHandle: trigger == null ? null : false,
    backgroundColor: trigger == null ? null : Color.alphaBlend(success.withValues(alpha: 0.18), theme.colorScheme.surface),
    context: context,
    builder: (BuildContext context) {
      return _TaskRulesSheet(
        copyFrom: copyFrom,
        copyRules: copyRules,
        suggestions: suggestions,
        componentName: componentName,
        componentType: componentType,
        presetName: presetName,
        trigger: trigger,
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
  final ComponentType? componentType;
  final String? presetName;
  final TaskRulesTrigger? trigger;

  const _TaskRulesSheet({
    required this.copyFrom,
    required this.copyRules,
    required this.suggestions,
    required this.componentName,
    required this.componentType,
    required this.presetName,
    required this.trigger,
  });

  @override
  State<_TaskRulesSheet> createState() => _TaskRulesSheetState();
}

class _TaskRulesSheetState extends State<_TaskRulesSheet> {
  late final List<TaskRule> _openRules;
  late final List<TaskRule> _doneRules;
  late final Set<TaskRule> _selectedCopies;
  late final Set<TaskSuggestion> _selectedSuggestions;

  /// Empty while task recommendations are off, so the sheet follows the setting live.
  List<TaskSuggestion> get _suggestions =>
      context.select<AppSettings, bool>((settings) => settings.showTaskPresets) ? widget.suggestions : const [];

  _Mode get _mode => switch ((widget.copyRules.isNotEmpty, _suggestions.isNotEmpty)) {
    (true, true) => _Mode.merged,
    (true, false) => _Mode.copy,
    _ => _Mode.recommend,
  };

  /// A copy carries its source's key, so the matching template would be a duplicate.
  List<TaskSuggestion> get _visibleSuggestions =>
      _suggestions.where((suggestion) => !isTaskPresetConsumed(suggestion.key, _selectedCopies)).toList();

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

  String _successTitle(TaskRulesTrigger trigger) => switch (trigger) {
    TaskRulesTrigger.added || TaskRulesTrigger.duplicated => "'${widget.componentName}' added",
    TaskRulesTrigger.replaced => "'${widget.copyFrom ?? widget.componentName}' replaced",
  };

  String get _prompt {
    final type = widget.componentType?.label.toLowerCase() ?? 'component';
    return switch (_mode) {
      _Mode.copy => "Copy tasks from '${widget.copyFrom}'?",
      _Mode.recommend => 'Add tasks for this $type?',
      _Mode.merged => 'Set up tasks for this $type?',
    };
  }

  void _turnOffRecommendations() {
    final appSettings = context.read<AppSettings>();
    final messenger = ScaffoldMessenger.of(context);
    unawaited(HapticFeedback.lightImpact());
    // Built before the sheet can pop, while its context is still active.
    final snackBar = AppSnackBar.info(
      context,
      'Task recommendations turned off. Turn them back on in Settings › Features.',
      action: AppSnackBarAction(label: 'UNDO', onPressed: () => appSettings.enableTaskPresets = true),
    );
    appSettings.enableTaskPresets = false;
    messenger.showSnackBar(snackBar);
    if (widget.copyRules.isEmpty) Navigator.pop(context);
  }

  Widget _copySection() {
    final allRules = [..._openRules, ..._doneRules];

    Widget tile(TaskRule rule, {required bool isDone}) => TaskRuleSheetTile(
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
    final typeLabel = widget.componentType!.label;
    final selectedVisible = visible.where(_selectedSuggestions.contains).length;

    String origin(TaskSuggestion suggestion) {
      final strava = suggestion.stravaInterval;
      final parts = [
        if (strava != null)
          'Time-based · ${taskIntervalLabel(strava, distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit)} with Strava',
        ?suggestion.source,
      ];
      return parts.isEmpty ? 'Typical interval for ${typeLabel.toLowerCase()}' : parts.join(' · ');
    }

    final presetName = widget.presetName;
    final recommendedFor = presetName != null && visible.any((suggestion) => suggestion.source != null)
        ? presetName
        : typeLabel;

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
              title: 'Recommended for $recommendedFor',
              icon: Icons.auto_awesome,
              color: colors.onPrimaryContainer,
              maxLines: 2,
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
            ..._suggestions.map((suggestion) => _AnimatedReveal(
              child: !visible.contains(suggestion) ? const SizedBox.shrink() : TaskRuleSheetTile(
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: colors.onPrimaryContainer),
                onPressed: _turnOffRecommendations,
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Turn off recommendations'),
              ),
            ),
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
    final trigger = widget.trigger;

    final theme = Theme.of(context);
    final success = theme.extension<SnackBarColors>()!;

    final body = SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trigger != null) ...[
                    Text(_prompt, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    trigger == null ? _description : 'Optional — ${_description[0].toLowerCase()}${_description.substring(1)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  child: Text(isCopyMode ? 'Continue without copying tasks' : 'Not now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: false,
          child: trigger == null
              ? SheetHeader(title: _title, titleMaxLines: 2, leadingIcon: const Icon(Icons.checklist))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: success.success.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SheetHeader(
                      title: _successTitle(trigger),
                      titleMaxLines: 2,
                      leadingIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle, color: success.success),
                      ),
                      showClose: false,
                      actions: [
                        IconButton.filled(
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: success.success.withValues(alpha: 0.2),
                            foregroundColor: theme.colorScheme.onSurface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        ),
        Flexible(
          child: trigger == null ? body : ColoredBox(color: theme.colorScheme.surface, child: body),
        ),
      ],
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
  final int maxLines;
  final int selected;
  final int total;
  final ValueChanged<bool> onChanged;

  const _SectionHeader({
    required this.title,
    this.icon,
    this.color,
    this.maxLines = 1,
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
                Flexible(child: Text(title, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis)),
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
