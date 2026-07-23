import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/task/task_association.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold.dart';
import '../repositories/app_repository.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/app_settings_radio_group.dart';
import '../widgets/sheets/set_task_rule_tags.dart';
import '../widgets/sheets/strava.dart';
import '../widgets/sheets/task_association_picker.dart';
import '../widgets/text/section_title.dart';

enum TaskRulePageMode { add, edit, duplicate }

class TaskRulePage extends StatefulWidget {
  final TaskRule? taskRule;
  final TaskRulePageMode mode;
  final TaskAssociation? initialAssociation;

  const TaskRulePage._({super.key, this.taskRule, required this.mode, this.initialAssociation});

  factory TaskRulePage.add({Key? key}) =>
      TaskRulePage._(key: key, mode: TaskRulePageMode.add);

  factory TaskRulePage.addForBike({Key? key, required String bikeId}) =>
      TaskRulePage._(key: key, mode: TaskRulePageMode.add, initialAssociation: BikeTaskAssociation(bikeId));

  factory TaskRulePage.addForComponent({Key? key, required String componentId}) =>
      TaskRulePage._(key: key, mode: TaskRulePageMode.add, initialAssociation: ComponentTaskAssociation(componentId));

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
      componentId: widget.taskRule?.componentId ?? widget.initialAssociation?.componentId,
      bikeId: widget.taskRule?.bikeId ?? widget.initialAssociation?.bikeId,
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
      if (_delayType == _ThresholdType.none) {
        _delayType = _delayTypeForInterval(_intervalType);
      }
    } else {
      _intervalValueController = TextEditingController();
      _delayValueController = TextEditingController();
    }

    _intervalValueController.addListener(_changeListener);
    _delayValueController.addListener(_changeListener);
  }

  /// Types a delay can use. A delay is added on top of the trigger, so it has
  /// to share the trigger's unit — a date deadline has no unit to add to.
  static const Set<_ThresholdType> _delayThresholdTypes = {
    _ThresholdType.distance,
    _ThresholdType.elevation,
    _ThresholdType.movingTime,
    _ThresholdType.elapsedTime,
    _ThresholdType.duration,
    _ThresholdType.activityCount,
  };

  /// An unset delay follows the trigger type, so the only thing left to do is
  /// type a value.
  _ThresholdType _delayTypeForInterval(_ThresholdType intervalType) =>
      _delayThresholdTypes.contains(intervalType) ? intervalType : _ThresholdType.none;

  bool get _hasSavedDelay => widget.taskRule?.delay != null;

  /// A delay exists only once a positive value is typed. An empty field — or an
  /// explicit zero, offered as a way to drop a delay that was already saved —
  /// means "no delay", so the preselected type never becomes a delay of zero.
  bool get _hasDelayValue {
    final raw = _delayValueController.text.trim();
    if (raw.isEmpty) return false;
    final parsed = double.tryParse(raw);
    return parsed != null && parsed > 0;
  }

  _ThresholdType get _effectiveDelayType =>
      _hasDelayValue ? _delayType : _ThresholdType.none;

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
      case DistanceThreshold(): return NumberFormat('0.#####', 'en_US').format(threshold.meters / 1000);
      case ElevationThreshold(): return NumberFormat('0.#####', 'en_US').format(threshold.meters);
      case ActivityCountThreshold(): return threshold.count.toString();
      case MovingTimeThreshold(): return threshold.hours.inHours.toString();
      case ElapsedTimeThreshold(): return threshold.hours.inHours.toString();
      case DurationThreshold(): return threshold.days.inDays.toString();
      case DateTimeThreshold(): return '';
    }
  }

  bool _valueChanged(TextEditingController controller, TaskThreshold? saved) {
    return double.tryParse(controller.text.trim()) != double.tryParse(_getThresholdValueString(saved));
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
        _valueChanged(_intervalValueController, widget.taskRule?.interval) ||
        (_intervalType == _ThresholdType.dateTime && _intervalDate != (widget.taskRule?.interval is DateTimeThreshold ? (widget.taskRule!.interval as DateTimeThreshold).deadline : null)) ||
        _effectiveDelayType != _getThresholdType(widget.taskRule?.delay) ||
        _valueChanged(_delayValueController, widget.taskRule?.delay);

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
      _thresholdNeedsAsset(_intervalType) || _thresholdNeedsAsset(_effectiveDelayType);

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

  String? _validateDelayValue(String? value) {
    // The type is only a preselection until a value is typed, so an empty
    // field is valid and simply means "no delay".
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    // Zero reads as "drop the delay", which only makes sense for a delay that
    // is already saved. _saveTaskRule then stores no delay at all.
    if (_hasSavedDelay && double.tryParse(raw) == 0) return null;
    return _validateThresholdValue(_delayType, value);
  }

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
    final delay = (_intervalType == _ThresholdType.dateTime || !_hasDelayValue)
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

  /// Closed state of the "Linked To" field. Two lines rather than two columns,
  /// so a long component name and a long bike name each ellipsize on their own.
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
                // Same text style DropdownButton applies to its value, so this
                // field reads identically to the type field on ComponentPage.
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
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
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
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
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
            backgroundColor: widget.mode == TaskRulePageMode.edit && _priority != widget.taskRule?.priority ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
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
          backgroundColor: widget.mode == TaskRulePageMode.edit && !widget.taskRule!.tags.contains(tag)
              ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
              : null,
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
                        FormField<TaskAssociation>(
                          initialValue: _association,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (TaskAssociation? ta) {
                            if (_needsAsset && (ta == null || ta is GeneralTaskAssociation)) {
                              return 'The selected trigger needs a linked Bike or Component';
                            }
                            return null;
                          },
                          builder: (field) {
                            return InkWell(
                              onTap: () async {
                                final picked = await showTaskAssociationSheet(
                                  context: context,
                                  selected: _association,
                                  // Highlighting is an "changed vs. saved" cue, so it
                                  // only applies when editing an existing rule.
                                  initial: widget.mode == TaskRulePageMode.edit
                                      ? _initialAssociation
                                      : null,
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
                                  errorText: field.errorText,
                                  suffixIcon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == TaskRulePageMode.edit && _association != _initialAssociation,
                                  helperText: (_association is ComponentTaskAssociation &&
                                          components[_association.componentId]?.isArchived == true)
                                      ? 'WARNING: Tasks of archived components are hidden in the task list.'
                                      : null,
                                  helperMaxLines: 3,
                                  helperStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                                child: _associationDisplay(bikes, components),
                              ),
                            );
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
                                    fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    filled: widget.mode == TaskRulePageMode.edit && _intervalType != _getThresholdType(widget.taskRule?.interval),
                                  ),
                                  items: _intervalTypeItems(hasStravaEntitlement),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        _intervalType = v;
                                        // Keep an unset delay pointed at the new
                                        // trigger; a typed one keeps its type so
                                        // the mismatch stays visible.
                                        if (!_hasDelayValue) {
                                          _delayType = _delayTypeForInterval(v);
                                        }
                                      });
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
                                            fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
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
                                      fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                      filled: widget.mode == TaskRulePageMode.edit && _valueChanged(_intervalValueController, widget.taskRule?.interval),
                                    ),
                                  ),
                                ),
                              },
                            ],
                          ),
                          if (!hasStravaEntitlement) _stravaTriggerBanner(context),
                          if (_intervalType != _ThresholdType.none && _intervalType != _ThresholdType.dateTime) ...[
                            ListTile(
                              tileColor: widget.mode == TaskRulePageMode.edit && _repeat != (widget.taskRule?.repeat ?? true)
                                  ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                                  : null,
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
                              const SizedBox(height: 36),
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
                                        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                        filled: widget.mode == TaskRulePageMode.edit && _effectiveDelayType != _getThresholdType(widget.taskRule?.delay),
                                      ),
                                      items: [_ThresholdType.none, ..._delayThresholdTypes]
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _delayType = v);
                                          _changeListener();
                                        }
                                      },
                                      validator: (v) {
                                        if (_hasDelayValue && v != null && v != _ThresholdType.none && v != _intervalType) {
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
                                          suffixIcon: _delayValueController.text.isEmpty
                                              ? null
                                              : IconButton(
                                                  icon: const Icon(Icons.clear, size: 20),
                                                  tooltip: 'Clear',
                                                  onPressed: () {
                                                    _delayValueController.clear();
                                                    setState(() {});
                                                  },
                                                ),
                                          border: const OutlineInputBorder(),
                                          fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                          filled: widget.mode == TaskRulePageMode.edit && _valueChanged(_delayValueController, widget.taskRule?.delay),
                                        ),
                                        onChanged: (value) => setState(() {}),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                                child: Text(
                                  "A delay postpones when this task becomes due, without changing its interval. It only applies once: completing the task clears the delay automatically.",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
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
