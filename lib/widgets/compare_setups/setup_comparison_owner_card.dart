import 'package:flutter/material.dart';

import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../theme.dart';
import '../items/card_header_tile.dart';
import 'setup_comparison_row.dart';

class SetupComparisonOwnerCard extends StatelessWidget {
  final comparison.SetupComparisonGroup group;
  final bool differencesOnly;

  const SetupComparisonOwnerCard({super.key, required this.group, required this.differencesOnly});

  @override
  Widget build(BuildContext context) {
    final rows = group.visibleRows(differencesOnly: differencesOnly);
    if (rows.isEmpty && !group.isStructuralDifference) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final hasError =
        group.kind == comparison.SetupComparisonGroupKind.deletedValues ||
        group.ownerStateA == comparison.SetupComparisonOwnerState.dangling ||
        group.ownerStateB == comparison.SetupComparisonOwnerState.dangling;
    final headerColor = hasError ? scheme.errorContainer : scheme.outlineVariant;
    final headerTextColor = hasError
        ? scheme.error
        : group.isStructuralDifference
        ? Theme.of(context).extension<ValueHighlightColors>()!.changed
        : null;
    final differenceCount = group.differenceCount;
    final totalCount = rows.isEmpty ? differenceCount : group.rows.length;

    return KeyedSubtree(
      key: Key('compare-owner-${group.kind.name}-${group.ownerId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHeaderTile(
                color: headerColor,
                child: ListTile(
                  leading: Icon(_icon, color: hasError ? scheme.error : null),
                  title: Semantics(
                    label: group.label,
                    child: Text(
                      group.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor),
                    ),
                  ),
                  subtitle: Text(
                    _subtitle(differenceCount, totalCount),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: headerTextColor),
                  ),
                ),
              ),
              if (rows.isEmpty)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.compare_arrows),
                  title: Text('-', style: TextStyle(color: headerTextColor)),
                )
              else
                for (final row in rows) SetupComparisonRow(groupId: group.ownerId, row: row),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (group.kind) {
    comparison.SetupComparisonGroupKind.component =>
      (group.componentA ?? group.componentB)?.componentType.getIconData() ?? Component.iconData,
    comparison.SetupComparisonGroupKind.person => Person.iconData,
    comparison.SetupComparisonGroupKind.deletedValues => Icons.error_outline,
    _ => Icons.grid_view_sharp,
  };

  String _subtitle(int differenceCount, int totalCount) {
    final count = '$differenceCount of $totalCount differ';
    if (group.kind == comparison.SetupComparisonGroupKind.deletedValues) {
      return '$count · Adjustment definitions are no longer available';
    }
    final states = [
      'A: ${_stateLabel(group.ownerStateA)}',
      'B: ${_stateLabel(group.ownerStateB)}',
    ];
    return '$count · ${states.join(' · ')}';
  }

  String _stateLabel(comparison.SetupComparisonOwnerState state) => switch (state) {
    comparison.SetupComparisonOwnerState.installedOrLinked => 'Present',
    comparison.SetupComparisonOwnerState.dangling =>
      group.kind == comparison.SetupComparisonGroupKind.person
          ? 'Person is not linked to this setup'
          : 'Component was not installed at setup time',
    comparison.SetupComparisonOwnerState.absent => '-',
  };
}
