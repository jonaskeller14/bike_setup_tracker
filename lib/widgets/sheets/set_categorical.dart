import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';

void showSetCategoricalSheet({
  required BuildContext context,
  required CategoricalAdjustment adjustment,
  required List<String> selected,
  required ValueChanged<List<String>> onChanged,
}) async {
  final bool multiSelect = adjustment.multiSelect;
  final Set<String> current = selected.toSet();

  final List<String> danglingOrder =
      selected.where((v) => !adjustment.options.contains(v)).toList();

  List<String> emit() {
    final valid = adjustment.options.where(current.contains).toList(); // option order
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
          final bool hasDanglingSelected = danglingOrder.any(current.contains);

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
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in adjustment.options)
                          _OptionChip(
                            label: option,
                            selected: current.contains(option),
                            multiSelect: multiSelect,
                            onTap: () {
                              unawaited(HapticFeedback.selectionClick());
                              if (multiSelect) {
                                setSheetState(() {
                                  if (!current.remove(option)) current.add(option);
                                });
                                onChanged(emit());
                              } else {
                                // Reflect the selection in the sheet, then close
                                // shortly after so the tap is visible.
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
                        // No-longer-valid preselected values, shown error-red so the
                        // user can see and remove them.
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
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (multiSelect) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
    }
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
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
