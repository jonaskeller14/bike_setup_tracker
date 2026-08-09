import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../sheets/set_duration.dart';
import 'set_adjustment.dart';

class SetDurationAdjustmentWidget extends StatelessWidget {
  final DurationAdjustment adjustment;
  final Duration? initialValue;
  final Duration? value;
  final ValueChanged<Duration?> onChanged;
  final bool highlighting;

  const SetDurationAdjustmentWidget({
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
            child: Row(
              mainAxisSize: MainAxisSize.max,
              spacing: 10,
              children: [
                Icon(DurationAdjustment.iconData, color: highlightColor),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
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
                if (isInitial)
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
