import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/task/task_association.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../repositories/app_repository.dart';
import '../theme.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/task_association_picker.dart';
import '../widgets/task_rule_display_card.dart';

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

  late TaskAssociation _association;
  late TaskAssociation _initialAssociation;

  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialName = widget.taskEntry?.name ?? widget.taskRule.name;
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

    _association = TaskAssociation.fromIds(
      componentId: widget.taskEntry?.componentId ?? (widget.mode == TaskEntryPageMode.add ? widget.taskRule.componentId : null),
      bikeId: widget.taskEntry?.bikeId ?? (widget.mode == TaskEntryPageMode.add ? widget.taskRule.bikeId : null),
    );
    _initialAssociation = _association;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != _initialName ||
        _notesController.text.trim() != (_initialNotes ?? '') || 
        _initialDateTimeUtc != _selectedDateTimeUtc || 
        _initialDateTimeLocal != _selectedDateTimeLocal ||
        _association != _initialAssociation;
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
    final TimeOfDay? pickedTime = await showTimePicker(
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

  Future<void> _saveTaskEntry() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final notes = _notesController.text.trim();
      final appRepository = context.read<AppRepository>();
      
      final snapshot = (widget.mode == TaskEntryPageMode.edit && _association == _initialAssociation && _initialDateTimeUtc == _selectedDateTimeUtc)
          ? widget.taskEntry?.snapshot 
          : await appRepository.getStatsAt(
              componentId: _association.componentId,
              bikeId: _association.bikeId,
              date: _selectedDateTimeUtc,
            );

      if (!mounted) return;
      _formHasChanges = false;
      
      Navigator.pop(context, TaskEntry(
        id: widget.mode == TaskEntryPageMode.edit 
            ? widget.taskEntry!.id 
            : const Uuid().v4(), 
        name: name,
        notes: notes.isEmpty ? null : notes,
        taskRule: widget.taskRule.id,
        componentId: _association.componentId,
        bikeId: _association.bikeId,
        snapshot: snapshot,
        dateTimeUTC: _selectedDateTimeUtc,
        dateTimeLocal: _selectedDateTimeLocal,
        isDeleted: false,
        lastModified: DateTime.now().toUtc(),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  String _describeAssociation(TaskAssociation association, Map<String, Bike> bikes, Map<String, Component> components) {
    return switch (association) {
      ComponentTaskAssociation(:final id) => components[id]?.name ?? "a deleted component",
      BikeTaskAssociation(:final id) => bikes[id]?.name ?? "a deleted bike",
      GeneralTaskAssociation() => "a general task",
    };
  }

  String? _linkMismatchWarning(Map<String, Bike> bikes, Map<String, Component> components) {
    final ruleAssociation = TaskAssociation.fromIds(
      componentId: widget.taskRule.componentId,
      bikeId: widget.taskRule.bikeId,
    );
    if (_association == ruleAssociation) return null;
    return 'WARNING: Differs from the task rule, which is linked to ${_describeAssociation(ruleAssociation, bikes, components)}.';
  }

  Widget _associationDisplay(Map<String, Bike> bikes, Map<String, Component> components) {
    final scheme = Theme.of(context).colorScheme;

    IconData icon;
    String primary;
    String? secondary;
    Color? errorColor;

    switch (_association) {
      case GeneralTaskAssociation():
        icon = Icons.circle_outlined;
        primary = "General Task";
      case BikeTaskAssociation(:final id):
        final bike = bikes[id];
        icon = Bike.iconData;
        primary = bike?.name ?? "BIKE NOT FOUND";
        errorColor = bike == null ? scheme.error : null;
      case ComponentTaskAssociation(:final id):
        final component = components[id];
        if (component == null) {
          icon = Component.iconData;
          primary = "COMPONENT NOT FOUND";
          errorColor = scheme.error;
          break;
        }
        icon = component.componentType.getIconData();
        primary = component.name;
        switch (component.latestInstallation) {
          case Archival():
            secondary = "Archived";
          case BikeInstallation(:final bikeId):
            final bike = bikes[bikeId];
            secondary = bike == null ? "BIKE NOT FOUND" : "on ${bike.name}";
            if (bike == null) errorColor = scheme.error;
          case Uninstallation() || null:
            secondary = "Not installed";
        }
    }

    return Row(
      spacing: 8,
      children: [
        Icon(icon, color: errorColor),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.1,
                  color: errorColor,
                ),
              ),
              if (secondary != null)
                Text(
                  secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.1,
                    color: errorColor ?? Theme.of(context).hintColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String? _selectionHelperText(Map<String, Bike> bikes, Map<String, Component> components) {
    final parts = <String>[];
    if (_association is ComponentTaskAssociation &&
        components[_association.componentId]?.isArchived == true) {
      parts.add('WARNING: Tasks of archived components are hidden in the task list.');
    }
    final mismatch = _linkMismatchWarning(bikes, components);
    if (mismatch != null) parts.add(mismatch);
    return parts.isEmpty ? null : parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;

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
            if (_isSaving)
              const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
            else
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
                  TaskRuleDisplayCard(taskRule: widget.taskRule, showStatus: false),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    autofocus: widget.mode == TaskEntryPageMode.add,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Task Entry Name',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter task entry name',
                      fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
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
                      border: const OutlineInputBorder(),
                      fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                      filled: widget.mode == TaskEntryPageMode.edit && _notesController.text.trim() != (widget.taskEntry?.notes ?? ""),
                    ),
                  ),
                  if (widget.mode == TaskEntryPageMode.edit) ...[
                    const SizedBox(height: 12),
                    FormField<TaskAssociation>(
                      initialValue: _association,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      builder: (field) {
                        return InkWell(
                          onTap: () async {
                            final picked = await showTaskAssociationSheet(
                              context: context,
                              selected: _association,
                              initial: _initialAssociation,
                            );
                            if (picked == null) return;
                            setState(() => _association = picked);
                            field.didChange(picked);
                            _changeListener();
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Linked To',
                              border: const OutlineInputBorder(),
                              suffixIcon: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                              filled: _association != _initialAssociation,
                              helperText: _selectionHelperText(bikes, components),
                              helperMaxLines: 3,
                              helperStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                            child: _associationDisplay(bikes, components),
                          ),
                        );
                      },
                    ),
                  ],
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
                        backgroundColor: widget.mode == TaskEntryPageMode.edit && (_selectedDateTimeUtc.year != _initialDateTimeUtc.year || _selectedDateTimeUtc.month != _initialDateTimeUtc.month || _selectedDateTimeUtc.day != _initialDateTimeUtc.day) ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
                        onPressed: _pickDate,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.access_time),
                        label: Text(
                          DateFormat(appSettings.timeFormat).format(_selectedDateTimeLocal),
                        ),
                        backgroundColor: widget.mode == TaskEntryPageMode.edit && (_selectedDateTimeUtc.hour != _initialDateTimeUtc.hour || _selectedDateTimeUtc.minute != _initialDateTimeUtc.minute) ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
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
