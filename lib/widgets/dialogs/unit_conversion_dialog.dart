import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../utils/unit_conversion.dart';
import 'dialog_action.dart';

enum UnitEditChoice { convert, keep }

Future<UnitEditChoice?> showUnitConversionDialog(
  BuildContext context, {
  required KnownUnit from,
  required KnownUnit to,
}) {
  const example = 10.0;
  final converted = convertUnit(example, from, to);
  final exampleLine =
      '${formatConverted(example)} ${from.label} → ${formatConverted(converted)} ${to.label}';
  final keepLine =
      '${formatConverted(example)} ${from.label} becomes ${formatConverted(example)} ${to.label}';

  return showDialog<UnitEditChoice>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: const Text('Convert existing values?'),
        content: Text(
          'Unit changed from ${from.label} to ${to.label}. '
          'What should happen to existing values?\n\n'
          '• Convert values — e.g. $exampleLine\n'
          '• Keep numbers — $keepLine (values were mislabeled)',
        ),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(UnitEditChoice.keep),
            child: const Text('Keep numbers'),
          ),
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(UnitEditChoice.convert),
            child: const Text('Convert values'),
          ),
        ],
      );
    },
  );
}
