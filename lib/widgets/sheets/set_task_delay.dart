import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_position.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_threshold/task_threshold.dart';
import '../../theme.dart';
import '../items/task_rule_display_card.dart';
import 'sheet_header.dart';

bool _intervalSupportsDelay(TaskThreshold interval) {
  return switch (interval) {
    DistanceThreshold() ||
    ElevationThreshold() ||
    MovingTimeThreshold() ||
    ElapsedTimeThreshold() ||
    DurationThreshold() ||
    ActivityCountThreshold() ||
    KilojoulesThreshold() => true,
    DateTimeThreshold() => false,
  };
}

bool canQuickEditTaskDelay(TaskRule taskRule, AppSettings appSettings) {
  if (!appSettings.enableTaskInterval || !appSettings.enableTaskDelay) return false;

  final interval = taskRule.interval;
  if (interval == null || !_intervalSupportsDelay(interval)) return false;

  final delay = taskRule.delay;
  return delay == null || delay.runtimeType == interval.runtimeType;
}

String _delaySuffix(TaskThreshold interval, AppSettings appSettings) {
  return switch (interval) {
    DistanceThreshold() => appSettings.distanceUnit,
    ElevationThreshold() => appSettings.altitudeUnit,
    MovingTimeThreshold() || ElapsedTimeThreshold() => 'h',
    DurationThreshold() => 'days',
    ActivityCountThreshold() => 'rides',
    KilojoulesThreshold() => 'kJ',
    DateTimeThreshold() => '',
  };
}

bool _acceptsDecimals(TaskThreshold interval) =>
    interval is DistanceThreshold || interval is ElevationThreshold || interval is KilojoulesThreshold;

/// Lets a delay value through only while it still reads as a (partly typed)
/// number. A negative delay brings the due point forward.
TextInputFormatter signedDelayInputFormatter({required bool decimal}) {
  final pattern = decimal ? RegExp(r'^-?\d*\.?\d*$') : RegExp(r'^-?\d*$');
  return TextInputFormatter.withFunction(
    (oldValue, newValue) => pattern.hasMatch(newValue.text) ? newValue : oldValue,
  );
}

String _delayValueString(TaskThreshold? delay, AppSettings appSettings) {
  return switch (delay) {
    null => '',
    DistanceThreshold() => NumberFormat('0.#####', 'en_US')
        .format(AppSettings.convertDistanceFromMeters(delay.meters, appSettings.distanceUnit)!),
    ElevationThreshold() => NumberFormat('0.#####', 'en_US')
        .format(AppSettings.convertElevationFromMeters(delay.meters, appSettings.altitudeUnit)!),
    MovingTimeThreshold() => delay.hours.inHours.toString(),
    ElapsedTimeThreshold() => delay.hours.inHours.toString(),
    DurationThreshold() => delay.days.inDays.toString(),
    ActivityCountThreshold() => delay.count.toString(),
    KilojoulesThreshold() => NumberFormat('0.#####', 'en_US').format(delay.kilojoules),
    DateTimeThreshold() => '',
  };
}

/// Builds a delay of the same type as [interval], or null when [rawValue] is
/// empty, zero or unparsable.
TaskThreshold? _buildDelay(TaskThreshold interval, String rawValue, AppSettings appSettings) {
  final value = rawValue.trim();
  if (value.isEmpty) return null;

  if (_acceptsDecimals(interval)) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed == 0) return null;
    return switch (interval) {
      DistanceThreshold() =>
        DistanceThreshold(AppSettings.convertDistanceToMeters(parsed, appSettings.distanceUnit)!),
      KilojoulesThreshold() => KilojoulesThreshold(parsed),
      _ => ElevationThreshold(ContextPosition.convertAltitudeToMeters(parsed, appSettings.altitudeUnit)!),
    };
  }

  final parsed = int.tryParse(value);
  if (parsed == null || parsed == 0) return null;
  return switch (interval) {
    MovingTimeThreshold() => MovingTimeThreshold(Duration(hours: parsed)),
    ElapsedTimeThreshold() => ElapsedTimeThreshold(Duration(hours: parsed)),
    DurationThreshold() => DurationThreshold(Duration(days: parsed)),
    _ => ActivityCountThreshold(parsed),
  };
}

/// [dueNowDelay] works out the delay that makes the task due right away;
/// without it the "Make Due Now" option is hidden.
Future<TaskRule?> showSetTaskDelaySheet({
  required BuildContext context,
  required TaskRule taskRule,
  ValueGetter<TaskThreshold?>? dueNowDelay,
}) {
  return showModalBottomSheet<TaskRule>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => _SetTaskDelaySheet(taskRule: taskRule, dueNowDelay: dueNowDelay),
  );
}

class _SetTaskDelaySheet extends StatefulWidget {
  final TaskRule taskRule;
  final ValueGetter<TaskThreshold?>? dueNowDelay;

  const _SetTaskDelaySheet({required this.taskRule, this.dueNowDelay});

  @override
  State<_SetTaskDelaySheet> createState() => _SetTaskDelaySheetState();
}

class _SetTaskDelaySheetState extends State<_SetTaskDelaySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TaskThreshold _interval;
  late final String _initialValue;

  /// The delay the field text stands for while it still reads [_exactValue].
  /// The text is rounded, and a "Make Due Now" delay rebuilt from it could fall
  /// just short of due.
  late TaskThreshold? _exactDelay;
  late String _exactValue;

  @override
  void initState() {
    super.initState();
    _interval = widget.taskRule.interval!;
    _initialValue = _delayValueString(widget.taskRule.delay, context.read<AppSettings>());
    _exactDelay = widget.taskRule.delay;
    _exactValue = _initialValue;
    _valueController = TextEditingController(text: _initialValue)
      // Preselect so typing replaces the existing delay instead of appending.
      ..selection = TextSelection(baseOffset: 0, extentOffset: _initialValue.length);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  bool get _hadDelay => widget.taskRule.delay != null;

  bool get _valueChanged =>
      double.tryParse(_valueController.text.trim()) != double.tryParse(_initialValue);

  TaskThreshold? get _delay => double.tryParse(_valueController.text.trim()) == double.tryParse(_exactValue)
      ? _exactDelay
      : _buildDelay(_interval, _valueController.text, context.read<AppSettings>());

  String? _validate(String? rawValue) {
    // An empty field clears the delay, so it stays valid.
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return null;

    final decimal = _acceptsDecimals(_interval);
    final num? parsed = decimal ? double.tryParse(value) : int.tryParse(value);
    if (parsed == null) {
      return decimal ? 'Enter a valid number' : 'Enter a whole number';
    }
    // Zero reads as "drop the delay", which only makes sense for a delay that
    // is already there — _buildDelay turns it into no delay at all.
    if (parsed == 0) return _hadDelay ? null : 'Must not be 0';
    final interval = _interval;
    if (interval is AccumulatingThreshold &&
        interval.totalTarget(_buildDelay(interval, value, context.read<AppSettings>())) < 0) {
      return 'Cannot bring it forward by more than its interval';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, widget.taskRule.copyWith(delay: _delay));
  }

  void _makeDueNow() {
    unawaited(HapticFeedback.selectionClick());
    final delay = widget.dueNowDelay!();
    final value = _delayValueString(delay, context.read<AppSettings>());
    setState(() {
      _exactDelay = delay;
      _exactValue = value;
      _valueController.text = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: _hadDelay ? 'Edit Delay' : 'Add Delay'),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TaskRuleDisplayCard(
                        taskRule: widget.taskRule.copyWith(delay: _delay),
                        showStatus: true,
                        showForcast: false,
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _valueController,
                                autofocus: true,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: _acceptsDecimals(_interval),
                                  signed: true,
                                ),
                                inputFormatters: [signedDelayInputFormatter(decimal: _acceptsDecimals(_interval))],
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => setState(() {}),
                                onFieldSubmitted: (_) => _save(),
                                validator: _validate,
                                decoration: InputDecoration(
                                  labelText: 'Delay Value',
                                  errorMaxLines: 2,
                                  suffixText: _delaySuffix(_interval, appSettings),
                                  suffixIcon: _valueController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          tooltip: 'Clear',
                                          onPressed: () {
                                            _valueController.clear();
                                            setState(() {});
                                          },
                                        ),
                                  border: const OutlineInputBorder(),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: _hadDelay && _valueChanged,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 58, // matches the outlined field height
                              child: FilledButton(
                                onPressed: _save,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A delay postpones when this task becomes due, or brings it forward '
                        'when negative, without changing its interval. It only applies once: '
                        'completing the task clears the delay automatically.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      if (widget.dueNowDelay != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.update),
                            label: const Text('Make Due Now'),
                            onPressed: _makeDueNow,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
