import 'package:flutter/material.dart';

import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../theme.dart';
import '../display_adjustment/display_adjustment_diff.dart';
import '../empty_state_placeholder.dart';
import '../items/card_header_tile.dart';

class SetupComparisonOwnerCard extends StatelessWidget {
  final comparison.SetupComparisonGroup group;
  final bool differencesOnly;

  const SetupComparisonOwnerCard({super.key, required this.group, required this.differencesOnly});

  @override
  Widget build(BuildContext context) {
    final rows = group.visibleRows(differencesOnly: differencesOnly);
    if (rows.isEmpty && !group.isStructuralDifference) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final detailTextColor = group.isStructuralDifference
        ? Theme.of(context).extension<ValueHighlightColors>()!.changed
        : null;
    final differenceCount = group.differenceCount;
    final totalCount = rows.isEmpty ? differenceCount : group.rows.length;
    final oneSidedComponent =
        group.kind == comparison.SetupComparisonGroupKind.component && group.ownerStateA != group.ownerStateB;
    final visibleSide = group.ownerStateA == comparison.SetupComparisonOwnerState.installedOrLinked
        ? DisplayAdjustmentDiffSide.a
        : DisplayAdjustmentDiffSide.b;
    final notInstalled = EmptyStatePlaceholder(
      key: Key(
        'compare-not-installed-${group.ownerId}-${visibleSide == DisplayAdjustmentDiffSide.a ? 'b' : 'a'}',
      ),
      icon: Icons.remove_circle_outline,
      title: 'Not installed',
      compact: true,
    );

    final card = Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeaderTile(
            color: scheme.outlineVariant,
            child: ListTile(
              leading: Icon(_icon),
              title: Semantics(
                label: group.label,
                child: Text(
                  group.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: Text(
                _subtitle(differenceCount, totalCount),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: detailTextColor),
              ),
            ),
          ),
          if (rows.isEmpty && !oneSidedComponent)
            ListTile(
              dense: true,
              leading: const Icon(Icons.compare_arrows),
              title: Text('-', style: TextStyle(color: detailTextColor)),
            )
          else
            for (final row in rows)
              DisplayAdjustmentDiff(
                groupId: group.ownerId,
                row: row,
                side: oneSidedComponent ? visibleSide : DisplayAdjustmentDiffSide.both,
              ),
        ],
      ),
    );

    return KeyedSubtree(
      key: Key('compare-owner-${group.kind.name}-${group.ownerId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: oneSidedComponent
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: visibleSide == DisplayAdjustmentDiffSide.a ? card : notInstalled,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: visibleSide == DisplayAdjustmentDiffSide.b ? card : notInstalled,
                  ),
                ],
              )
            : card,
      ),
    );
  }

  IconData get _icon => switch (group.kind) {
    comparison.SetupComparisonGroupKind.component =>
      (group.componentA ?? group.componentB)?.componentType.getIconData() ?? Component.iconData,
    comparison.SetupComparisonGroupKind.person => Person.iconData,
  };

  String _subtitle(int differenceCount, int totalCount) {
    final verb = differenceCount == 1 ? 'differs' : 'differ';
    return '$differenceCount/$totalCount values $verb';
  }
}
