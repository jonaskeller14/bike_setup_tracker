

import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';

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
              message: adjustment.notes!,
              child: SelectableText.rich(
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
