import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'radio_group.dart';

Future<bool?> showFeatureSettingSheet(
  BuildContext context, {
  required String title,
  required bool value,
  String? infoText,
}) async {
  final l10n = context.l10n;
  bool? selected;
  await radioGroupSheet<bool>(
    context: context,
    title: title,
    value: value,
    optionWidgets: {false: Text(l10n.valueOff), true: Text(l10n.valueOn)},
    onChanged: (newValue) {
      selected = newValue;
      Navigator.pop(context);
    },
    infoText: infoText,
  );
  return selected;
}
