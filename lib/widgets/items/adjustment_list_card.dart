import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';

class AdjustmentListCard extends StatelessWidget {
  final Adjustment adjustment;
  final int index;
  final double? elevation;
  final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) duplicateAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;
  final Map<String, Adjustment>? initialAdjustments;

  const AdjustmentListCard({
    super.key,
    required this.adjustment,
    required this.index,
    this.elevation,
    required this.editAdjustment,
    required this.duplicateAdjustment,
    required this.removeAdjustment,
    this.initialAdjustments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(adjustment.id),
      color: initialAdjustments != null && initialAdjustments![adjustment.id] != adjustment 
          ? Color.lerp(Theme.of(context).colorScheme.surface, Colors.orange, 0.08) 
          : null,
      child: ListTile(
        leading: Icon(adjustment.getIconData()),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          adjustment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(Icons.info_outline, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    adjustment.getProperties(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (adjustment.unit != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.straighten, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Unit: ${adjustment.unit}",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (adjustment.notes != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3), // tweak to match font size
                    child: Icon(
                      Icons.notes,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      adjustment.notes!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            PopupMenuButton<_AdjustmentOptions>(
              onSelected: (_AdjustmentOptions value) {
                switch (value) {
                  case _AdjustmentOptions.edit: editAdjustment(adjustment);
                  case _AdjustmentOptions.duplicate: duplicateAdjustment(adjustment);
                  case _AdjustmentOptions.remove: removeAdjustment(adjustment);
                }
              },
              itemBuilder: (BuildContext context) => _AdjustmentOptions.values.map((option) {
                return PopupMenuItem<_AdjustmentOptions>(
                  value: option,
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(option.iconData, size: 20),
                      Text(option.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AdjustmentOptions {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _AdjustmentOptions(this.label, this.iconData);
}
