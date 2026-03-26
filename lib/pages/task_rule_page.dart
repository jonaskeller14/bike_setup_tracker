import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_rule.dart';
import '../models/component.dart';
import '../models/bike.dart';
import '../repositories/app_repository.dart';
import '../widgets/dialogs/discard_changes.dart';
import 'package:uuid/uuid.dart';

enum TaskRulePageMode { add, edit, duplicate }

class TaskRulePage extends StatefulWidget {
  final TaskRule? taskRule;
  final TaskRulePageMode mode;

  const TaskRulePage._({super.key, this.taskRule, required this.mode});

  factory TaskRulePage.add({Key? key}) =>
      TaskRulePage._(key: key, mode: TaskRulePageMode.add);

  factory TaskRulePage.edit({Key? key, required TaskRule taskRule}) =>
      TaskRulePage._(key: key, taskRule: taskRule, mode: TaskRulePageMode.edit);

  factory TaskRulePage.duplicate({Key? key, required TaskRule taskRule}) =>
      TaskRulePage._(
        key: key,
        taskRule: taskRule,
        mode: TaskRulePageMode.duplicate,
      );

  @override
  State<TaskRulePage> createState() => _TaskRulePageState();
}

class _TaskRulePageState extends State<TaskRulePage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  TaskPriority _priority = TaskPriority.medium;
  String? _componentId;

  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.taskRule?.name);
    _nameController.addListener(_changeListener);

    _notesController = TextEditingController(text: widget.taskRule?.notes);
    _notesController.addListener(_changeListener);

    if (widget.mode != TaskRulePageMode.add && widget.taskRule != null) {
      _priority = widget.taskRule!.priority;
      _componentId = widget.taskRule!.componentId;
    }
  }

  void _changeListener() {
    final hasChanges =
        _nameController.text.trim() != (widget.taskRule?.name ?? '') ||
        _notesController.text.trim() != (widget.taskRule?.notes ?? '') ||
        _priority != (widget.taskRule?.priority ?? TaskPriority.medium) ||
        _componentId != widget.taskRule?.componentId;
    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_changeListener);
    _nameController.dispose();
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    super.dispose();
  }

  void _saveTaskRule() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;

    Navigator.pop(
      context,
      TaskRule(
        componentId: _componentId!,
        id: widget.mode == TaskRulePageMode.edit
            ? widget.taskRule!.id
            : const Uuid().v4(),
        name: name,
        notes: notes.isEmpty ? null : notes,
        priority: _priority,
        isDeleted: false,
        lastModified: DateTime.now().toUtc(),
      ),
    );
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateComponent(String? value) {
    if (value == null || value.isEmpty) return 'Component is required';
    return null;
  }

  DropdownMenuItem<String> _dropdownMenuItemComponent(Component component) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    return DropdownMenuItem<String>(
      value: component.id,
      child: Row(
        spacing: 8,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              spacing: 8,
              children: [
                Icon(component.componentType.getIconData()),
                Expanded(
                  child: Text(component.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  component.bike != null ? Bike.iconData : Icons.shelves,
                  color:
                      component.bike == null ||
                          bikes.containsKey(component.bike)
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
                Expanded(
                  child: Text(
                    component.bike == null
                        ? "Not installed"
                        : bikes[component.bike]?.name ?? "BIKE NOT FOUND",
                    style:
                        component.bike == null ||
                            bikes.containsKey(component.bike)
                        ? null
                        : TextStyle(color: Theme.of(context).colorScheme.error),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final components = appRepository.components;

    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            TaskRulePageMode.add ||
            TaskRulePageMode.duplicate => const Text('Add Task'),
            TaskRulePageMode.edit => const Text('Edit Task'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveTaskRule),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    autofocus: widget.mode == TaskRulePageMode.add,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter task name',
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled:
                          widget.mode == TaskRulePageMode.edit &&
                          _nameController.text.trim() != widget.taskRule?.name,
                    ),
                    validator: _validateName,
                    onFieldSubmitted: (_) => _saveTaskRule(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _componentId,
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Component',
                      border: OutlineInputBorder(),
                      hintText: "Choose a component",
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled:
                          widget.mode == TaskRulePageMode.edit &&
                          _componentId != widget.taskRule?.componentId,
                    ),
                    validator: _validateComponent,
                    items: (components.values.toList()
                          ..sort((a, b) => (a.bike ?? "").compareTo(b.bike ?? "")))
                        .map((c) => _dropdownMenuItemComponent(c))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() => _componentId = newValue);
                      _changeListener();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled:
                          widget.mode == TaskRulePageMode.edit &&
                          _priority != widget.taskRule?.priority,
                    ),
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem<TaskPriority>(
                        value: priority,
                        child: Text(priority.label),
                      );
                    }).toList(),
                    onChanged: (TaskPriority? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _priority = newValue;
                        });
                        _changeListener();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add additional details or instructions...',
                      border: OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled:
                          widget.mode == TaskRulePageMode.edit &&
                          _notesController.text.trim() !=
                              (widget.taskRule?.notes ?? ""),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
