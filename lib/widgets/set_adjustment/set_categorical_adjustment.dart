import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';
import '../display_adjustment/previous_value_line.dart';
import '../sheets/set_categorical.dart';

class SetCategoricalAdjustmentWidget extends StatelessWidget {
  final CategoricalAdjustment adjustment;
  final CategoricalValue? initialValue;
  final CategoricalValue? value;
  final ValueChanged<CategoricalValue?> onChanged;
  final bool highlighting;

  /// The selection is not pre-filled from [initialValue], so it may be left
  /// unset and its reset button clears it instead of restoring [initialValue].
  final bool optional;

  final Future<void> Function(String option)? onAddOption;

  const SetCategoricalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
    this.optional = false,
    this.onAddOption,
  });

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = value != null && initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }

    // An optional selection is revertible to "unset" as soon as it holds a
    // value, even when that value happens to match the previous setup's.
    final bool canReset = optional ? value != null : isChanged;

    // Only options that still exist are shown in the field; any dangling values
    // are surfaced (and removable) inside the sheet.
    final List<String> selected = value?.options ?? const [];
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 20,
            children: [
              Flexible(
                flex: 2,
                child: AdjustmentIconNameNotes(adjustment: adjustment, value: value, color: highlightColor),
              ),
              Flexible(
                flex: 3,
                child: FormField<List<String>>(
                  initialValue: value?.options,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (_) {
                    final selection = value?.options ?? const <String>[];
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
                        initialValue: initialValue?.options,
                        highlighting: highlighting,
                        onAddOption: onAddOption,
                        onChanged: (List<String> newSelection) {
                          field.didChange(newSelection);
                          onChanged(CategoricalValue(newSelection));
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
                                padding: EdgeInsets.only(right: canReset ? 0 : 8),
                                child: Icon(Icons.arrow_drop_down, color: highlightColor),
                              ),
                              if (canReset)
                                IconButton(
                                  onPressed: () {
                                    final resetValue = optional ? null : initialValue;
                                    field.didChange(resetValue?.options);
                                    onChanged(resetValue);
                                  },
                                  icon: const Icon(Icons.replay),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Revert',
                                ),
                            ],
                          ),
                        ),
                        child: Text(
                          hasValidValue ? CategoricalValue(validSelected).display : "Please select",
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
          if (highlighting && PreviousValueLine.appliesTo(adjustment, initialValue, value))
            PreviousValueLine(adjustment: adjustment, previousValue: initialValue!, value: value!),
        ],
      ),
    );
  }
}
