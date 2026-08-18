import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../items/data_select_task_rule.dart';
import 'sheet_header.dart';

/// Lets the user choose which related task rules are deleted with an asset.
/// Returns null when dismissed and an empty list is never returned by the CTA.
Future<List<TaskRule>?> showDeleteTaskRulesSheet(
  BuildContext context, {
  required List<TaskRule> taskRules,
}) {
  return showModalBottomSheet<List<TaskRule>>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _DeleteTaskRulesSheet(taskRules: taskRules),
  );
}

class _DeleteTaskRulesSheet extends StatefulWidget {
  final List<TaskRule> taskRules;

  const _DeleteTaskRulesSheet({required this.taskRules});

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

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

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
                  ...widget.taskRules.map(
                    (rule) => DataSelectTaskRule(
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
                    ),
                  ),
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
