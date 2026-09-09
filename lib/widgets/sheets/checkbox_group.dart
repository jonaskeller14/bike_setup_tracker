import 'package:flutter/material.dart';

import 'sheet_header.dart';

class CheckboxGroupSheetOption {
  final String title;
  final String? subtitle;
  final ValueGetter<bool> value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const CheckboxGroupSheetOption({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });
}

Future<void> checkboxGroupSheet({
  required BuildContext context,
  required String title,
  required List<CheckboxGroupSheetOption> options,
  String? infoText,
}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeader(title: title),
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
                      children: options
                          .map((option) => CheckboxListTile(
                                value: option.value(),
                                title: Text(option.title),
                                subtitle: option.subtitle != null
                                    ? Text(option.subtitle!)
                                    : null,
                                enabled: option.enabled,
                                onChanged: (bool? newValue) {
                                  if (newValue == null) return;
                                  option.onChanged(newValue);
                                  setState(() {});
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
