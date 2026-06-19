import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';

void showSetDurationSheet({
  required BuildContext context, 
  required DurationAdjustment adjustment, 
  required Duration? value, 
  required ValueChanged<Duration> onChanged
}) async {
  Duration currentValue = value ?? Duration.zero;
  return await showModalBottomSheet<void>(
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bool isBelowMin = adjustment.min != null && currentValue < adjustment.min!;
          final bool isAboveMax = adjustment.max != null && currentValue > adjustment.max!;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (adjustment.min != null || adjustment.max != null)
                  Row(
                    children: [
                      if (adjustment.min != null)
                        Expanded(
                          child: ListTile(
                            leading: Icon(
                              Icons.vertical_align_bottom,
                              color: isBelowMin ? Theme.of(context).colorScheme.error : null,
                            ),
                            title: Text(
                              "Min: ${Adjustment.formatValue(adjustment.min)}",
                              style: TextStyle(color: isBelowMin ? Theme.of(context).colorScheme.error : null),
                            ),
                            dense: true,
                          ),
                        ),
                      if (adjustment.max != null)
                        Expanded(
                          child: ListTile(
                            leading: Icon(
                              Icons.vertical_align_top,
                              color: isAboveMax ? Theme.of(context).colorScheme.error : null,
                            ),
                            title: Text(
                              "Max: ${Adjustment.formatValue(adjustment.max)}",
                              style: TextStyle(color: isAboveMax ? Theme.of(context).colorScheme.error : null),
                            ),
                            dense: true,
                          ),
                        ),
                    ],
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: (isBelowMin || isAboveMax)
                      ? ListTile(
                          leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                          title: SelectableText(
                            isBelowMin ? "Selected duration is below the minimum" : "Selected duration exceeds the maximum",
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          dense: true,
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(
                  height: 200,
                  child: _MaterialDurationPicker(
                    initialDuration: currentValue,
                    onDurationChanged: (newValue) {
                      setSheetState(() {
                        currentValue = newValue;
                      });
                      
                      if (adjustment.isValidValue(newValue)) {
                        onChanged(newValue);
                        return;
                      }
                
                      if (adjustment.max != null && newValue > adjustment.max!) {
                        onChanged(adjustment.max!);
                      }
                
                      if (adjustment.min != null && newValue < adjustment.min!) {
                        onChanged(adjustment.min!);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
      );
    }
  );
}

class _MaterialDurationPicker extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration> onDurationChanged;

  const _MaterialDurationPicker({
    required this.initialDuration,
    required this.onDurationChanged,
  });

  @override
  State<_MaterialDurationPicker> createState() => _MaterialDurationPickerState();
}

class _MaterialDurationPickerState extends State<_MaterialDurationPicker> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;

  bool _isKeyboardMode = false;
  late TextEditingController _hoursInputController;
  late TextEditingController _minutesInputController;
  late TextEditingController _secondsInputController;

  late FocusNode _hoursFocusNode;
  late FocusNode _minutesFocusNode;
  late FocusNode _secondsFocusNode;

  @override
  void initState() {
    super.initState();
    final duration = widget.initialDuration;
    _hours = duration.inHours.clamp(0, 99);
    _minutes = duration.inMinutes.remainder(60).clamp(0, 59);
    _seconds = duration.inSeconds.remainder(60).clamp(0, 59);

    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
    _secondsController = FixedExtentScrollController(initialItem: _seconds);

    _hoursInputController = TextEditingController(text: _hours.toString().padLeft(2, '0'));
    _minutesInputController = TextEditingController(text: _minutes.toString().padLeft(2, '0'));
    _secondsInputController = TextEditingController(text: _seconds.toString().padLeft(2, '0'));

    _hoursFocusNode = FocusNode();
    _minutesFocusNode = FocusNode();
    _secondsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();

    _hoursInputController.dispose();
    _minutesInputController.dispose();
    _secondsInputController.dispose();

    _hoursFocusNode.dispose();
    _minutesFocusNode.dispose();
    _secondsFocusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    widget.onDurationChanged(
      Duration(
        hours: _hours,
        minutes: _minutes,
        seconds: _seconds,
      ),
    );
  }

  void _switchToKeyboardMode({FocusNode? targetFocusNode, TextEditingController? targetController}) {
    setState(() {
      _isKeyboardMode = true;
      _hoursInputController.text = _hours.toString().padLeft(2, '0');
      _minutesInputController.text = _minutes.toString().padLeft(2, '0');
      _secondsInputController.text = _seconds.toString().padLeft(2, '0');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = targetFocusNode ?? _hoursFocusNode;
      final ctrl = targetController ?? _hoursInputController;
      focus.requestFocus();
      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
    });
  }

  void _onHoursInputChanged(String val) {
    final parsed = int.tryParse(val) ?? 0;
    if (parsed > 99) {
      _hours = 99;
      _hoursInputController.text = '99';
      _hoursInputController.selection = const TextSelection.collapsed(offset: 2);
    } else {
      _hours = parsed;
    }
    _onChanged();

    if (val.length == 2) {
      _minutesFocusNode.requestFocus();
      _minutesInputController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _minutesInputController.text.length,
      );
    }
  }

  void _onMinutesInputChanged(String val) {
    final parsed = int.tryParse(val) ?? 0;
    if (parsed > 59) {
      _minutes = 59;
      _minutesInputController.text = '59';
      _minutesInputController.selection = const TextSelection.collapsed(offset: 2);
    } else {
      _minutes = parsed;
    }
    _onChanged();

    if (val.length == 2) {
      _secondsFocusNode.requestFocus();
      _secondsInputController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _secondsInputController.text.length,
      );
    }
  }

  void _onSecondsInputChanged(String val) {
    final parsed = int.tryParse(val) ?? 0;
    if (parsed > 59) {
      _seconds = 59;
      _secondsInputController.text = '59';
      _secondsInputController.selection = const TextSelection.collapsed(offset: 2);
    } else {
      _seconds = parsed;
    }
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _isKeyboardMode 
        ? Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInputField(
                  controller: _hoursInputController,
                  focusNode: _hoursFocusNode,
                  label: 'h',
                  maxValue: 99,
                  textInputAction: TextInputAction.next,
                  onChanged: _onHoursInputChanged,
                ),
                const SizedBox(width: 16),
                _buildInputField(
                  controller: _minutesInputController,
                  focusNode: _minutesFocusNode,
                  label: 'm',
                  maxValue: 59,
                  textInputAction: TextInputAction.next,
                  onChanged: _onMinutesInputChanged,
                ),
                const SizedBox(width: 16),
                _buildInputField(
                  controller: _secondsInputController,
                  focusNode: _secondsFocusNode,
                  label: 's',
                  maxValue: 59,
                  textInputAction: TextInputAction.done,
                  onChanged: _onSecondsInputChanged,
                  onSubmitted: (_) {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildWheel(
                      controller: _hoursController,
                      max: 99,
                      label: 'h',
                      selectedValue: _hours,
                      onChanged: (val) {
                        setState(() => _hours = val);
                        _onChanged();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildWheel(
                      controller: _minutesController,
                      max: 59,
                      label: 'm',
                      selectedValue: _minutes,
                      onChanged: (val) {
                        setState(() => _minutes = val);
                        _onChanged();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildWheel(
                      controller: _secondsController,
                      max: 59,
                      label: 's',
                      selectedValue: _seconds,
                      onChanged: (val) {
                        setState(() => _seconds = val);
                        _onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required int maxValue,
    required TextInputAction textInputAction,
    required ValueChanged<String> onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textInputAction: textInputAction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
              counterText: '',
            ),
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int max,
    required String label,
    required int selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            perspective: 0.003,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            useMagnifier: true,
            magnification: 1.18,
            overAndUnderCenterOpacity: 0.5,
            onSelectedItemChanged: (index) {
              unawaited(HapticFeedback.selectionClick());
              onChanged(index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max + 1,
              builder: (context, index) {
                final isSelected = index == selectedValue;
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      if (label == 'h') {
                        _switchToKeyboardMode(targetFocusNode: _hoursFocusNode, targetController: _hoursInputController);
                      } else if (label == 'm') {
                        _switchToKeyboardMode(targetFocusNode: _minutesFocusNode, targetController: _minutesInputController);
                      } else if (label == 's') {
                        _switchToKeyboardMode(targetFocusNode: _secondsFocusNode, targetController: _secondsInputController);
                      }
                    } else {
                      unawaited(controller.animateToItem(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ));
                    }
                  },
                  child: Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
