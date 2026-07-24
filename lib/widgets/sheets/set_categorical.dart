import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import 'sheet.dart';

void showSetCategoricalSheet({
  required BuildContext context,
  required CategoricalAdjustment adjustment,
  required List<String> selected,
  required ValueChanged<List<String>> onChanged,
  List<String>? initialValue,
  bool highlighting = true,
  Future<void> Function(String option)? onAddOption,
}) async {
  await showModalBottomSheet<void>(
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => _SetCategoricalSheet(
      adjustment: adjustment,
      selected: selected,
      initialValue: initialValue,
      highlighting: highlighting,
      onAddOption: onAddOption,
      onChanged: onChanged,
    ),
  );
}

class _SetCategoricalSheet extends StatefulWidget {
  final CategoricalAdjustment adjustment;
  final List<String> selected;
  final List<String>? initialValue;
  final bool highlighting;
  final Future<void> Function(String option)? onAddOption;
  final ValueChanged<List<String>> onChanged;

  const _SetCategoricalSheet({
    required this.adjustment,
    required this.selected,
    required this.initialValue,
    required this.highlighting,
    required this.onAddOption,
    required this.onChanged,
  });

  @override
  State<_SetCategoricalSheet> createState() => _SetCategoricalSheetState();
}

class _SetCategoricalSheetState extends State<_SetCategoricalSheet> {
  bool get _multiSelect => widget.adjustment.multiSelect;
  bool get _counted => widget.adjustment.counted;

  late final Set<String> _current = widget.selected.toSet();
  // Locally tracked options so an inline-added option renders and emits while
  // the sheet is open; the captured adjustment stays stale until it closes.
  late final List<String> _optionList = widget.adjustment.options.toList();
  late final Map<String, int> _counts = {
    for (final option in _optionList) option: widget.selected.where((v) => v == option).length,
  };

  late final bool _isInitial = widget.initialValue == null;
  late final Set<String> _initialSet = (widget.initialValue ?? const <String>[]).toSet();
  late final Map<String, int> _initialCounts = {
    for (final option in _optionList)
      option: (widget.initialValue ?? const <String>[]).where((v) => v == option).length,
  };

  late final List<String> _danglingOrder =
      widget.selected.where((v) => !_optionList.contains(v)).toList();

  List<String> _emit() {
    final valid = _counted
        ? [
            for (final option in _optionList)
              for (var i = 0; i < (_counts[option] ?? 0); i++) option,
          ]
        : _optionList.where(_current.contains).toList(); // option order
    final dangling = _danglingOrder.where(_current.contains).toList();
    return [...valid, ...dangling];
  }

  /// Persists a newly typed option, then auto-selects it (respecting the
  /// adjustment's mode). Returns an error message to show inline, or null on
  /// success.
  Future<String?> _handleAddOption(String value) async {
    if (_optionList.contains(value)) return 'Already exists';
    await widget.onAddOption?.call(value);
    if (!mounted) return null;
    unawaited(HapticFeedback.selectionClick());
    final bool singleClose = !_multiSelect && !_counted;
    setState(() {
      _optionList.add(value);
      if (_counted) {
        if (!_multiSelect && _counts.values.any((c) => c > 0)) {
          _counts.updateAll((key, v) => 0);
        }
        _counts[value] = 1;
      } else if (_multiSelect) {
        _current.add(value);
      } else {
        _current
          ..clear()
          ..add(value);
      }
    });
    widget.onChanged(_emit());
    if (singleClose) _closeAfterSelection();
    return null;
  }

  void _onCountedTap(String option) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_multiSelect && (_counts[option] ?? 0) == 0 && _counts.values.any((c) => c > 0)) {
        _counts.updateAll((key, value) => 0);
      }
      _counts[option] = (_counts[option] ?? 0) + 1;
    });
    widget.onChanged(_emit());
  }

  void _onCountedDecrement(String option) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      final int newCount = (_counts[option] ?? 0) - 1;
      _counts[option] = newCount < 0 ? 0 : newCount;
    });
    widget.onChanged(_emit());
  }

  void _onOptionTap(String option) {
    unawaited(HapticFeedback.selectionClick());
    if (_multiSelect) {
      setState(() {
        if (!_current.remove(option)) _current.add(option);
      });
      widget.onChanged(_emit());
    } else {
      setState(() {
        _current
          ..clear()
          ..add(option);
      });
      widget.onChanged(_emit());
      _closeAfterSelection();
    }
  }

  void _onDanglingDelete(String value) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _current.remove(value));
    widget.onChanged(_emit());
  }

  /// Single-select briefly shows the new selection before dismissing.
  void _closeAfterSelection() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    final bool hasDanglingSelected = _danglingOrder.any(_current.contains);
    final bool hasMultipleSelectedError = !_multiSelect &&
        (_counted ? _counts.values.where((c) => c > 0).length > 1 : _current.length > 1);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: double.infinity),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasDanglingSelected
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.error_outline, color: scheme.error),
                          title: Text(
                            'Some selected options no longer exist.',
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasMultipleSelectedError
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.error_outline, color: scheme.error),
                          title: Text(
                            'Multiple options selected, but only one is allowed.',
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (_optionList.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SheetFilterEmptyHint(
                    icon: CategoricalAdjustment.iconData,
                    title: 'No options yet',
                    hint: widget.onAddOption == null
                        ? 'Edit this adjustment to add options.'
                        : 'Tap + below to add the first option.',
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final option in _optionList)
                    if (_counted)
                      _CountedOptionChip(
                        label: option,
                        count: _counts[option] ?? 0,
                        highlightColor: !widget.highlighting ||
                                (_counts[option] ?? 0) == 0 ||
                                (_counts[option] ?? 0) == (_initialCounts[option] ?? 0)
                            ? null
                            : (_isInitial
                                ? highlights?.initial ?? Colors.green
                                : highlights?.changed ?? Colors.orange),
                        isPrevious: widget.highlighting &&
                            (_counts[option] ?? 0) == 0 &&
                            (_initialCounts[option] ?? 0) > 0,
                        onTap: () => _onCountedTap(option),
                        onDecrement: () => _onCountedDecrement(option),
                      )
                    else
                      _OptionChip(
                        label: option,
                        selected: _current.contains(option),
                        multiSelect: _multiSelect,
                        highlightColor: !widget.highlighting ||
                                !_current.contains(option) ||
                                _initialSet.contains(option)
                            ? null
                            : (_isInitial
                                ? highlights?.initial ?? Colors.green
                                : highlights?.changed ?? Colors.orange),
                        isPrevious: widget.highlighting &&
                            !_current.contains(option) &&
                            _initialSet.contains(option),
                        onTap: () => _onOptionTap(option),
                      ),
                  for (final value in _danglingOrder)
                    if (_current.contains(value))
                      _DanglingChip(
                        label: value,
                        onDeleted: () => _onDanglingDelete(value),
                      ),
                  if (widget.onAddOption != null)
                    _AddOptionChip(onSubmit: _handleAddOption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multiSelect;

  final Color? highlightColor;

  final bool isPrevious;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.multiSelect,
    required this.highlightColor,
    required this.isPrevious,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color? labelColor = highlightColor ?? (isPrevious ? scheme.onSurfaceVariant : null);
    final TextStyle? labelStyle =
        labelColor == null ? null : theme.textTheme.labelLarge?.copyWith(color: labelColor);
    final BorderSide? side = highlightColor != null
        ? BorderSide(color: highlightColor!)
        : (isPrevious ? BorderSide(color: scheme.outline) : null);
    final Widget? avatar = isPrevious
        ? Icon(Icons.history, size: 18, color: scheme.onSurfaceVariant)
        : null;

    final Widget chip = multiSelect
        ? FilterChip(
            label: Text(label),
            selected: selected,
            avatar: avatar,
            labelStyle: labelStyle,
            side: side,
            selectedColor: highlightColor?.withValues(alpha: 0.18),
            checkmarkColor: highlightColor,
            onSelected: (_) => onTap(),
          )
        : ChoiceChip(
            label: Text(label),
            selected: selected,
            avatar: avatar,
            labelStyle: labelStyle,
            side: side,
            selectedColor: highlightColor?.withValues(alpha: 0.18),
            checkmarkColor: highlightColor,
            onSelected: (_) => onTap(),
          );

    return isPrevious ? Tooltip(message: 'Previous value', child: chip) : chip;
  }
}

class _CountedOptionChip extends StatelessWidget {
  final String label;
  final int count;

  final Color? highlightColor;

  final bool isPrevious;
  final VoidCallback onTap;
  final VoidCallback onDecrement;

  const _CountedOptionChip({
    required this.label,
    required this.count,
    required this.highlightColor,
    required this.isPrevious,
    required this.onTap,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color? labelColor = highlightColor ?? (isPrevious ? scheme.onSurfaceVariant : null);
    final TextStyle? labelStyle =
        labelColor == null ? null : theme.textTheme.labelLarge?.copyWith(color: labelColor);
    final BorderSide? side = highlightColor != null
        ? BorderSide(color: highlightColor!)
        : (isPrevious ? BorderSide(color: scheme.outline) : null);
    final Widget? avatar = isPrevious
        ? Icon(Icons.history, size: 18, color: scheme.onSurfaceVariant)
        : null;

    final Widget chip = InputChip(
      label: Text(count > 0 ? '$label ($count)' : label),
      selected: count > 0,
      avatar: avatar,
      labelStyle: labelStyle,
      side: side,
      selectedColor: highlightColor?.withValues(alpha: 0.18),
      checkmarkColor: highlightColor,
      deleteIcon: count > 0 ? const Icon(Icons.close, size: 18) : null,
      deleteIconColor: highlightColor,
      onDeleted: count > 0 ? onDecrement : null,
      onPressed: onTap,
    );

    return isPrevious ? Tooltip(message: 'Previous value', child: chip) : chip;
  }
}

class _AddOptionChip extends StatefulWidget {
  final Future<String?> Function(String value) onSubmit;

  const _AddOptionChip({required this.onSubmit});

  @override
  State<_AddOptionChip> createState() => _AddOptionChipState();
}

class _AddOptionChipState extends State<_AddOptionChip> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _editing = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final String? error;
    try {
      error = await widget.onSubmit(value);
    } finally {
      // Always clear the busy state, even if persistence throws, so the field
      // never stays disabled. The error itself is left to propagate.
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    if (error == null) {
      setState(() {
        _editing = false;
        _controller.clear();
      });
    } else {
      setState(() => _error = error);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_editing) {
      // Match the label height of the neighbouring text chips so the pill lines
      // up; an icon-only label is otherwise a few pixels shorter.
      final labelStyle = theme.chipTheme.labelStyle ?? theme.textTheme.labelLarge;
      final double labelHeight = (labelStyle?.fontSize ?? 14) * (labelStyle?.height ?? 1.4);
      return ActionChip(
        label: SizedBox(
          height: labelHeight,
          child: const Center(
            widthFactor: 1,
            child: Icon(Icons.add, size: 18),
          ),
        ),
        tooltip: 'Add option',
        onPressed: () => setState(() => _editing = true),
      );
    }
    return SizedBox(
      width: 170,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        enabled: !_submitting,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        style: theme.textTheme.labelLarge,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onTapOutside: (_) {
          if (_controller.text.trim().isEmpty && _editing) {
            setState(() => _editing = false);
          }
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: 'New option',
          errorText: _error,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: _submitting
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, size: 18),
                  tooltip: 'Add',
                  visualDensity: VisualDensity.compact,
                  onPressed: _submit,
                ),
        ),
      ),
    );
  }
}

class _DanglingChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _DanglingChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'This option no longer exists',
      child: InputChip(
        avatar: Icon(Icons.error_outline, size: 18, color: scheme.onErrorContainer),
        label: Text(label, style: TextStyle(color: scheme.onErrorContainer)),
        backgroundColor: scheme.errorContainer,
        side: BorderSide(color: scheme.error),
        deleteIcon: Icon(Icons.close, size: 18, color: scheme.onErrorContainer),
        deleteButtonTooltipMessage: 'Remove',
        onDeleted: onDeleted,
        onPressed: onDeleted,
      ),
    );
  }
}
