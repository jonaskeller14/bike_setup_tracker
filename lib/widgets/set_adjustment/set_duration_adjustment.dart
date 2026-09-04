import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';
import '../sheets/set_duration.dart';

class SetDurationAdjustmentWidget extends StatelessWidget {
  final DurationAdjustment adjustment;
  final Duration? initialValue;
  final Duration? value;
  final ValueChanged<Duration?> onChanged;
  final bool highlighting;

  /// The value is not pre-filled from [initialValue], so it may be left unset
  /// and stays clearable even when a previous value exists.
  final bool optional;

  const SetDurationAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = value == null ? false : initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChanged ? (isInitial ? highlights?.initialFill ?? Colors.green.withValues(alpha: 0.08) : highlights?.changedFill ?? Colors.orange.withValues(alpha: 0.08)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Expanded(
            child: AdjustmentIconNameNotes(adjustment: adjustment, color: highlightColor),
          ),
          if (value == null)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => onChanged(Duration.zero),
              child: const Text("Set value"),
            )
          else
            Row(
              children: [
                InkWell(
                  onTap: () => showSetDurationSheet(
                    context: context,
                    adjustment: adjustment,
                    value: value,
                    onChanged: onChanged, 
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Adjustment.formatValue(value),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: highlightColor,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit, 
                        size: 20, 
                        color: highlightColor ?? Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (isInitial || optional)
                  IconButton(
                    onPressed: () => onChanged(null), 
                    icon: const Icon(Icons.replay),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
