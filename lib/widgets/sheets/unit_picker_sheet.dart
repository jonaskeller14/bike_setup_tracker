import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment_unit.dart';
import 'sheet_header.dart';

const int unitPickerMaxCustomLength = 10;

/// Suggests a known unit for a raw typed string, for the "Did you mean X?"
/// hint in the custom-unit row. Reuses the same alias table as migration/import.
KnownUnit? suggestKnownUnitFor(String raw) {
  final unit = AdjustmentUnit.fromLegacy(raw);
  return unit is KnownUnit ? unit : null;
}

/// Opens the unit picker bottom sheet. Every pick applies immediately via
/// [onSelected]. Picking a new unit closes the sheet; tapping the
/// already-selected chip clears it via [onSelected] but keeps the sheet open
/// so another unit can still be picked. Dismissing the sheet without picking
/// anything (back button, scrim tap, drag-down) simply never calls
/// [onSelected], so the caller's state is untouched.
void showUnitPickerSheet({
  required BuildContext context,
  required AdjustmentUnit? current,
  required ValueChanged<AdjustmentUnit?> onSelected,
}) async {
  await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _UnitPickerSheet(current: current, onSelected: onSelected),
  );
}

class _UnitPickerSheet extends StatefulWidget {
  final AdjustmentUnit? current;
  final ValueChanged<AdjustmentUnit?> onSelected;

  const _UnitPickerSheet({required this.current, required this.onSelected});

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  late final TextEditingController _customController;
  late AdjustmentUnit? _selected;
  late bool _showCustomTextField;

  bool get _isCustomActive => _selected is CustomUnit && !blessedCustomUnitLabels.contains((_selected as CustomUnit).label);

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _showCustomTextField = _isCustomActive;
    _customController = TextEditingController(
      text: _isCustomActive ? (_selected as CustomUnit).label : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Picks a new unit: applies it and closes the sheet.
  void _select(AdjustmentUnit unit) {
    setState(() => _selected = unit);
    widget.onSelected(unit);
    Navigator.pop(context);
  }

  /// Clears the currently-selected chip: applies the clear but keeps the
  /// sheet open so another unit can still be picked.
  void _deselect() {
    setState(() => _selected = null);
    widget.onSelected(null);
  }

  static const double _quantityLabelWidth = 84;

  Widget _quantityRow(UnitQuantity quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _quantityLabelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                quantity.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final entry in unitCatalog[quantity]!)
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(entry.label),
                    selected: _selected == KnownUnit(quantity: quantity, unitId: entry.unitId),
                    onSelected: (_) {
                      final unit = KnownUnit(quantity: quantity, unitId: entry.unitId);
                      _selected == unit ? _deselect() : _select(unit);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: _quantityLabelWidth,
            child: Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Custom',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final label in blessedCustomUnitLabels)
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(label),
                    selected: _selected == CustomUnit(label),
                    onSelected: (_) =>
                        _selected == CustomUnit(label) ? _deselect() : _select(CustomUnit(label)),
                  ),
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(_isCustomActive ? (_selected as CustomUnit).label : 'Other'),
                  avatar: _isCustomActive ? null : const Icon(Icons.edit),
                  selected: _isCustomActive,
                  onSelected: (_) {
                    if (_isCustomActive) {
                      // Deselecting the active custom chip: clear the field and
                      // the selection, but keep the sheet open to pick again.
                      _customController.clear();
                      _deselect();
                    } else {
                      setState(() => _showCustomTextField = !_showCustomTextField);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestion = _customController.text.trim().isEmpty
        ? null
        : suggestKnownUnitFor(_customController.text.trim());

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: "Choose Unit", leadingIcon: Icon(Icons.straighten)),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final quantity in UnitQuantity.values) _quantityRow(quantity),
                  _customRow(),
                  if (_showCustomTextField) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customController,
                      autofocus: true,
                      maxLength: unitPickerMaxCustomLength,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isEmpty) return;
                        _select(CustomUnit(trimmed));
                      },
                      decoration: InputDecoration(
                        labelText: 'Custom unit',
                        hintText: 'Enter a custom unit',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: _customController.text.trim().isEmpty
                              ? null
                              : () => _select(CustomUnit(_customController.text.trim())),
                        ),
                      ),
                    ),
                    if (suggestion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: InkWell(
                          onTap: () => _select(suggestion),
                          child: Text(
                            'Did you mean "${suggestion.label}" (${suggestion.quantity.label})?',
                            style: TextStyle(color: colorScheme.primary, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
