import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/component.dart';
import '../models/setup.dart';
import '../models/bike.dart';
import '../widgets/adjustment_display_list.dart';
import '../pages/component_overview_page.dart';

const defaultVisibleCount = 10;

class ComponentList extends StatefulWidget {
  final Map<String, Bike> bikes;
  final List<Component> components;
  final List<Setup> setups;
  final Future<void> Function(Component component) editComponent;
  final Future<void> Function(Component component) duplicateComponent;
  final Future<void> Function(Component component) removeComponent;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final Widget filterWidget;

  const ComponentList({
    super.key,
    required this.bikes,
    required this.components,
    required this.setups,
    required this.editComponent,
    required this.duplicateComponent,
    required this.removeComponent,
    required this.onReorder,
    required this.filterWidget,
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
    for (int index = 0; index < visibleCount; index++) {
      final component = widget.components[index];
      cards.add(
        Card(
          key: ValueKey(component.id),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(component.componentType.getIconData()),
                minTileHeight: 0,
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                title: Text(
                  component.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                enabled: widget.setups.lastWhereOrNull((s) => s.bike == component.bike) != null,
                onTap: () async {
                  await Navigator.push<Component>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComponentOverviewPage(component: component, setups: widget.setups),
                    ),
                  );
                },
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Bike.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              widget.bikes[component.bike]?.name ?? "-",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: AdjustmentDisplayList(
                  components: [component],
                  adjustmentValues: widget.setups.lastWhereOrNull((s) => s.bike == component.bike)?.bikeAdjustmentValues ?? {},
                  showComponentIcons: false,
                  missingValuesPlaceholder: true,
                  displayBikeAdjustmentValues: true,
                  displayPersonAdjustmentValues: false,
                  displayRatingAdjustmentValues: false,
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
    
    return widget.components.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.filterWidget,
                Expanded(
                  child: Center(
                    child: Text(
                      'No components yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          )
        : ReorderableListView.builder(
            itemCount: visibleCount,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: widget.filterWidget,
            footer: widget.components.length > defaultVisibleCount
                ? Center(
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
                  )
                : null,
            onReorder: widget.onReorder,
            proxyDecorator: proxyDecorator,
            itemBuilder: (context, index) {
              return cards[index];
            },
          );
  }
}
