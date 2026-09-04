import 'package:flutter/material.dart';

import 'display_adjustment/display_dangling_adjustment.dart';
import 'initial_changed_value_legend.dart';
import 'items/card_header_tile.dart';

Widget cardErrorBadgeDot(BuildContext context, {double size = 9}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      color: scheme.surface,
      shape: BoxShape.circle,
      border: Border.all(color: scheme.error, width: 1),
    ),
    child: Icon(Icons.error, size: size, color: scheme.error),
  );
}

Widget danglingValuesCard(BuildContext context, {
  required Map<String, dynamic> values,
  required String title,
  required String cause,
  required void Function(String) onRemove,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CardHeaderTile(
          color: scheme.errorContainer,
          child: ListTile(
            leading: Icon(Icons.error_outline, color: scheme.error),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
            subtitle: Text(cause, style: TextStyle(color: scheme.error)),
          ),
        ),
        ...values.entries.map((danglingAdjustmentValue) {
          return DisplayDanglingAdjustmentWidget(
            name: danglingAdjustmentValue.key,
            value: danglingAdjustmentValue.value,
            onRemove: () => onRemove(danglingAdjustmentValue.key),
          );
        }),
      ],
    ),
  );
}

class SetupTabScaffold extends StatelessWidget {
  final List<Widget> children;
  final bool showLegend;

  const SetupTabScaffold({
    super.key, 
    required this.children,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          if (showLegend) const InitialChangedValueLegend(),
        ],
      ),
    );
  }
}
