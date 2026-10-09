import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../utils/adjustment_preset_consumption.dart';
import '../items/adjustment_properties.dart';
import '../items/adjustment_type_icon.dart';
import 'sheet.dart';

/// Preset tiles for an "add adjustment" sheet: presets not yet added are listed
/// directly, already-added ones collapse into an "Already added" group.
class AdjustmentPresetList extends StatelessWidget {
  final List<Adjustment> presets;
  final List<Adjustment> existingAdjustments;
  final String allAddedHint;
  final Future<void> Function(Adjustment preset) onSelected;

  const AdjustmentPresetList({
    super.key,
    required this.presets,
    required this.existingAdjustments,
    required this.allAddedHint,
    required this.onSelected,
  });

  Widget _presetTile(BuildContext context, Adjustment preset, {required bool consumed}) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final tile = ListTile(
      textColor: consumed ? mutedColor : null,
      iconColor: consumed ? mutedColor : null,
      leading: AdjustmentTypeIcon(preset, color: consumed ? mutedColor : null),
      title: Text(preset.name),
      subtitle: AdjustmentProperties(preset, singleLine: true, compact: true),
      trailing: Icon(consumed ? Icons.check : Icons.arrow_forward_ios, size: 16.0),
      onTap: () async {
        Navigator.pop(context);
        await onSelected(preset);
      },
    );
    return consumed ? Opacity(opacity: 0.6, child: tile) : tile;
  }

  Widget _consumedGroup(BuildContext context, List<Adjustment> consumed) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      dense: true,
      textColor: mutedColor,
      collapsedTextColor: mutedColor,
      iconColor: mutedColor,
      collapsedIconColor: mutedColor,
      title: Text("Already added (${consumed.length})"),
      // Already-added presets stay tappable for a deliberate second copy.
      children: consumed.map((preset) => _presetTile(context, preset, consumed: true)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = <Adjustment>[];
    final consumed = <Adjustment>[];
    for (final preset in presets) {
      (isAdjustmentPresetConsumed(preset, existingAdjustments) ? consumed : available).add(preset);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...available.map((preset) => _presetTile(context, preset, consumed: false)),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SheetFilterEmptyHint(
              icon: Icons.check_circle_outline,
              title: "All suggestions added",
              hint: allAddedHint,
            ),
          ),
        if (consumed.isNotEmpty) _consumedGroup(context, consumed),
      ],
    );
  }
}
