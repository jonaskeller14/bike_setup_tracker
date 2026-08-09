import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../sheets/set_categorical.dart';
import 'set_adjustment.dart';

class SetCategoricalAdjustmentWidget extends StatelessWidget {
  final CategoricalAdjustment adjustment;
  final List<String>? initialValue;
  final List<String>? value;
  final ValueChanged<List<String>?> onChanged;
  final bool highlighting;
  final Future<void> Function(String option)? onAddOption;

  const SetCategoricalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
    this.onAddOption,
  });

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = value != null && !adjustmentValuesEqual(initialValue, value);
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }

    // Only options that still exist are shown in the field; any dangling values
    // are surfaced (and removable) inside the sheet.
    final List<String> selected = value ?? const [];
    final List<String> validSelected = [
      for (final option in adjustment.options)
        for (var i = 0; i < selected.where((v) => v == option).length; i++) option,
    ];
    final bool hasValidValue = validSelected.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? (isInitial ? highlights?.initialFill ?? Colors.green.withValues(alpha: 0.08) : highlights?.changedFill ?? Colors.orange.withValues(alpha: 0.08)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(CategoricalAdjustment.iconData, color: highlightColor),
                const SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            ),
          ),
          Flexible(
            flex: 3,
            child: FormField<List<String>>(
              initialValue: value,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (_) {
                final selection = value ?? const <String>[];
                if (selection.any((e) => !adjustment.options.contains(e))) {
                  return 'Contains options that no longer exist';
                }
                final distinct = selection.toSet();
                if (!adjustment.multiSelect && distinct.length > 1) {
                  return 'Only one option can be selected';
                }
                if (!adjustment.counted && selection.length != distinct.length) {
                  return 'An option cannot be selected more than once';
                }
                return null;
              },
              builder: (FormFieldState<List<String>> field) {
                return InkWell(
                  onTap: () => showSetCategoricalSheet(
                    context: context,
                    adjustment: adjustment,
                    selected: selected,
                    initialValue: initialValue,
                    highlighting: highlighting,
                    onAddOption: onAddOption,
                    onChanged: (List<String> newSelection) {
                      field.didChange(newSelection);
                      onChanged(newSelection);
                    },
                  ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      errorText: field.errorText,
                      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 48),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: isChanged ? 0 : 8),
                            child: Icon(Icons.arrow_drop_down, color: highlightColor),
                          ),
                          if (isChanged)
                            IconButton(
                              onPressed: () {
                                field.didChange(initialValue);
                                onChanged(initialValue);
                              },
                              icon: const Icon(Icons.replay),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Revert',
                            ),
                        ],
                      ),
                    ),
                    child: Text(
                      hasValidValue ? Adjustment.formatValue(validSelected) : "Please select",
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: hasValidValue ? highlightColor : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
