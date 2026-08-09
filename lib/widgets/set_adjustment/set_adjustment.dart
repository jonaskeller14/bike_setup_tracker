import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../items/adjustment_properties.dart';

Widget nameNotesSetAdjustmentWidget({required BuildContext context, required Adjustment adjustment, required Color? highlightColor}) {
  return Expanded(
    child: Align(
      alignment: Alignment.centerLeft,
      child: adjustment.notes == null 
          ? SelectableText(adjustment.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor))
          : Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              showDuration: const Duration(seconds: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
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
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AdjustmentProperties(
                      adjustment,
                      color: Theme.of(context).colorScheme.onSecondary,
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
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              adjustment.notes!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondary,
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
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
                            color: highlightColor,
                            size: Theme.of(context).textTheme.bodyMedium?.fontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

Widget nameSetAdjustmentWidget({required BuildContext context, required String name, required Color? highlightColor}) {
  return Expanded(
    child: Align(
      alignment: Alignment.centerLeft,
      child: SelectableText(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor))
    ),
  );
}
