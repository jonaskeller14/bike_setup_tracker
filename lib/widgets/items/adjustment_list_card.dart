import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../notes_text.dart';
import 'adjustment_properties.dart';
import 'adjustment_type_icon.dart';

class AdjustmentListCard extends StatelessWidget {
  final Adjustment adjustment;
  final int index;
  final double? elevation;
  final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) duplicateAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;
  final Map<String, Adjustment>? initialAdjustments;
  final double? metricWeight;

  const AdjustmentListCard({
    super.key,
    required this.adjustment,
    required this.index,
    this.elevation,
    required this.editAdjustment,
    required this.duplicateAdjustment,
    required this.removeAdjustment,
    this.initialAdjustments,
    this.metricWeight,
  });

  bool get _isScored =>
      adjustment is StepAdjustment ||
      adjustment is NumericalAdjustment ||
      adjustment is DurationAdjustment ||
      adjustment is BooleanAdjustment;

  Widget _weightChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final weight = metricWeight!;

    if (!_isScored || weight == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "not scored",
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );
    }

    final abs = weight.abs();
    final w = abs == abs.roundToDouble() ? abs.toStringAsFixed(0) : abs.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "×$w",
        style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(adjustment.id),
      color: initialAdjustments != null && initialAdjustments![adjustment.id] != adjustment
          ? Color.lerp(Theme.of(context).colorScheme.surface, Colors.orange, 0.08)
          : null,
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.titleHeight,
        leading: AdjustmentTypeIcon(adjustment),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                adjustment.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (metricWeight != null) ...[
              const SizedBox(width: 8),
              _weightChip(context),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            AdjustmentProperties(adjustment),
            if (adjustment.notes != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2), // tweak to match font size
                    child: Icon(
                      Icons.notes,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: NotesText(
                      adjustment.notes!,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
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
