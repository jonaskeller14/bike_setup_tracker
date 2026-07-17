import 'package:flutter/material.dart';
import 'dialog_action.dart';

enum PresetAdjustmentChoice { replace, keepBoth, cancel }

Future<PresetAdjustmentChoice?> showApplyPresetAdjustmentsDialog(
  BuildContext context, {
  required int existingCount,
}) {
  return showDialog<PresetAdjustmentChoice>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: const Text('Apply preset adjustments?'),
        content: Text(
          'This component already has $existingCount '
          '${existingCount == 1 ? 'adjustment' : 'adjustments'}. '
          'Replace them with the preset, or keep both?',
        ),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, PresetAdjustmentChoice.cancel),
            child: const Text('Cancel'),
          ),
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, PresetAdjustmentChoice.keepBoth),
            child: const Text('Keep both'),
          ),
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, PresetAdjustmentChoice.replace),
            child: const Text('Replace'),
          ),
        ],
      );
    },
  );
}
