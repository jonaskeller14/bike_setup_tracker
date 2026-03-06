import 'package:flutter/material.dart';
import '../models/todo_rule.dart';
import '../widgets/dialogs/discard_changes.dart';
import 'package:uuid/uuid.dart';

enum TodoPageMode { add, edit, duplicate }

class TodoPage extends StatefulWidget {
  final TodoRule? todoRule;
  final TodoPageMode mode;

  const TodoPage._({super.key, this.todoRule, required this.mode});

  factory TodoPage.add({Key? key}) => 
    TodoPage._(key: key, mode: TodoPageMode.add);

  factory TodoPage.edit({Key? key, required TodoRule todoRule}) => 
    TodoPage._(key: key, todoRule: todoRule, mode: TodoPageMode.edit);

  factory TodoPage.duplicate({Key? key, required TodoRule todoRule}) => 
    TodoPage._(key: key, todoRule: todoRule, mode: TodoPageMode.duplicate);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  TodoPriority _priority = TodoPriority.medium;
  
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.todoRule?.name);
    _nameController.addListener(_changeListener);
    
    _notesController = TextEditingController(text: widget.todoRule?.notes);
    _notesController.addListener(_changeListener);
    
    if (widget.mode != TodoPageMode.add && widget.todoRule != null) {
      _priority = widget.todoRule!.priority;
    }
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.todoRule?.name ?? '') ||
        _notesController.text.trim() != (widget.todoRule?.notes ?? '') ||
        _priority != (widget.todoRule?.priority ?? TodoPriority.medium);
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
    
    Navigator.pop(context, TodoRule(
      id: widget.mode == TodoPageMode.edit ? widget.todoRule!.id : const Uuid().v4(), 
      name: name,
      notes: notes.isEmpty ? null : notes,
      priority: _priority,
      isDeleted: false,
      lastModified: DateTime.now().toUtc(),
    ));
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

  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            TodoPageMode.add || TodoPageMode.duplicate => const Text('Add Todo'),
            TodoPageMode.edit => const Text('Edit Todo'),
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
                  autofocus: widget.mode == TodoPageMode.add,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Todo Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter todo name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == TodoPageMode.edit && _nameController.text.trim() != widget.todoRule?.name,
                  ),
                  validator: _validateName,
                  onFieldSubmitted: (_) => _saveTodoRule(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TodoPriority>(
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == TodoPageMode.edit && _priority != widget.todoRule?.priority,
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
                    filled: widget.mode == TodoPageMode.edit && _notesController.text.trim() != (widget.todoRule?.notes ?? ""),
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
