import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/setup.dart';
import '../../services/setup_carry_over.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// Asks whether the values of [setup] recorded on replaced components move to
/// the components in the same position now. True to apply them, false or
/// dismissed to leave them where they are: they stay in the setup, but belong
/// to components that are no longer on the bike.
Future<bool?> showCarryOverSheet(
  BuildContext context, {
  required Setup setup,
  required SetupCarryOver carryOver,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => _CarryOverSheet(setup: setup, carryOver: carryOver),
  );
}

class _CarryOverSheet extends StatelessWidget {
  final Setup setup;
  final SetupCarryOver carryOver;

  const _CarryOverSheet({required this.setup, required this.carryOver});

  static String _valueText(CarryOverEntry entry) => '${entry.value.display}${entry.from.unitSuffix()}';

  static String _reason(CarryOverEntry entry) => switch (entry.issue) {
    CarryOverIssue.componentGone => "'${entry.fromComponent.name}' is no longer on the bike.",
    CarryOverIssue.noMatchingAdjustment => "'${entry.toComponent?.name}' has no matching adjustment.",
    CarryOverIssue.valueNotAllowed => "Not allowed by '${entry.to?.name}' on '${entry.toComponent?.name}'.",
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicable = carryOver.applicable.toList();
    final skipped = carryOver.skipped.toList();
    final canApply = applicable.isNotEmpty;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: canApply ? 'Apply values to current components?' : "Values can't be applied"),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              canApply
                  ? "'${setup.displayName}' was recorded with components that are no longer on the bike. "
                        'Their values can go to the components in the same position now.'
                  : "'${setup.displayName}' was recorded with components that are no longer on the bike, "
                        "and their values don't fit the components in the same position now.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                if (canApply) sheetSectionHeader(context, 'WILL BE APPLIED'),
                for (final entry in applicable)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_forward),
                    title: Text(
                      '${entry.to!.name}: ${_valueText(entry)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "From '${entry.fromComponent.name}' to '${entry.toComponent!.name}'",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (skipped.isNotEmpty) sheetSectionHeader(context, "CAN'T BE APPLIED"),
                for (final entry in skipped)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.block, color: theme.colorScheme.error),
                    title: Text(
                      '${entry.from.name}: ${_valueText(entry)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_reason(entry), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Values that are not applied stay in the setup, but belong to components that are no longer on the bike.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: canApply
                      ? OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Don't apply"),
                        )
                      : FilledButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Continue'),
                        ),
                ),
                if (canApply)
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        unawaited(HapticFeedback.selectionClick());
                        Navigator.pop(context, true);
                      },
                      child: Text(Intl.plural(applicable.length, one: 'Apply 1 value', other: 'Apply ${applicable.length} values')),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
