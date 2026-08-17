import 'package:flutter/material.dart';

import '../../models/setup_comparison.dart' as comparison;
import 'setup_comparison_row.dart';

class SetupComparisonSection extends StatelessWidget {
  final comparison.SetupComparisonGroup group;
  final bool differencesOnly;

  const SetupComparisonSection({super.key, required this.group, required this.differencesOnly});

  @override
  Widget build(BuildContext context) {
    final rows = group.visibleRows(differencesOnly: differencesOnly);
    return KeyedSubtree(
      key: Key('compare-section-${group.kind.name}-${group.ownerId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Text(group.label, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (rows.isEmpty && group.isStructuralDifference)
                ListTile(
                  key: Key('compare-group-${group.kind.name}-${group.ownerId}'),
                  dense: true,
                  leading: const Icon(Icons.compare_arrows),
                  title: const Text('Available on only one side'),
                )
              else
                for (final row in rows) SetupComparisonRow(groupId: group.ownerId, row: row),
            ],
          ),
        ),
      ),
    );
  }
}
