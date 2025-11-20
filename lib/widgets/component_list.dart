import 'package:flutter/material.dart';
import '../models/component.dart';
import '../widgets/adjustment_display_list.dart';

class ComponentList extends StatefulWidget {
  final List<Component> components;
  final void Function(Component component) editComponent;
  final void Function(Component component) duplicateComponent;
  final void Function(Component component) removeComponent;

  const ComponentList({
    super.key,
    required this.components,
    required this.editComponent,
    required this.duplicateComponent,
    required this.removeComponent,
  });

  @override
  State<ComponentList> createState() => _ComponentListState();
}

class _ComponentListState extends State<ComponentList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded
        ? widget.components.length
        : widget.components.length.clamp(0, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCount,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, index) {
            final component = widget.components[index];
            final componentAdjustmentValues = Map.fromEntries(
              (component.currentSetting?.adjustmentValues ?? {})
                  .entries
                  .where((e) => component.adjustments.contains(e.key)),
            );

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: const Icon(Icons.tune),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  component.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.pedal_bike, size: 13, color: Colors.grey.shade800),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            component.bike.name,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('${component.adjustments.length} adjustments '),
                        for (final adjustment in component.adjustments)
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: adjustment.getIcon(size: 13, color: Colors.grey.shade800),
                          ),
                      ],
                    ),
                    AdjustmentDisplayList(
                      adjustmentValues: componentAdjustmentValues,
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.editComponent(component);
                    } else if (value == "duplicate") {
                      widget.duplicateComponent(component);
                    } else if (value == 'remove') {
                      widget.removeComponent(component);
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
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 10),
                          Text('Duplicate'),
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
        ),

        if (widget.components.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(_expanded ? "Show less" : "Show more"),
            ),
          ),
      ],
    );
  }
}
