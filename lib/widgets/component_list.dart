import 'package:flutter/material.dart';
import '../models/component.dart';
import '../widgets/adjustment_display_list.dart';

class ComponentList extends StatelessWidget {
  final List<Component> components;
  final void Function(Component component) editComponent;
  final void Function(Component component) removeComponent;

  const ComponentList({
    super.key,
    required this.components,
    required this.editComponent,
    required this.removeComponent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: components.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final component = components[index];
        final componentAdjustmentValues = Map.fromEntries(
          (component.currentSetting?.adjustmentValues ?? {})
              .entries
              .where((e) => component.adjustments.contains(e.key)),
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: ListTile(
            leading: const Icon(Icons.casino),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              component.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text('${component.adjustments.length} adjustments'),
                ),
                AdjustmentDisplayList(
                  adjustmentValues: componentAdjustmentValues,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  editComponent(component);
                } else if (value == 'remove') {
                  removeComponent(component);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
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
