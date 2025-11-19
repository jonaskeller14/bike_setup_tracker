import 'package:flutter/material.dart';
import '../models/adjustment.dart';

class AdjustmentEditList extends StatelessWidget {
  final List<Adjustment> adjustments;
  // final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;

  const AdjustmentEditList({
    super.key,
    required this.adjustments,
    // required this.editAdjustment,
    required this.removeAdjustment,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: adjustments.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final adjustment = adjustments[index];
        String? adjustmentProperties;
        Icon? icon;
        if (adjustment is BooleanAdjustment) {
          icon = Icon(Icons.toggle_on);
          adjustmentProperties = "(On/Off)";
        } else if (adjustment is NumericalAdjustment) {
          icon = Icon(Icons.numbers);
          adjustmentProperties = "Range ${adjustment.min}..${adjustment.max} [${adjustment.unit ?? ''}]";
        } else if (adjustment is StepAdjustment) {
          icon = Icon(Icons.format_list_numbered);
          adjustmentProperties = "Range ${adjustment.min}..${adjustment.max}, Step ${adjustment.step}";
        } else if (adjustment is CategoricalAdjustment) {
          icon = Icon(Icons.category);
          adjustmentProperties = adjustment.options.join('/');
        } else {
          adjustmentProperties = null;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: icon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              adjustment.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: adjustmentProperties != null
                ? Text(
                    adjustmentProperties,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // editAdjustment(adjustment);
                } else if (value == 'remove') {
                  removeAdjustment(adjustment);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                // const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 10),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
