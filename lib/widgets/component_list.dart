import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/component.dart';
import '../models/setup.dart';
import '../widgets/adjustment_display_list.dart';
import '../pages/component_overview_page.dart';

const defaultVisibleCount = 10;

class ComponentList extends StatefulWidget {
  final List<Component> components;
  final List<Setup> setups;
  final Future<void> Function(Component component) editComponent;
  final Future<void> Function(Component component) duplicateComponent;
  final Future<void> Function(Component component) removeComponent;
  final Future<void> Function(int oldIndex, int newIndex) onReorder; 

  const ComponentList({
    super.key,
    required this.components,
    required this.setups,
    required this.editComponent,
    required this.duplicateComponent,
    required this.removeComponent,
    required this.onReorder,
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
        : widget.components.length.clamp(0, defaultVisibleCount);

    final List<Card> cards = <Card>[];
    for (final component in widget.components.take(visibleCount)) {
      cards.add(
        Card(
          key: ValueKey(component.id),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Component.getIcon(component.componentType),
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                title: Text(
                  component.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await Navigator.push<Component>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComponentOverviewPage(component: component, setups: widget.setups),
                    ),
                  );
                },
                subtitle: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.pedal_bike, size: 13, color: Colors.grey.shade800),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        component.bike.name,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle),
                    PopupMenuButton<String>(
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Text(
                      '${component.adjustments.length} adjustments ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    for (final adjustment in component.adjustments)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: adjustment.getIcon(size: 13, color: Colors.grey.shade800),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: AdjustmentDisplayList(
                  components: [component],
                  adjustmentValues: widget.setups.lastWhereOrNull((s) => s.bike == component.bike)?.adjustmentValues ?? {},
                  showComponentIcons: false,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(1, 6, animValue)!;
        final double scale = lerpDouble(1, 1.03, animValue)!;
        return Transform.scale(
          scale: scale,
          child: Card(elevation: elevation, color: cards[index].color, child: cards[index].child),
          );
        },
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCount,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          onReorder: widget.onReorder,
          proxyDecorator: proxyDecorator,
          itemBuilder: (context, index) {
            return cards[index];
          },
        ),
        if (widget.components.length > defaultVisibleCount)
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
