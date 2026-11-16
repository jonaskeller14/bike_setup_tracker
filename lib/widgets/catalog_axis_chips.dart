import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../l10n/catalog_labels.dart';
import '../l10n/l10n.dart';
import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import 'sheets/sheet.dart';

/// The values of one catalog option [axis] as choice chips under its name.
class CatalogAxisChips extends StatelessWidget {
  const CatalogAxisChips({super.key, required this.axis, required this.selected, required this.onTap});

  final OptionAxis axis;
  final OptionValue? selected;
  final ValueChanged<OptionValue> onTap;

  @override
  Widget build(BuildContext context) {
    final groups = _chipGroups(axis, context.l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetGroupTitle(title: axis.key.name(context.l10n)),
        for (final MapEntry(key: heading, value: values) in groups.entries) ...[
          if (heading != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                heading,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(value.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: value == selected,
                  onSelected: (_) => onTap(value),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Shock sizes are grouped by eye-to-eye length, since that is what a frame
/// fixes and the stroke is chosen within it. Every other axis is one group
/// without a heading, as is a size axis that lists strokes only.
Map<String?, List<OptionValue>> _chipGroups(OptionAxis axis, AppLocalizations l10n) {
  if (axis.id != PresetOptionAxes.size.id) return {null: axis.values};
  final byLength = groupBy(axis.values, (value) => value.specs.get(PresetSpecKeys.eyeToEyeMm));
  if (byLength.keys.every((length) => length == null)) return {null: axis.values};
  return {
    for (final MapEntry(key: length, value: values) in byLength.entries)
      length == null
              ? l10n.catalogPickerCategoryOther
              : '${PresetSpecKeys.eyeToEyeMm.name(l10n)} ${PresetSpecKeys.eyeToEyeMm.format(length)}':
          values,
  };
}
