import 'package:flutter/material.dart';
import '../models/component.dart';

class ComponentList extends StatelessWidget {
  final List<Component> components;
  final void Function(int index)? onEdit;
  final void Function(Component component) removeComponent;

  const ComponentList({
    super.key,
    required this.components,
    this.onEdit,
    required this.removeComponent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: components.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final component = components[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              component.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  if (onEdit != null) onEdit!(index);
                } else if (value == 'remove') {
                  removeComponent(component);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
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
