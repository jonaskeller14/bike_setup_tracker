import 'package:flutter/material.dart';
import 'sheet.dart';

Future<void> appSettingsRadioGroupSheet<T>({required BuildContext context, required String title, required T value, required ValueChanged<T?> onChanged, required Map<T, Widget> optionWidgets, String? infoText}) {
    return showModalBottomSheet<void>(
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return RadioGroup<T>(
          groupValue: value,
          onChanged: onChanged,
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                  ],
                  ...optionWidgets.entries.map((e) => RadioListTile(
                    value: e.key,
                    title: e.value,
                  )),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
