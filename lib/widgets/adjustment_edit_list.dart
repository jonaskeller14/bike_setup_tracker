import 'package:flutter/material.dart';
import '../models/adjustment.dart';

class AdjustmentEditList extends StatelessWidget {
  final List<Adjustment> adjustments;
  final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;

  const AdjustmentEditList({
    super.key,
    required this.adjustments,
    required this.editAdjustment,
    required this.removeAdjustment,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: adjustments.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final adjustment = adjustments[index];
        String adjustmentProperties = adjustment.getProperties();
        Icon icon = adjustment.getIcon();
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
            subtitle: Text(
              adjustmentProperties,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  editAdjustment(adjustment);
                } else if (value == 'remove') {
                  removeAdjustment(adjustment);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit', 
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
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
