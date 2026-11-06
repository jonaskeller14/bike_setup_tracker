import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
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
        title: Text(context.l10n.applyPresetTitle),
        content: Text(context.l10n.applyPresetBody(existingCount)),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, PresetAdjustmentChoice.cancel),
            child: Text(context.l10n.cancel),
          ),
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, PresetAdjustmentChoice.keepBoth),
            child: Text(context.l10n.applyPresetKeepBoth),
          ),
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, PresetAdjustmentChoice.replace),
            child: Text(context.l10n.replace),
          ),
        ],
      );
    },
  );
}
