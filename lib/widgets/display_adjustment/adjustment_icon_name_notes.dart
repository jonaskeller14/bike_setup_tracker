import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../items/adjustment_properties.dart';
import '../items/adjustment_type_icon.dart';

class AdjustmentIconNameNotes extends StatelessWidget{
  final Adjustment adjustment;
  final Color? color;
  final bool compact;
  
  const AdjustmentIconNameNotes({super.key, required this.adjustment, this.color, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textStyle = compact
        ? textTheme.bodyMedium?.copyWith(color: color)
        : textTheme.bodyLarge?.copyWith(color: color);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      spacing: compact ? 8 : 10,
      children: [
        AdjustmentTypeIcon(adjustment, size: compact ? 20 : 24, color: color),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              showDuration: const Duration(seconds: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(12),
              richMessage: WidgetSpan(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      adjustment.name,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AdjustmentProperties(
                      adjustment,
                      color: colorScheme.onSecondary,
                    ),
                    if (adjustment.notes != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3), // tweak to match font size
                            child: Icon(
                              Icons.notes,
                              size: 13,
                              color: colorScheme.onSecondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              adjustment.notes!,
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              child: Text.rich( // not selectable because conflict with tooltip
                TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: adjustment.name),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Opacity(
                          opacity: 0.5,
                          child: Icon(
                            Icons.info_outline,
                            color: color,
                            size: textTheme.bodyMedium?.fontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget nameSetAdjustmentWidget({required BuildContext context, required String name, required Color? highlightColor}) {
  return Expanded(
    child: Align(
      alignment: Alignment.centerLeft,
      child: SelectableText(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor))
    ),
  );
}
