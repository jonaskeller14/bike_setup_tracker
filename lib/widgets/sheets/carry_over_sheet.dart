import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
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

  static String _reason(CarryOverEntry entry, AppLocalizations l10n) => switch (entry.issue) {
    CarryOverIssue.componentGone => l10n.carryOverReasonGone(entry.fromComponent.name),
    CarryOverIssue.noMatchingAdjustment => l10n.carryOverReasonNoMatch('${entry.toComponent?.name}'),
    CarryOverIssue.valueNotAllowed => l10n.carryOverReasonNotAllowed('${entry.to?.name}', '${entry.toComponent?.name}'),
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
          SheetHeader(title: canApply ? context.l10n.carryOverTitleApply : context.l10n.carryOverTitleCant),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              canApply
                  ? context.l10n.carryOverBodyApply(setup.displayName)
                  : context.l10n.carryOverBodyCant(setup.displayName),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                if (canApply) sheetSectionHeader(context, context.l10n.carryOverWillApply.toUpperCase()),
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
                      context.l10n.carryOverFromTo(entry.fromComponent.name, entry.toComponent!.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (skipped.isNotEmpty) sheetSectionHeader(context, context.l10n.carryOverCantApply.toUpperCase()),
                for (final entry in skipped)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.block, color: theme.colorScheme.error),
                    title: Text(
                      '${entry.from.name}: ${_valueText(entry)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_reason(entry, context.l10n), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              context.l10n.carryOverNote,
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
                          child: Text(context.l10n.carryOverDontApply),
                        )
                      : FilledButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.l10n.continueLabel),
                        ),
                ),
                if (canApply)
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        unawaited(HapticFeedback.selectionClick());
                        Navigator.pop(context, true);
                      },
                      child: Text(context.l10n.carryOverApplyCount(applicable.length)),
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
