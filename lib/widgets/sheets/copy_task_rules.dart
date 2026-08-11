import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../items/data_select_task_rule.dart';
import 'sheet_header.dart';

/// Lets the user pick which of a component's task rules are copied onto a newly
/// created component. Returns the selected rules, or null if dismissed.
Future<List<TaskRule>?> showCopyTaskRulesSheet(BuildContext context, {
  required List<TaskRule> taskRules,
  required String componentName,
}) async {
  return showModalBottomSheet<List<TaskRule>>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return _CopyTaskRulesSheet(taskRules: taskRules, componentName: componentName);
    },
  );
}

class _CopyTaskRulesSheet extends StatefulWidget {
  final List<TaskRule> taskRules;
  final String componentName;

  const _CopyTaskRulesSheet({required this.taskRules, required this.componentName});

  @override
  State<_CopyTaskRulesSheet> createState() => _CopyTaskRulesSheetState();
}

class _CopyTaskRulesSheetState extends State<_CopyTaskRulesSheet> {
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
          const SheetHeader(title: "Copy tasks?"),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pick the tasks to copy to '${widget.componentName}'. Copies start fresh — the completion history stays with the original component.",
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
                            "Tasks (${_selected.length} / ${widget.taskRules.length})",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Checkbox(
                          tristate: true,
                          value: _selected.length == widget.taskRules.length
                              ? true
                              : (_selected.isEmpty ? false : null),
                          onChanged: (bool? newValue) {
                            switch (newValue) {
                              case true: setState(() {_selected.clear(); _selected.addAll(widget.taskRules);});
                              case false || null: setState(() => _selected.clear());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  ...widget.taskRules.map((rule) => DataSelectTaskRule(
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
                  )),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(_selected.isEmpty ? Icons.arrow_forward : Icons.copy),
              onPressed: () => Navigator.pop(context, _selected),
              label: Text(
                _selected.isEmpty
                    ? 'Continue without copying tasks'
                    : "Copy ${_selected.length} task${_selected.length == 1 ? '' : 's'}",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
