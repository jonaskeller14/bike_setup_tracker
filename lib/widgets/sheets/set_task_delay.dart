import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/app_settings.dart';
import '../../models/task/task_rule.dart';
import '../../models/task/task_threshold.dart';
import '../task_rule_display_card.dart';
import 'sheet_header.dart';

bool _intervalSupportsDelay(TaskThreshold interval) {
  return switch (interval) {
    DistanceThreshold() ||
    ElevationThreshold() ||
    MovingTimeThreshold() ||
    ElapsedTimeThreshold() ||
    DurationThreshold() ||
    ActivityCountThreshold() => true,
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

String _delaySuffix(TaskThreshold interval) {
  return switch (interval) {
    DistanceThreshold() => 'km',
    ElevationThreshold() => 'm',
    MovingTimeThreshold() || ElapsedTimeThreshold() => 'h',
    DurationThreshold() => 'days',
    ActivityCountThreshold() => 'rides',
    DateTimeThreshold() => '',
  };
}

bool _acceptsDecimals(TaskThreshold interval) =>
    interval is DistanceThreshold || interval is ElevationThreshold;

String _delayValueString(TaskThreshold? delay) {
  return switch (delay) {
    null => '',
    DistanceThreshold() => NumberFormat('0.#####', 'en_US').format(delay.meters / 1000),
    ElevationThreshold() => NumberFormat('0.#####', 'en_US').format(delay.meters),
    MovingTimeThreshold() => delay.hours.inHours.toString(),
    ElapsedTimeThreshold() => delay.hours.inHours.toString(),
    DurationThreshold() => delay.days.inDays.toString(),
    ActivityCountThreshold() => delay.count.toString(),
    DateTimeThreshold() => '',
  };
}

/// Builds a delay of the same type as [interval], or null when [rawValue] is
/// empty or unparsable.
TaskThreshold? _buildDelay(TaskThreshold interval, String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) return null;

  if (_acceptsDecimals(interval)) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return null;
    return switch (interval) {
      DistanceThreshold() => DistanceThreshold(parsed * 1000),
      _ => ElevationThreshold(parsed),
    };
  }

  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) return null;
  return switch (interval) {
    MovingTimeThreshold() => MovingTimeThreshold(Duration(hours: parsed)),
    ElapsedTimeThreshold() => ElapsedTimeThreshold(Duration(hours: parsed)),
    DurationThreshold() => DurationThreshold(Duration(days: parsed)),
    _ => ActivityCountThreshold(parsed),
  };
}

Future<TaskRule?> showSetTaskDelaySheet({
  required BuildContext context,
  required TaskRule taskRule,
}) {
  return showModalBottomSheet<TaskRule>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) => _SetTaskDelaySheet(taskRule: taskRule),
  );
}

class _SetTaskDelaySheet extends StatefulWidget {
  final TaskRule taskRule;

  const _SetTaskDelaySheet({required this.taskRule});

  @override
  State<_SetTaskDelaySheet> createState() => _SetTaskDelaySheetState();
}

class _SetTaskDelaySheetState extends State<_SetTaskDelaySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TaskThreshold _interval;

  @override
  void initState() {
    super.initState();
    _interval = widget.taskRule.interval!;
    final initialValue = _delayValueString(widget.taskRule.delay);
    _valueController = TextEditingController(text: initialValue)
      // Preselect so typing replaces the existing delay instead of appending.
      ..selection = TextSelection(baseOffset: 0, extentOffset: initialValue.length);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  bool get _hadDelay => widget.taskRule.delay != null;

  TaskThreshold? get _delay => _buildDelay(_interval, _valueController.text);

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
    if (parsed == 0 && _hadDelay) return null;
    if (parsed <= 0) return 'Must be greater than 0';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, widget.taskRule.copyWith(delay: _delay));
  }

  @override
  Widget build(BuildContext context) {
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
                                  signed: false,
                                ),
                                inputFormatters: _acceptsDecimals(_interval)
                                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))]
                                    : [FilteringTextInputFormatter.digitsOnly],
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => setState(() {}),
                                onFieldSubmitted: (_) => _save(),
                                validator: _validate,
                                decoration: InputDecoration(
                                  labelText: 'Delay Value',
                                  suffixText: _delaySuffix(_interval),
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
                        'A delay postpones when this task becomes due, without changing '
                        'its interval. It only applies once: completing the task clears '
                        'the delay automatically.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
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
