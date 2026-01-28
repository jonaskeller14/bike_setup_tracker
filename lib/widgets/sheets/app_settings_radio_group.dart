import 'package:flutter/material.dart';
import 'sheet.dart';

Future<void> appSettingsRadioGroupSheet<T>({
  required BuildContext context,
  required String title,
  required T value,
  required ValueChanged<T?> onChanged,
  required Map<T, Widget> optionWidgets,
  String? infoText,
  Widget? contentWidget,
}) {
    return showModalBottomSheet<void>(
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return RadioGroup<T>(
          groupValue: value,
          onChanged: onChanged,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      sheetTitle(context, title),
                      sheetCloseButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (infoText != null) ...[
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(infoText),
                    dense: true,
                  ),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contentWidget != null)
                          contentWidget,
                        ...optionWidgets.entries.map((e) => RadioListTile(
                          value: e.key,
                          title: e.value,
                        )),
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),
        );
      }
    );
  }
