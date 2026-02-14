import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/component.dart';
import 'component_list_card.dart';

class ComponentList extends StatelessWidget {
  final Map<String, Component> components;
  final Future<void> Function(Component component) editComponent;
  final Future<void> Function(Component component) duplicateComponent;
  final Future<void> Function(Component component) removeComponent;
  final Future<void> Function(int oldIndex, int newIndex) onReorderComponent;
  final Widget filterWidget;

  const ComponentList({
    super.key,
    required this.components,
    required this.editComponent,
    required this.duplicateComponent,
    required this.removeComponent,
    required this.onReorderComponent,
    required this.filterWidget,
  });

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterWidget,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final componentsList = components.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: ComponentListCard(
              component: componentsList[index],
              index: index,
              elevation: elevation,
              editComponent: editComponent,
              duplicateComponent: duplicateComponent,
              removeComponent: removeComponent,
            ),
          );
        },
        child: child,
      );
    }

    return components.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: componentsList.length,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: filterWidget,
            proxyDecorator: proxyDecorator,
            onReorder: onReorderComponent,
            itemBuilder: (context, index) {
              final component = componentsList[index];
              return ComponentListCard(
                key: ValueKey(component.id),
                component: component,
                index: index,
                editComponent: editComponent,
                duplicateComponent: duplicateComponent,
                removeComponent: removeComponent
              );
            },
          );
  }
}
