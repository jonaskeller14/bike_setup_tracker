import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/task_entry.dart';
import '../models/task_rule.dart';
import '../repositories/app_repository.dart';
import '../widgets/dialogs/discard_changes.dart';

enum TaskEntryPageMode { add, edit, duplicate }

class TaskEntryPage extends StatefulWidget {
  final TaskEntry? taskEntry;
  final TaskRule taskRule;
  final TaskEntryPageMode mode;

  const TaskEntryPage._({super.key, this.taskEntry, required this.taskRule, required this.mode});

  factory TaskEntryPage.add({Key? key, required TaskRule taskRule}) => 
    TaskEntryPage._(key: key, taskRule: taskRule, mode: TaskEntryPageMode.add);

  factory TaskEntryPage.edit({Key? key, required TaskEntry taskEntry, required TaskRule taskRule}) => 
    TaskEntryPage._(key: key, taskEntry: taskEntry, taskRule: taskRule, mode: TaskEntryPageMode.edit);

  factory TaskEntryPage.duplicate({Key? key, required TaskEntry taskEntry, required TaskRule taskRule}) => 
    TaskEntryPage._(key: key, taskEntry: taskEntry, taskRule: taskRule, mode: TaskEntryPageMode.duplicate);

  @override
  State<TaskEntryPage> createState() => _TaskEntryPageState();
}

class _TaskEntryPageState extends State<TaskEntryPage> {
  late String _initialName;
  late TextEditingController _nameController;
  late String? _initialNotes;
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
    _initialName = widget.taskEntry?.name ?? "Completed '${widget.taskRule.name}'";
    _nameController = TextEditingController(text: _initialName);
    _nameController.addListener(_changeListener);
    
    _initialNotes = widget.taskEntry?.notes;
    _notesController = TextEditingController(text: _initialNotes);
    _notesController.addListener(_changeListener);

    final now = DateTime.now();
    _selectedDateTimeLocal = widget.taskEntry?.dateTimeLocal ?? now;
    _initialDateTimeLocal = _selectedDateTimeLocal;
    
    _selectedDateTimeUtc = widget.taskEntry?.dateTimeUTC ?? _selectedDateTimeLocal.toUtc();
    _initialDateTimeUtc = _selectedDateTimeUtc;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != _initialName ||
        _notesController.text.trim() != (_initialNotes ?? '') || 
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
      helpText: "Select Task Entry Date",
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
      helpText: "Select Task Entry Time",
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

  void _saveTaskEntry() {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    
    debugPrint("$_selectedDateTimeLocal");
    debugPrint("$_selectedDateTimeUtc");
    Navigator.pop(context, TaskEntry(
      id: widget.mode == TaskEntryPageMode.edit 
          ? widget.taskEntry!.id 
          : const Uuid().v4(), 
      name: name,
      notes: notes.isEmpty ? null : notes,
      taskRule: widget.taskRule.id,
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
    final appRepository = context.watch<AppRepository>();
    final component = appRepository.components[widget.taskRule.componentId];
    
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            TaskEntryPageMode.add || TaskEntryPageMode.duplicate => const Text('Add Task Entry'),
            TaskEntryPageMode.edit => const Text('Edit Task Entry'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveTaskEntry),
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
                  Card.outlined(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        widget.taskRule.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 2,
                            children: [
                              Icon(
                                component?.componentType.getIconData() ?? Icons.grid_view_sharp, 
                                size: 13, 
                                color: component != null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
                              ),
                              Flexible(
                                child: Text(
                                  component?.name ?? "COMPONENT NOT FOUND",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: component != null 
                                        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                        : Theme.of(context).colorScheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 2,
                            children: [
                              Icon(Icons.traffic, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              Text(
                                'Priority: ${widget.taskRule.priority.label}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (widget.taskRule.notes != null && widget.taskRule.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                                  child: Icon(
                                    Icons.notes,
                                    size: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.taskRule.notes!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    autofocus: widget.mode == TaskEntryPageMode.add,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Task Entry Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter task entry name',
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == TaskEntryPageMode.edit && _nameController.text.trim() != widget.taskEntry?.name,
                    ),
                    validator: _validateName,
                    onFieldSubmitted: (_) => _saveTaskEntry(),
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
                      filled: widget.mode == TaskEntryPageMode.edit && _notesController.text.trim() != (widget.taskEntry?.notes ?? ""),
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
                        backgroundColor: widget.mode == TaskEntryPageMode.edit && (_selectedDateTimeUtc.year != _initialDateTimeUtc.year || _selectedDateTimeUtc.month != _initialDateTimeUtc.month || _selectedDateTimeUtc.day != _initialDateTimeUtc.day) ? Colors.orange.withValues(alpha: 0.08) : null,
                        onPressed: _pickDate,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.access_time),
                        label: Text(
                          DateFormat(appSettings.timeFormat).format(_selectedDateTimeLocal),
                        ),
                        backgroundColor: widget.mode == TaskEntryPageMode.edit && (_selectedDateTimeUtc.hour != _initialDateTimeUtc.hour || _selectedDateTimeUtc.minute != _initialDateTimeUtc.minute) ? Colors.orange.withValues(alpha: 0.08) : null,
                        onPressed: _pickTime,
                      ),
                    ],
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