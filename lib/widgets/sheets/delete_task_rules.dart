import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/component/component.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../items/data_select_task_rule.dart';
import 'sheet_header.dart';

/// Lets the user choose which related task rules are deleted with an asset.
/// Returns null when dismissed and an empty list is never returned by the CTA.
///
/// With [rootComponentId], rules spanning several components are grouped by
/// component so the root's rules can be told apart from its subcomponents'.
Future<List<TaskRule>?> showDeleteTaskRulesSheet(
  BuildContext context, {
  required List<TaskRule> taskRules,
  String? rootComponentId,
}) {
  return showModalBottomSheet<List<TaskRule>>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _DeleteTaskRulesSheet(taskRules: taskRules, rootComponentId: rootComponentId),
  );
}

class _DeleteTaskRulesSheet extends StatefulWidget {
  final List<TaskRule> taskRules;
  final String? rootComponentId;

  const _DeleteTaskRulesSheet({required this.taskRules, required this.rootComponentId});

  @override
  State<_DeleteTaskRulesSheet> createState() => _DeleteTaskRulesSheetState();
}

class _DeleteTaskRulesSheetState extends State<_DeleteTaskRulesSheet> {
  late final List<TaskRule> _selected;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.taskRules];
  }

  /// Rules per component, root first, or null when there is nothing to group.
  List<(Component?, List<TaskRule>)>? _groups(Map<String, Component> components) {
    final rootId = widget.rootComponentId;
    if (rootId == null) return null;
    final byComponent = <String?, List<TaskRule>>{};
    for (final rule in widget.taskRules) {
      (byComponent[rule.association.componentId] ??= []).add(rule);
    }
    if (byComponent.length < 2) return null;

    int rank(String? id) => id == rootId ? 0 : 1;
    final ids = byComponent.keys.toList()
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) return byRank;
        return (components[a]?.name.toLowerCase() ?? '').compareTo(components[b]?.name.toLowerCase() ?? '');
      });
    return [for (final id in ids) (components[id], byComponent[id]!)];
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final groups = _groups(appRepository.components);

    Widget ruleTile(TaskRule rule) => DataSelectTaskRule(
          item: rule,
          bikes: appRepository.bikes,
          components: appRepository.components,
          isSelected: _selected.contains(rule),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _selected.add(rule);
              } else {
                _selected.remove(rule);
              }
            });
          },
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Delete related tasks?'),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deleting a task also deletes its corresponding task entries.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tasks (${_selected.length} / ${widget.taskRules.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Checkbox(
                          tristate: true,
                          value: _selected.length == widget.taskRules.length
                              ? true
                              : (_selected.isEmpty ? false : null),
                          onChanged: (bool? newValue) {
                            setState(() {
                              _selected.clear();
                              if (newValue == true) _selected.addAll(widget.taskRules);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (groups == null)
                    ...widget.taskRules.map(ruleTile)
                  else
                    for (final (component, rules) in groups) ...[
                      _ComponentGroupHeader(
                        component: component,
                        isRoot: component?.id == widget.rootComponentId,
                      ),
                      ...rules.map(ruleTile),
                    ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(_selected.isEmpty ? Icons.arrow_forward : Icons.delete_outline),
              onPressed: () => Navigator.pop(context, _selected),
              label: Text(
                _selected.isEmpty
                    ? 'Continue without deleting tasks'
                    : 'Delete ${_selected.length} task${_selected.length == 1 ? '' : 's'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentGroupHeader extends StatelessWidget {
  final Component? component;
  final bool isRoot;

  const _ComponentGroupHeader({required this.component, required this.isRoot});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        spacing: 8,
        children: [
          Icon(component?.componentType.getIconData() ?? Component.iconData, size: 18, color: cs.onSurfaceVariant),
          Expanded(
            child: Text(
              component?.name ?? 'Component not found',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            isRoot ? 'This component' : 'Subcomponent',
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
