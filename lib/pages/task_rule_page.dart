import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_rule.dart';
import '../models/component.dart';
import '../models/bike.dart';
import '../models/task_threshold.dart';
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

class _TaskAssociation {
  final String? componentId;
  final String? bikeId;

  const _TaskAssociation({this.componentId, this.bikeId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TaskAssociation &&
          componentId == other.componentId &&
          bikeId == other.bikeId;

  @override
  int get hashCode => componentId.hashCode ^ bikeId.hashCode;
}

enum _ThresholdType {
  none('None'),
  distance('Distance'),
  movingTime('Moving Time'),
  duration('Duration'),
  activityCount('Activity Count'),
  dateTime('Date');

  final String label;
  const _ThresholdType(this.label);
}

class _TaskRulePageState extends State<TaskRulePage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _intervalValueController;
  late TextEditingController _delayValueController;
  
  TaskPriority _priority = TaskPriority.medium;
  late _TaskAssociation _association;
  late _TaskAssociation _initialAssociation;
  
  _ThresholdType _intervalType = _ThresholdType.none;
  _ThresholdType _delayType = _ThresholdType.none;
  bool _repeat = true;
  DateTime? _intervalDate;

  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.taskRule?.name);
    _nameController.addListener(_changeListener);

    _notesController = TextEditingController(text: widget.taskRule?.notes);
    _notesController.addListener(_changeListener);

    _association = _TaskAssociation(
      componentId: widget.taskRule?.componentId,
      bikeId: widget.taskRule?.bikeId,
    );
    _initialAssociation = _association;

    if (widget.mode != TaskRulePageMode.add && widget.taskRule != null) {
      _priority = widget.taskRule!.priority;
      _repeat = widget.taskRule!.repeat;
      
      _intervalType = _getThresholdType(widget.taskRule!.interval);
      _intervalValueController = TextEditingController(text: _getThresholdValueString(widget.taskRule!.interval));
      if (widget.taskRule!.interval is DateTimeThreshold) {
        _intervalDate = (widget.taskRule!.interval as DateTimeThreshold).deadline;
      }

      _delayType = _getThresholdType(widget.taskRule!.delay);
      _delayValueController = TextEditingController(text: _getThresholdValueString(widget.taskRule!.delay));
    } else {
      _intervalValueController = TextEditingController();
      _delayValueController = TextEditingController();
    }

    _intervalValueController.addListener(_changeListener);
    _delayValueController.addListener(_changeListener);
  }

  _ThresholdType _getThresholdType(TaskThreshold? threshold) {
    switch (threshold) {
      case null: return _ThresholdType.none;
      case DistanceThreshold(): return _ThresholdType.distance;
      case MovingTimeThreshold(): return _ThresholdType.movingTime;
      case DurationThreshold(): return _ThresholdType.duration;
      case ActivityCountThreshold(): return _ThresholdType.activityCount;
      case DateTimeThreshold(): return _ThresholdType.dateTime;
    }
  }

  String _getThresholdValueString(TaskThreshold? threshold) {
    switch (threshold) {
      case null: return "";
      case DistanceThreshold(): return (threshold.meters / 1000).toStringAsFixed(1);
      case ActivityCountThreshold(): return threshold.count.toString();
      case MovingTimeThreshold(): return threshold.hours.inHours.toString();
      case DurationThreshold(): return threshold.days.inDays.toString();
      case DateTimeThreshold(): return ''; 
    }
  }

  void _changeListener() {
    final hasChanges =
        _nameController.text.trim() != (widget.taskRule?.name ?? '') ||
        _notesController.text.trim() != (widget.taskRule?.notes ?? '') ||
        _priority != (widget.taskRule?.priority ?? TaskPriority.medium) ||
        _association != _initialAssociation ||
        _repeat != (widget.taskRule?.repeat ?? true) ||
        _intervalType != _getThresholdType(widget.taskRule?.interval) ||
        _intervalValueController.text != _getThresholdValueString(widget.taskRule?.interval) ||
        (_intervalType == _ThresholdType.dateTime && _intervalDate != (widget.taskRule?.interval is DateTimeThreshold ? (widget.taskRule!.interval as DateTimeThreshold).deadline : null)) ||
        _delayType != _getThresholdType(widget.taskRule?.delay) ||
        _delayValueController.text != _getThresholdValueString(widget.taskRule?.delay);

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
    _intervalValueController.removeListener(_changeListener);
    _intervalValueController.dispose();
    _delayValueController.removeListener(_changeListener);
    _delayValueController.dispose();

    super.dispose();
  }

  TaskThreshold? _createThreshold(_ThresholdType type, String value, DateTime? date) {
    if (type == _ThresholdType.none) return null;
    final doubleVal = double.tryParse(value) ?? 0;
    final intVal = int.tryParse(value) ?? 0;

    switch (type) {
      case _ThresholdType.distance:
        return DistanceThreshold(doubleVal * 1000);
      case _ThresholdType.movingTime:
        return MovingTimeThreshold(Duration(hours: intVal));
      case _ThresholdType.duration:
        return DurationThreshold(Duration(days: intVal));
      case _ThresholdType.activityCount:
        return ActivityCountThreshold(intVal);
      case _ThresholdType.dateTime:
        return date != null ? DateTimeThreshold(date) : null;
      case _ThresholdType.none:
        return null;
    }
  }

  void _saveTaskRule() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    
    final interval = _createThreshold(_intervalType, _intervalValueController.text, _intervalDate);
    final delay = (_intervalType == _ThresholdType.dateTime)
        ? null
        : _createThreshold(_delayType, _delayValueController.text, null);

    // Validation
    final needsAsset = (interval is DistanceThreshold || interval is MovingTimeThreshold || interval is ActivityCountThreshold) ||
                       (delay is DistanceThreshold || delay is MovingTimeThreshold || delay is ActivityCountThreshold);
    
    if (needsAsset && _association.componentId == null && _association.bikeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distance, Time, or Activity triggers require a linked Bike or Component.')),
      );
      return;
    }

    _formHasChanges = false;

    Navigator.pop(
      context,
      TaskRule(
        id: widget.mode == TaskRulePageMode.edit
            ? widget.taskRule!.id
            : const Uuid().v4(),
        name: name,
        notes: notes.isEmpty ? null : notes,
        priority: _priority,
        componentId: _association.componentId,
        bikeId: _association.bikeId,
        interval: interval,
        delay: delay,
        repeat: _intervalType == _ThresholdType.dateTime ? false : _repeat,
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

  DropdownMenuItem<_TaskAssociation> _dropdownMenuItemNone() {
    return const DropdownMenuItem<_TaskAssociation>(
      value: _TaskAssociation(),
      child: Row(
        spacing: 8,
        children: [
          Icon(Icons.circle_outlined),
          Text("General Task"),
        ],
      ),
    );
  }

  DropdownMenuItem<_TaskAssociation> _dropdownMenuItemBike(Bike bike) {
    return DropdownMenuItem<_TaskAssociation>(
      value: _TaskAssociation(bikeId: bike.id),
      child: Row(
        spacing: 8,
        children: [
          const Icon(Bike.iconData),
          Expanded(child: Text(bike.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  DropdownMenuItem<_TaskAssociation> _dropdownMenuItemComponent(Component component) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    return DropdownMenuItem<_TaskAssociation>(
      value: _TaskAssociation(componentId: component.id),
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
                  color: component.bike == null || bikes.containsKey(component.bike)
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
                Expanded(
                  child: Text(
                    component.bike == null
                        ? "Not installed"
                        : bikes[component.bike]?.name ?? "BIKE NOT FOUND",
                    style: component.bike == null || bikes.containsKey(component.bike)
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

  DropdownMenuItem<_TaskAssociation?> _dropdownMenuSection(String label) {
    return DropdownMenuItem<_TaskAssociation?>(
      enabled: false,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;

    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            TaskRulePageMode.add ||
            TaskRulePageMode.duplicate => const Text('Add Task Rule'),
            TaskRulePageMode.edit => const Text('Edit Task Rule'),
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
                    onChanged: (value) => setState(() {}),  // trigger filled
                    decoration: InputDecoration(
                      labelText: 'Task Rule Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter task name',
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == TaskRulePageMode.edit && _nameController.text.trim() != widget.taskRule?.name,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                    onFieldSubmitted: (_) => _saveTaskRule(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: const OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == TaskRulePageMode.edit && _priority != widget.taskRule?.priority,
                    ),
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem<TaskPriority>(
                        value: priority,
                        child: Text(priority.label),
                      );
                    }).toList(),
                    onChanged: (TaskPriority? newValue) {
                      if (newValue != null) {
                        setState(() => _priority = newValue);
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
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add additional details or instructions...',
                      border: const OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == TaskRulePageMode.edit && _notesController.text.trim() != (widget.taskRule?.notes ?? ""),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_TaskAssociation?>(
                    initialValue: _association,
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Linked To',
                      border: const OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == TaskRulePageMode.edit && _association != _initialAssociation,
                    ),
                    items: [
                      _dropdownMenuItemNone(),
                      _dropdownMenuSection("BIKES"),
                      ...bikes.values.map((b) => _dropdownMenuItemBike(b)),
                      _dropdownMenuSection("COMPONENTS"),
                      ...(() {
                        final sorted = components.values.toList()
                          ..sort((a, b) => (a.bike ?? "").compareTo(b.bike ?? ""));
                        return sorted.map((c) => _dropdownMenuItemComponent(c));
                      })(),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _association = v);
                        _changeListener();
                      }
                    },
                  ),
                  const SizedBox(height: 12),                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text("Task Trigger", style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<_ThresholdType>(
                          initialValue: _intervalType,
                          isExpanded: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: "Type",
                            border: const OutlineInputBorder(),
                            fillColor: Colors.orange.withValues(alpha: 0.08),
                            filled: widget.mode == TaskRulePageMode.edit && _intervalType != _getThresholdType(widget.taskRule?.interval),
                          ),
                          items: _ThresholdType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _intervalType = v);
                              _changeListener();
                            }
                          },
                        ),
                      ),
                      switch (_intervalType) {
                        _ThresholdType.none => const SizedBox.shrink(),
                        _ThresholdType.dateTime => Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _intervalDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                setState(() => _intervalDate = d);
                                _changeListener();
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Date",
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today, size: 20),
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.mode == TaskRulePageMode.edit && _intervalDate != (widget.taskRule?.interval is DateTimeThreshold ? (widget.taskRule!.interval as DateTimeThreshold).deadline : null),
                              ),
                              child: Text(
                                _intervalDate == null
                                    ? "Select Date"
                                    : _intervalDate!.toLocal().toString().split(' ')[0],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                        _ThresholdType.activityCount || 
                        _ThresholdType.distance || 
                        _ThresholdType.movingTime || 
                        _ThresholdType.duration => Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _intervalValueController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: "Value",
                              suffixText: switch (_intervalType) {
                                _ThresholdType.distance => 'km',
                                _ThresholdType.movingTime => 'h',
                                _ThresholdType.duration => 'days',
                                _ThresholdType.activityCount => 'rides',
                                _ => '',
                              },
                              border: const OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.mode == TaskRulePageMode.edit && _intervalValueController.text != _getThresholdValueString(widget.taskRule?.interval),
                              //TODO: Add validation for example > 0, double parsable, validate on user interaction
                            ),
                          ),
                        ),
                      },                      
                    ],
                  ),
                  if (_intervalType != _ThresholdType.none && _intervalType != _ThresholdType.dateTime) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      tileColor: widget.mode == TaskRulePageMode.edit && _repeat != (widget.taskRule?.repeat ?? true) ? Colors.orange.withValues(alpha: 0.08) : null,
                      contentPadding: const EdgeInsets.all(12),
                      title: const Text("Repeat Interval"),
                      subtitle: const Text("Restart interval after each entry"),
                      trailing: Switch(
                        value: _repeat,
                        onChanged: (v) {
                          setState(() => _repeat = v);
                          _changeListener();
                        },
                      ),
                    ),
                    if (widget.mode == TaskRulePageMode.edit) ...[
                      const SizedBox(height: 12),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<_ThresholdType>(
                              initialValue: _delayType,
                              isExpanded: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Delay Type (Optional)",
                                border: const OutlineInputBorder(),
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.mode == TaskRulePageMode.edit && _delayType != _getThresholdType(widget.taskRule?.delay),
                              ),
                              items: [_ThresholdType.none, _ThresholdType.distance, _ThresholdType.movingTime, _ThresholdType.duration, _ThresholdType.activityCount]
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _delayType = v);
                                  _changeListener();
                                }
                              },
                              validator: (v) {
                                if (v != null && v != _ThresholdType.none && v != _intervalType) {
                                  return 'Must match trigger type';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_delayType != _ThresholdType.none)
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _delayValueController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Delay Value",
                                  suffixText: switch (_delayType) {
                                    _ThresholdType.distance => 'km',
                                    _ThresholdType.movingTime => 'h',
                                    _ThresholdType.duration => 'days',
                                    _ThresholdType.activityCount => 'rides',
                                    _ => '',
                                  },
                                  border: const OutlineInputBorder(),
                                  fillColor: Colors.orange.withValues(alpha: 0.08),
                                  filled: widget.mode == TaskRulePageMode.edit && _delayValueController.text != _getThresholdValueString(widget.taskRule?.delay),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
