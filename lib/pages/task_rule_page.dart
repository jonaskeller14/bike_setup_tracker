import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/task/task_association.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold.dart';
import '../repositories/app_repository.dart';
import '../services/subscription_service.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/app_settings_radio_group.dart';
import '../widgets/sheets/set_task_rule_tags.dart';
import '../widgets/sheets/strava.dart';
import '../widgets/text/section_title.dart';

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

enum _ThresholdType {
  none('None'),
  distance('Distance'),
  elevation('Elevation'),
  movingTime('Moving Time'),
  elapsedTime('Elapsed Time'),
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
  Set<String> _tags = {};
  Set<String> _initialTags = {};
  late TaskAssociation _association;
  late TaskAssociation _initialAssociation;
  
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

    _association = TaskAssociation.fromIds(
      componentId: widget.taskRule?.componentId,
      bikeId: widget.taskRule?.bikeId,
    );
    _initialAssociation = _association;

    final appRepository = context.read<AppRepository>();
    _tags.addAll(widget.taskRule?.tags ?? appRepository.selectedTaskRuleTags);
    _initialTags = _tags;
    
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
      case ElevationThreshold(): return _ThresholdType.elevation;
      case MovingTimeThreshold(): return _ThresholdType.movingTime;
      case ElapsedTimeThreshold(): return _ThresholdType.elapsedTime;
      case DurationThreshold(): return _ThresholdType.duration;
      case ActivityCountThreshold(): return _ThresholdType.activityCount;
      case DateTimeThreshold(): return _ThresholdType.dateTime;
    }
  }

  String _getThresholdValueString(TaskThreshold? threshold) {
    switch (threshold) {
      case null: return "";
      case DistanceThreshold(): return (threshold.meters / 1000).toStringAsFixed(1);
      case ElevationThreshold(): return threshold.meters.toStringAsFixed(0);
      case ActivityCountThreshold(): return threshold.count.toString();
      case MovingTimeThreshold(): return threshold.hours.inHours.toString();
      case ElapsedTimeThreshold(): return threshold.hours.inHours.toString();
      case DurationThreshold(): return threshold.days.inDays.toString();
      case DateTimeThreshold(): return ''; 
    }
  }

  void _changeListener() {
    final hasChanges =
        _nameController.text.trim() != (widget.taskRule?.name ?? '') ||
        _notesController.text.trim() != (widget.taskRule?.notes ?? '') ||
        _priority != (widget.taskRule?.priority ?? TaskPriority.medium) ||
        !setEquals(_tags, _initialTags) ||
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

  static const Set<_ThresholdType> _stravaThresholdTypes = {
    _ThresholdType.distance,
    _ThresholdType.elevation,
    _ThresholdType.movingTime,
    _ThresholdType.elapsedTime,
    _ThresholdType.activityCount,
  };

  List<DropdownMenuItem<_ThresholdType?>> _intervalTypeItems(bool hasStravaEntitlement) {
    DropdownMenuItem<_ThresholdType?> sectionHeader(String label) {
      return DropdownMenuItem<_ThresholdType?>(
        enabled: false,
        value: null,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
        ),
      );
    }

    DropdownMenuItem<_ThresholdType?> typeItem(_ThresholdType type) {
      final locked = _stravaThresholdTypes.contains(type) && !hasStravaEntitlement;
      return DropdownMenuItem<_ThresholdType?>(
        value: type,
        enabled: !locked,
        child: Row(
          spacing: 6,
          children: [
            Flexible(
              child: Text(
                type.label,
                overflow: TextOverflow.ellipsis,
                style: locked ? TextStyle(color: Theme.of(context).disabledColor) : null,
              ),
            ),
            if (locked) Icon(Icons.lock_outline, size: 14, color: Theme.of(context).disabledColor),
          ],
        ),
      );
    }

    return [
      typeItem(_ThresholdType.none),
      sectionHeader("TIME-BASED"),
      typeItem(_ThresholdType.duration),
      typeItem(_ThresholdType.dateTime),
      sectionHeader("ACTIVITY-BASED (STRAVA)"),
      typeItem(_ThresholdType.distance),
      typeItem(_ThresholdType.elevation),
      typeItem(_ThresholdType.movingTime),
      typeItem(_ThresholdType.elapsedTime),
      typeItem(_ThresholdType.activityCount),
    ];
  }

  Widget _stravaTriggerBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(Icons.lock_outline, size: 20, color: colorScheme.onSurfaceVariant),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Activity-based triggers need Strava", style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  "Distance, elevation, time and ride-count triggers update automatically from your Strava activities.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showStravaSheet(context: context),
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  bool _thresholdNeedsAsset(_ThresholdType type) {
    switch (type) {
      case _ThresholdType.distance:
      case _ThresholdType.elevation:
      case _ThresholdType.movingTime:
      case _ThresholdType.elapsedTime:
      case _ThresholdType.activityCount:
        return true;
      case _ThresholdType.none:
      case _ThresholdType.duration:
      case _ThresholdType.dateTime:
        return false;
    }
  }

  bool get _needsAsset =>
      _thresholdNeedsAsset(_intervalType) || _thresholdNeedsAsset(_delayType);

  List<TextInputFormatter>? _valueInputFormatters(_ThresholdType type) {
    return switch (type) {
      _ThresholdType.distance ||
      _ThresholdType.elevation => [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
      _ThresholdType.movingTime ||
      _ThresholdType.elapsedTime ||
      _ThresholdType.duration ||
      _ThresholdType.activityCount => [FilteringTextInputFormatter.digitsOnly],
      _ThresholdType.dateTime ||
      _ThresholdType.none => null,
    };
  }

  bool _thresholdRequiresInteger(_ThresholdType type) {
    return switch (type) {
      _ThresholdType.movingTime ||
      _ThresholdType.elapsedTime ||
      _ThresholdType.duration ||
      _ThresholdType.activityCount => true,
      _ThresholdType.distance ||
      _ThresholdType.elevation ||
      _ThresholdType.dateTime ||
      _ThresholdType.none => false,
    };
  }

  String? _validateThresholdValue(_ThresholdType type, String? rawValue) {
    if (type == _ThresholdType.none || type == _ThresholdType.dateTime) {
      return null;
    }

    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return 'Enter a value';
    }

    final requiresInteger = _thresholdRequiresInteger(type);
    final num? parsed = requiresInteger ? int.tryParse(value) : double.tryParse(value);
    if (parsed == null) {
      return requiresInteger ? 'Enter a whole number' : 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Must be greater than 0';
    }
    return null;
  }

  String? _validateIntervalValue(String? value) => _validateThresholdValue(_intervalType, value);

  String? _validateDelayValue(String? value) => _validateThresholdValue(_delayType, value);

  TaskThreshold? _createThreshold(_ThresholdType type, String value, DateTime? date) {
    if (type == _ThresholdType.none) return null;
    final doubleVal = double.tryParse(value) ?? 0;
    final intVal = int.tryParse(value) ?? 0;

    switch (type) {
      case _ThresholdType.distance:
        return DistanceThreshold(doubleVal * 1000);
      case _ThresholdType.elevation:
        return ElevationThreshold(doubleVal);
      case _ThresholdType.movingTime:
        return MovingTimeThreshold(Duration(hours: intVal));
      case _ThresholdType.elapsedTime:
        return ElapsedTimeThreshold(Duration(hours: intVal));
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
        tags: _tags,
        componentId: _association.componentId,
        bikeId: _association.bikeId,
        interval: interval,
        delay: delay,
        repeat: (_intervalType == _ThresholdType.dateTime || _intervalType == _ThresholdType.none) ? false : _repeat,
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

  DropdownMenuItem<TaskAssociation> _dropdownMenuItemNone() {
    return const DropdownMenuItem<TaskAssociation>(
      value: GeneralTaskAssociation(),
      child: Row(
        spacing: 8,
        children: [
          Icon(Icons.circle_outlined),
          Text("General Task"),
        ],
      ),
    );
  }

  DropdownMenuItem<TaskAssociation> _dropdownMenuItemBike(Bike bike) {
    return DropdownMenuItem<TaskAssociation>(
      value: BikeTaskAssociation(bike.id),
      child: Row(
        spacing: 8,
        children: [
          const Icon(Bike.iconData),
          Expanded(child: Text(bike.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  DropdownMenuItem<TaskAssociation> _dropdownMenuItemComponent(Component component, Map<String, Bike> bikes) {
    return DropdownMenuItem<TaskAssociation>(
      value: ComponentTaskAssociation(component.id),
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

  DropdownMenuItem<TaskAssociation> _dropdownMenuItemMissing(TaskAssociation association, {String? label}) {
    final String resolvedLabel;
    final IconData icon;

    if (label != null) {
      resolvedLabel = label;
      icon = association.bikeId != null ? Bike.iconData : Icons.grid_view_sharp;
    } else if (association.bikeId != null) {
      resolvedLabel = "BIKE NOT FOUND";
      icon = Bike.iconData;
    } else if (association.componentId != null) {
      resolvedLabel = "COMPONENT NOT FOUND";
      icon = Icons.grid_view_sharp;
    } else {
      resolvedLabel = "ENTRY NOT FOUND";
      icon = Icons.help_outline_rounded;
    }

    return DropdownMenuItem<TaskAssociation>(
      value: association,
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.error),
          Text(
            resolvedLabel,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<TaskAssociation?> _dropdownMenuSection(String label) {
    return DropdownMenuItem<TaskAssociation?>(
      enabled: false,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  TextFormField _nameTextFormField() {
    return TextFormField(
      controller: _nameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: widget.mode == TaskRulePageMode.add,
      onChanged: (value) => setState(() {}),  // trigger filled
      decoration: InputDecoration(
        labelText: 'Task Rule Name',
        border: const OutlineInputBorder(),
        hintText: 'Enter task name',
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == TaskRulePageMode.edit && _nameController.text.trim() != widget.taskRule?.name,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
      onFieldSubmitted: (_) => _saveTaskRule(),
    );
  }

  TextFormField _notesTextFormField() {
    return TextFormField(
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
    );
  }

  Wrap _wrap() {
    final appSettings = context.watch<AppSettings>();
    final enableTaskTags = appSettings.enableTaskTags;
    final enableTaskPriority = appSettings.enableTaskPriority;
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        if (enableTaskPriority)
          ActionChip(
            avatar: const Icon(Icons.traffic),
            label: Text(_priority.label),
            backgroundColor: widget.mode == TaskRulePageMode.edit && _priority != widget.taskRule?.priority ? Colors.orange.withValues(alpha: 0.08) : null,
            onPressed: () => appSettingsRadioGroupSheet<TaskPriority>(
              context: context,
              title: "Task Priority",
              value: _priority,
              onChanged: (TaskPriority? newValue) {
                if (newValue == null) return;
                setState(() => _priority = newValue);
                Navigator.pop(context);
                _changeListener();
              },
              optionWidgets: Map.fromEntries(TaskPriority.values.map((priority) {
                return MapEntry(
                  priority,
                  Text(priority.label),
                );
              })),
            ),
          ),
        if (enableTaskTags) ..._tags.map((tag) => FilterChip(
          avatar: const Icon(Icons.tag),
          showCheckmark: false,
          selected: widget.mode != TaskRulePageMode.edit,
          label: Text(tag),
          onSelected: (_) {
            setState(() => _tags.remove(tag));
            _changeListener();
          },
          onDeleted: () {
            setState(() => _tags.remove(tag));
            _changeListener();
          },
          backgroundColor: widget.mode == TaskRulePageMode.edit && !widget.taskRule!.tags.contains(tag) ? Colors.orange.withValues(alpha: 0.08) : null,
        )),
        if (enableTaskTags)
          ActionChip(
            avatar: const Icon(Icons.add),
            label: const Text("Tags"),
            onPressed: () async {
              await showSetTaskRuleTagsSheet(
                context: context,
                tags: _tags,
                onChanged: (Set<String> newTags) {
                  setState(() => _tags = newTags);
                  _changeListener();
                },
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;
    final hasStravaEntitlement = context.watch<SubscriptionService>().hasStravaEntitlement;

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _nameTextFormField(),
                        const SizedBox(height: 12),
                        _notesTextFormField(),
                        const SizedBox(height: 12),
                        _wrap(),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<TaskAssociation?>(
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
                            ...[
                              if (_association is BikeTaskAssociation && !bikes.containsKey(_association.bikeId))
                                _dropdownMenuItemMissing(_association),
                            ],
                            _dropdownMenuSection("COMPONENTS"),
                            ...(() {
                              final sorted = components.values
                                  .where((c) => !c.isArchived)
                                  .toList()
                                ..sort((a, b) => (a.bike ?? "").compareTo(b.bike ?? ""));
                              return sorted.map((c) => _dropdownMenuItemComponent(c, bikes));
                            })(),
                            ...[
                              if (_association is ComponentTaskAssociation && !components.containsKey(_association.componentId))
                                _dropdownMenuItemMissing(_association),
                              if (_association is ComponentTaskAssociation &&
                                  components.containsKey(_association.componentId) &&
                                  components[_association.componentId]!.isArchived)
                                _dropdownMenuItemMissing(
                                  _association,
                                  label: "COMPONENT ARCHIVED",
                                ),
                            ],
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _association = v);
                              _changeListener();
                            }
                          },
                          validator: (TaskAssociation? ta) {
                            if (_needsAsset && (ta == null || ta is GeneralTaskAssociation)) {
                              return 'The selected trigger needs a linked Bike or Component';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (appSettings.enableTaskInterval) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SectionTitle(title: "Task Trigger", infoText: "(Optional) Set a task trigger to display a progress bar that updates automatically based on activity stats or time."),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<_ThresholdType?>(
                                  initialValue: _intervalType,
                                  isExpanded: true,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: "Type",
                                    border: const OutlineInputBorder(),
                                    fillColor: Colors.orange.withValues(alpha: 0.08),
                                    filled: widget.mode == TaskRulePageMode.edit && _intervalType != _getThresholdType(widget.taskRule?.interval),
                                  ),
                                  items: _intervalTypeItems(hasStravaEntitlement),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _intervalType = v);
                                      _changeListener();
                                    }
                                  },
                                ),
                              ),
                              ?switch (_intervalType) {
                                _ThresholdType.none => null,
                                _ThresholdType.dateTime => Expanded(
                                  child: FormField<DateTime>(
                                    initialValue: _intervalDate,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    validator: (value) => value == null ? 'Select a date' : null,
                                    builder: (field) {
                                      return InkWell(
                                        onTap: () async {
                                          final d = await showDatePicker(
                                            context: context,
                                            initialDate: _intervalDate ?? DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (d != null) {
                                            setState(() => _intervalDate = d);
                                            field.didChange(d);
                                            _changeListener();
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: "Date",
                                            border: const OutlineInputBorder(),
                                            suffixIcon: const Icon(Icons.calendar_today, size: 20),
                                            errorText: field.errorText,
                                            fillColor: Colors.orange.withValues(alpha: 0.08),
                                            filled: widget.mode == TaskRulePageMode.edit && _intervalDate != (widget.taskRule?.interval is DateTimeThreshold ? (widget.taskRule!.interval as DateTimeThreshold).deadline : null),
                                          ),
                                          child: Text(
                                            _intervalDate == null
                                                ? "Select Date"
                                                : DateFormat(appSettings.dateFormat).format(_intervalDate!.toLocal()),
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _ThresholdType.activityCount ||
                                _ThresholdType.distance ||
                                _ThresholdType.elevation ||
                                _ThresholdType.movingTime ||
                                _ThresholdType.elapsedTime ||
                                _ThresholdType.duration => Expanded(
                                  child: TextFormField(
                                    controller: _intervalValueController,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    keyboardType: TextInputType.numberWithOptions(
                                      decimal: _intervalType == _ThresholdType.distance || _intervalType == _ThresholdType.elevation,
                                      signed: false,
                                    ),
                                    inputFormatters: _valueInputFormatters(_intervalType),
                                    onChanged: (value) => setState(() {}),
                                    validator: _validateIntervalValue,
                                    decoration: InputDecoration(
                                      labelText: "Value",
                                      suffixText: switch (_intervalType) {
                                        _ThresholdType.distance => 'km',
                                        _ThresholdType.elevation => 'm',
                                        _ThresholdType.movingTime => 'h',
                                        _ThresholdType.elapsedTime => 'h',
                                        _ThresholdType.duration => 'days',
                                        _ThresholdType.activityCount => 'rides',
                                        _ => '',
                                      },
                                      border: const OutlineInputBorder(),
                                      fillColor: Colors.orange.withValues(alpha: 0.08),
                                      filled: widget.mode == TaskRulePageMode.edit && _intervalValueController.text != _getThresholdValueString(widget.taskRule?.interval),
                                    ),
                                  ),
                                ),
                              },
                            ],
                          ),
                          if (!hasStravaEntitlement) _stravaTriggerBanner(context),
                          if (_intervalType != _ThresholdType.none && _intervalType != _ThresholdType.dateTime) ...[
                            ListTile(
                              tileColor: widget.mode == TaskRulePageMode.edit && _repeat != (widget.taskRule?.repeat ?? true) ? Colors.orange.withValues(alpha: 0.08) : null,
                              contentPadding: const EdgeInsets.all(12),
                              title: const Text("Repeat Interval"),
                              subtitle: const Text("Restart interval after each entry"),
                              trailing: Switch.adaptive(
                                value: _repeat,
                                onChanged: (v) {
                                  setState(() => _repeat = v);
                                  _changeListener();
                                },
                              ),
                            ),
                            if (widget.mode == TaskRulePageMode.edit && appSettings.enableTaskDelay) ...[
                              const SizedBox(height: 12),
                              //TODO: If delay must match trigger type --> a value field is sufficient
                              //TODO: Add user info --> What is a delay?
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 8,
                                children: [
                                  Expanded(
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
                                      items: [_ThresholdType.none, _ThresholdType.distance, _ThresholdType.elevation, _ThresholdType.movingTime, _ThresholdType.elapsedTime, _ThresholdType.duration, _ThresholdType.activityCount]
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
                                      child: TextFormField(
                                        controller: _delayValueController,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        keyboardType: TextInputType.numberWithOptions(
                                          decimal: _delayType == _ThresholdType.distance || _delayType == _ThresholdType.elevation,
                                          signed: false,
                                        ),
                                        inputFormatters: _valueInputFormatters(_delayType),
                                        validator: _validateDelayValue,
                                        decoration: InputDecoration(
                                          labelText: "Delay Value",
                                          suffixText: switch (_delayType) {
                                            _ThresholdType.distance => 'km',
                                            _ThresholdType.elevation => 'm',
                                            _ThresholdType.movingTime => 'h',
                                            _ThresholdType.elapsedTime => 'h',
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
