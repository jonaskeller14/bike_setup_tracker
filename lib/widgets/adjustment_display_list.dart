import '../models/adjustment.dart';
import 'package:flutter/material.dart';

class AdjustmentDisplayList extends StatelessWidget {
  final Map<Adjustment, dynamic> adjustmentValues;

  const AdjustmentDisplayList({
    super.key,
    required this.adjustmentValues,
  });

  @override
  Widget build(BuildContext context) {
    final items = adjustmentValues.entries.toList();
    List<Widget> children = [];

    for (int index = 0; index < items.length; index++) {
      final entry = items[index];
      final adjustment = entry.key;
      final value = entry.value;

      children.add(
        _AdjustmentTableCell(
          title: adjustment.name,
          value: _formatValue(adjustment, value),
        ),
      );

      if (index != items.length - 1) {
        children.add(_VerticalDivider());
      }
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 12,
      runSpacing: 12,
      children: children,
    );
  }

  String _formatValue(Adjustment adjustment, dynamic value) {
    String unit = "";

    try {
      final dyn = adjustment as dynamic;
      final possibleUnit = dyn.unit;
      if (possibleUnit != null) unit = possibleUnit.toString();
    // ignore: empty_catches
    } catch (e) {}

    final valText = value == null ? '' : Adjustment.formatValue(value);
    return unit.isNotEmpty ? '$valText $unit' : valText;
  }
}

class _AdjustmentTableCell extends StatelessWidget {
  final String title;
  final String value;

  const _AdjustmentTableCell({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 1,
      height: 40,
      color: Colors.grey.shade400,
    );
  }
}




