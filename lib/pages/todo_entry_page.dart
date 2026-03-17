import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/todo_entry.dart';
import '../models/todo_rule.dart';
import '../widgets/dialogs/discard_changes.dart';

enum TodoEntryPageMode { add, edit, duplicate }

class TodoEntryPage extends StatefulWidget {
  final TodoEntry? todoEntry;
  final TodoRule todoRule;
  final TodoEntryPageMode mode;

  const TodoEntryPage._({super.key, this.todoEntry, required this.todoRule, required this.mode});

  factory TodoEntryPage.add({Key? key, required TodoRule todoRule}) => 
    TodoEntryPage._(key: key, todoRule: todoRule, mode: TodoEntryPageMode.add);

  factory TodoEntryPage.edit({Key? key, required TodoEntry todoEntry, required TodoRule todoRule}) => 
    TodoEntryPage._(key: key, todoEntry: todoEntry, todoRule: todoRule, mode: TodoEntryPageMode.edit);

  factory TodoEntryPage.duplicate({Key? key, required TodoEntry todoEntry, required TodoRule todoRule}) => 
    TodoEntryPage._(key: key, todoEntry: todoEntry, todoRule: todoRule, mode: TodoEntryPageMode.duplicate);

  @override
  State<TodoEntryPage> createState() => _TodoEntryPageState();
}

class _TodoEntryPageState extends State<TodoEntryPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  late DateTime _selectedDateTimeUtc;
  late DateTime _initialDateTimeUtc;
  late DateTime _selectedDateTimeLocal;
  late DateTime _initialDateTimeLocal;

  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.todoEntry?.name ?? widget.todoRule.name);
    _nameController.addListener(_changeListener);
    
    _notesController = TextEditingController(text: widget.todoEntry?.notes);
    _notesController.addListener(_changeListener);

    final now = DateTime.now();
    _selectedDateTimeLocal = widget.todoEntry?.dateTimeLocal ?? now;
    _initialDateTimeLocal = _selectedDateTimeLocal;
    
    _selectedDateTimeUtc = widget.todoEntry?.dateTimeUTC ?? _selectedDateTimeLocal.toUtc();
    _initialDateTimeUtc = _selectedDateTimeUtc;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.todoEntry?.name ?? '') ||
        _notesController.text.trim() != (widget.todoEntry?.notes ?? '') || 
        _initialDateTimeUtc != _selectedDateTimeUtc || 
        _initialDateTimeLocal != _selectedDateTimeLocal;
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      helpText: "Select Todo Entry Date",
      errorInvalidText: "Date cannot be in the future",
      selectableDayPredicate: (DateTime pickedDate) => !_selectedDateTimeLocal.copyWith(
        day: pickedDate.day,
        month: pickedDate.month,
        year: pickedDate.year,
      ).isAfter(DateTime.now()),
      initialDate: _selectedDateTimeLocal,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (!mounted || pickedDate == null) return;

    final DateTime newDateTimeLocal = _selectedDateTimeLocal.copyWith(
      day: pickedDate.day,
      month: pickedDate.month,
      year: pickedDate.year,
    );
    if (newDateTimeLocal == _selectedDateTimeLocal) return;

    setState(() {
      _selectedDateTimeLocal = newDateTimeLocal;
      _selectedDateTimeUtc = newDateTimeLocal.toUtc();
    });
    _changeListener();
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      helpText: "Select Todo Entry Time",
      initialTime: TimeOfDay.fromDateTime(_selectedDateTimeLocal),
    );

    if (!mounted || pickedTime == null) return;
    
    final DateTime newDateTimeLocal = _selectedDateTimeLocal.copyWith(hour: pickedTime.hour, minute: pickedTime.minute);
    if (newDateTimeLocal == _selectedDateTimeLocal) return;
    if (newDateTimeLocal.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text('Date and Time cannot be in the future.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }

    setState(() {
      _selectedDateTimeLocal = newDateTimeLocal;
      _selectedDateTimeUtc = newDateTimeLocal.toUtc();
    });
    _changeListener();
  }

  void _saveTodoEntry() {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    
    debugPrint("$_selectedDateTimeLocal");
    debugPrint("$_selectedDateTimeUtc");
    Navigator.pop(context, TodoEntry(
      id: widget.mode == TodoEntryPageMode.edit 
          ? widget.todoEntry!.id 
          : const Uuid().v4(), 
      name: name,
      notes: notes.isEmpty ? null : notes,
      todoRule: widget.todoRule.id,
      dateTimeUTC: _selectedDateTimeUtc,
      dateTimeLocal: _selectedDateTimeLocal,
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
    final appSettings = context.read<AppSettings>();
    
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            TodoEntryPageMode.add || TodoEntryPageMode.duplicate => const Text('Add Todo Entry'),
            TodoEntryPageMode.edit => const Text('Edit Todo Entry'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveTodoEntry),
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
                  autofocus: widget.mode == TodoEntryPageMode.add,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Todo Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter todo name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == TodoEntryPageMode.edit && _nameController.text.trim() != widget.todoEntry?.name,
                  ),
                  validator: _validateName,
                  onFieldSubmitted: (_) => _saveTodoEntry(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add additional details...',
                    border: OutlineInputBorder(),
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == TodoEntryPageMode.edit && _notesController.text.trim() != (widget.todoEntry?.notes ?? ""),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.calendar_month),
                      label: Text(
                        DateFormat(appSettings.dateFormat).format(_selectedDateTimeLocal),
                      ),
                      backgroundColor: widget.mode == TodoEntryPageMode.edit && (_selectedDateTimeUtc.year != _initialDateTimeUtc.year || _selectedDateTimeUtc.month != _initialDateTimeUtc.month || _selectedDateTimeUtc.day != _initialDateTimeUtc.day) ? Colors.orange.withValues(alpha: 0.08) : null,
                      onPressed: _pickDate,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.access_time),
                      label: Text(
                        DateFormat(appSettings.timeFormat).format(_selectedDateTimeLocal),
                      ),
                      backgroundColor: widget.mode == TodoEntryPageMode.edit && (_selectedDateTimeUtc.hour != _initialDateTimeUtc.hour || _selectedDateTimeUtc.minute != _initialDateTimeUtc.minute) ? Colors.orange.withValues(alpha: 0.08) : null,
                      onPressed: _pickTime,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}