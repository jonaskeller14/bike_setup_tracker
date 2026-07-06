import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../sheets/set_categorical.dart';
import "set_adjustment.dart";

class SetCategoricalAdjustmentWidget extends StatelessWidget {
  final CategoricalAdjustment adjustment;
  final List<String>? initialValue;
  final List<String>? value;
  final ValueChanged<List<String>?> onChanged;
  final bool highlighting;

  const SetCategoricalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
  });

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = !adjustmentValuesEqual(initialValue, value);
      isInitial = initialValue == null || initialValue!.isEmpty;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }

    // Only options that still exist are shown in the field; any dangling values
    // are surfaced (and removable) inside the sheet.
    final List<String> selected = value ?? const [];
    final List<String> validSelected = adjustment.options.where(selected.contains).toList();
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
                if (!adjustment.multiSelect && selection.length > 1) {
                  return 'Only one option can be selected';
                }
                return null;
              },
              builder: (FormFieldState<List<String>> field) {
                return InkWell(
                  onTap: () => showSetCategoricalSheet(
                    context: context,
                    adjustment: adjustment,
                    selected: selected,
                    onChanged: (List<String> newSelection) {
                      final List<String>? newValue = newSelection.isEmpty ? null : newSelection;
                      field.didChange(newValue);
                      onChanged(newValue);
                    },
                  ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: field.errorText,
                      suffixIcon: Icon(Icons.arrow_drop_down, color: highlightColor),
                    ),
                    child: Text(
                      hasValidValue ? validSelected.join(Adjustment.multiValueSeparator) : "Please select",
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
