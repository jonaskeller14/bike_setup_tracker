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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: adjustments.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final adjustment = adjustments[index];
        String? adjustmentProperties;
        if (adjustment is BooleanAdjustment) {
          adjustmentProperties = "(On/Off)";
        } else if (adjustment is NumericalAdjustment) {
          adjustmentProperties = "(Range ${adjustment.min} - ${adjustment.max}, Unit: ${adjustment.unit ?? 'none'})";
        } else if (adjustment is StepAdjustment) {
          adjustmentProperties = "(Range ${adjustment.min} - ${adjustment.max}, Step ${adjustment.step})";
        } else if (adjustment is CategoricalAdjustment) {
          adjustmentProperties = "(${adjustment.options.join('/')})";
        } else {
          adjustmentProperties = null;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: ListTile(
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
                  child: Text('Remove'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
