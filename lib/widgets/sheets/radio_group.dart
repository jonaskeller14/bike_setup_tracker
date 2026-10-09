import 'package:flutter/material.dart';

import 'sheet_header.dart';

Future<void> radioGroupSheet<T>({
  required BuildContext context,
  Widget? leadingIcon,
  required String title,
  required T value,
  required ValueChanged<T?> onChanged,
  required Map<T, Widget> optionWidgets,
  String? infoText,
  Widget? contentWidget,
}) {
    return showModalBottomSheet<void>(
      useSafeArea: true,
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
                SheetHeader(title: title, leadingIcon: leadingIcon),
                const SizedBox(height: 16),
                if (infoText != null)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    titleAlignment: ListTileTitleAlignment.titleHeight,
                    title: Text(infoText),
                    dense: true,
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ?contentWidget,
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
