import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_rule.dart';
import '../models/component.dart';
import '../models/bike.dart';
import '../repositories/app_repository.dart';
import '../widgets/dialogs/discard_changes.dart';
import 'package:uuid/uuid.dart';

enum TodoRulePageMode { add, edit, duplicate }

class TodoRulePage extends StatefulWidget {
  final TodoRule? todoRule;
  final TodoRulePageMode mode;

  const TodoRulePage._({super.key, this.todoRule, required this.mode});

  factory TodoRulePage.add({Key? key}) =>
      TodoRulePage._(key: key, mode: TodoRulePageMode.add);

  factory TodoRulePage.edit({Key? key, required TodoRule todoRule}) =>
      TodoRulePage._(key: key, todoRule: todoRule, mode: TodoRulePageMode.edit);

  factory TodoRulePage.duplicate({Key? key, required TodoRule todoRule}) =>
      TodoRulePage._(
        key: key,
        todoRule: todoRule,
        mode: TodoRulePageMode.duplicate,
      );

  @override
  State<TodoRulePage> createState() => _TodoRulePageState();
}

class _TodoRulePageState extends State<TodoRulePage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  TodoPriority _priority = TodoPriority.medium;
  String? _componentId;

  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.todoRule?.name);
    _nameController.addListener(_changeListener);

    _notesController = TextEditingController(text: widget.todoRule?.notes);
    _notesController.addListener(_changeListener);

    if (widget.mode != TodoRulePageMode.add && widget.todoRule != null) {
      _priority = widget.todoRule!.priority;
      _componentId = widget.todoRule!.componentId;
    }
  }

  void _changeListener() {
    final hasChanges =
        _nameController.text.trim() != (widget.todoRule?.name ?? '') ||
        _notesController.text.trim() != (widget.todoRule?.notes ?? '') ||
        _priority != (widget.todoRule?.priority ?? TodoPriority.medium) ||
        _componentId != widget.todoRule?.componentId;
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

  void _saveTodoRule() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;

    Navigator.pop(
      context,
      TodoRule(
        componentId: _componentId!,
        id: widget.mode == TodoRulePageMode.edit
            ? widget.todoRule!.id
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
            TodoRulePageMode.add ||
            TodoRulePageMode.duplicate => const Text('Add Todo'),
            TodoRulePageMode.edit => const Text('Edit Todo'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveTodoRule),
          ],
        ),
        body: SingleChildScrollView(
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
                  autofocus: widget.mode == TodoRulePageMode.add,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Todo Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter todo name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled:
                        widget.mode == TodoRulePageMode.edit &&
                        _nameController.text.trim() != widget.todoRule?.name,
                  ),
                  validator: _validateName,
                  onFieldSubmitted: (_) => _saveTodoRule(),
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
                        widget.mode == TodoRulePageMode.edit &&
                        _componentId != widget.todoRule?.componentId,
                  ),
                  validator: _validateComponent,
                  items: components.values
                      .map((c) => _dropdownMenuItemComponent(c))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() => _componentId = newValue);
                    _changeListener();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TodoPriority>(
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled:
                        widget.mode == TodoRulePageMode.edit &&
                        _priority != widget.todoRule?.priority,
                  ),
                  items: TodoPriority.values.map((priority) {
                    return DropdownMenuItem<TodoPriority>(
                      value: priority,
                      child: Text(priority.label),
                    );
                  }).toList(),
                  onChanged: (TodoPriority? newValue) {
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
                        widget.mode == TodoRulePageMode.edit &&
                        _notesController.text.trim() !=
                            (widget.todoRule?.notes ?? ""),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
