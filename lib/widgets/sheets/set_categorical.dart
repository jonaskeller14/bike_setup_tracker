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
}) async {
  final bool multiSelect = adjustment.multiSelect;
  final bool counted = adjustment.counted;
  final Set<String> current = selected.toSet();
  final Map<String, int> counts = {
    for (final option in adjustment.options) option: selected.where((v) => v == option).length,
  };

  final bool isInitial = initialValue == null;
  final Set<String> initialSet = (initialValue ?? const <String>[]).toSet();

  final List<String> danglingOrder =
      selected.where((v) => !adjustment.options.contains(v)).toList();

  List<String> emit() {
    final valid = counted
        ? [
            for (final option in adjustment.options)
              for (var i = 0; i < (counts[option] ?? 0); i++) option,
          ]
        : adjustment.options.where(current.contains).toList(); // option order
    final dangling = danglingOrder.where(current.contains).toList();
    return [...valid, ...dangling];
  }

  await showModalBottomSheet<void>(
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final scheme = Theme.of(context).colorScheme;
          final highlights = Theme.of(context).extension<ValueHighlightColors>();
          final bool hasDanglingSelected = danglingOrder.any(current.contains);
          final bool hasMultipleSelectedError = !multiSelect &&
              (counted ? counts.values.where((c) => c > 0).length > 1 : current.length > 1);

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    if (adjustment.options.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SheetFilterEmptyHint(
                          icon: CategoricalAdjustment.iconData,
                          title: 'No options yet',
                          hint: 'Edit this adjustment to add options.',
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in adjustment.options)
                          if (counted)
                            _CountedOptionChip(
                              label: option,
                              count: counts[option] ?? 0,
                              highlightColor: !highlighting ||
                                      (counts[option] ?? 0) == 0 ||
                                      initialSet.contains(option)
                                  ? null
                                  : (isInitial
                                      ? highlights?.initial ?? Colors.green
                                      : highlights?.changed ?? Colors.orange),
                              isPrevious: highlighting &&
                                  (counts[option] ?? 0) == 0 &&
                                  initialSet.contains(option),
                              onTap: () {
                                unawaited(HapticFeedback.selectionClick());
                                setSheetState(() {
                                  if (!multiSelect &&
                                      (counts[option] ?? 0) == 0 &&
                                      counts.values.any((c) => c > 0)) {
                                    counts.updateAll((key, value) => 0);
                                  }
                                  counts[option] = (counts[option] ?? 0) + 1;
                                });
                                onChanged(emit());
                              },
                              onDecrement: () {
                                unawaited(HapticFeedback.selectionClick());
                                setSheetState(() {
                                  final int newCount = (counts[option] ?? 0) - 1;
                                  counts[option] = newCount < 0 ? 0 : newCount;
                                });
                                onChanged(emit());
                              },
                            )
                          else
                            _OptionChip(
                              label: option,
                              selected: current.contains(option),
                              multiSelect: multiSelect,
                              highlightColor: !highlighting ||
                                      !current.contains(option) ||
                                      initialSet.contains(option)
                                  ? null
                                  : (isInitial
                                      ? highlights?.initial ?? Colors.green
                                      : highlights?.changed ?? Colors.orange),
                              isPrevious: highlighting &&
                                  !current.contains(option) &&
                                  initialSet.contains(option),
                              onTap: () {
                                unawaited(HapticFeedback.selectionClick());
                                if (multiSelect) {
                                  setSheetState(() {
                                    if (!current.remove(option)) current.add(option);
                                  });
                                  onChanged(emit());
                                } else {
                                  setSheetState(() {
                                    current
                                      ..clear()
                                      ..add(option);
                                  });
                                  onChanged(emit());
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    if (context.mounted) Navigator.of(context).pop();
                                  });
                                }
                              },
                            ),
                        for (final value in danglingOrder)
                          if (current.contains(value))
                            _DanglingChip(
                              label: value,
                              onDeleted: () {
                                unawaited(HapticFeedback.selectionClick());
                                setSheetState(() => current.remove(value));
                                onChanged(emit());
                              },
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
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
      deleteIcon: count > 0 ? const Icon(Icons.close, size: 18) : null,
      onDeleted: count > 0 ? onDecrement : null,
      onPressed: onTap,
    );

    return isPrevious ? Tooltip(message: 'Previous value', child: chip) : chip;
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
