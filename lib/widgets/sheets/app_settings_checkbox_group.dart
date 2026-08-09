import 'package:flutter/material.dart';

import 'sheet_header.dart';

class AppSettingsCheckboxOption {
  final String title;
  final String? subtitle;
  final ValueGetter<bool> value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const AppSettingsCheckboxOption({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });
}

Future<void> appSettingsCheckboxGroupSheet({
  required BuildContext context,
  required String title,
  required List<AppSettingsCheckboxOption> options,
  String? infoText,
}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
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
                          .map((option) => CheckboxListTile.adaptive(
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
