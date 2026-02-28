import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../models/component.dart';
import '../models/filtered_data.dart';
import '../models/bike.dart';
import '../pages/component_page.dart';
import 'adjustment_compact_display_list.dart';
import '../pages/component_overview_page.dart';

class ComponentListCard extends StatelessWidget{
  final Component component;
  final int? index;
  final double? elevation;
  final Color? color;

  const ComponentListCard({
    super.key,
    required this.component,
    this.index,
    this.elevation,
    this.color,
  });

  Future<void> _editComponent(BuildContext context, {required Component component}) async {
    final data = context.read<AppData>();

    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.edit(component: component),
      ),
    );
    if (editedComponent == null) return;

    data.editComponent(editedComponent);
  }

  Future<void> _duplicateComponent(BuildContext context, {required Component component}) async {
    final data = context.read<AppData>();

    final newComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.duplicate(component: component.deepCopy()),
      ),
    );
    if (newComponent == null) return;

    data.addComponent(newComponent);
  }

  Future<void> _removeComponent(BuildContext context, {required Component component}) async {
    final data = context.read<AppData>();
    data.removeComponents([component]);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Component '${component.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => data.restoreComponents([component]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final bikes = filteredData.bikes;
    final setups = filteredData.setups;
    final enabled = setups.values.lastWhereOrNull((s) => s.bike == component.bike) != null;
    return Card(
      key: ValueKey(component.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      color: color,
      child: InkWell(
        onTap: enabled
            ? () async {
                await Navigator.push<Component>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComponentOverviewPage(componentId: component.id, editComponent: _editComponent),
                  ),
                );
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(component.componentType.getIconData()),
              minTileHeight: 0,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              title: Text(
                component.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              enabled: enabled,
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
                        spacing: 2,
                        children: [
                          Icon(component.bike != null 
                              ? Bike.iconData 
                              : Icons.shelves, 
                            size: 13, 
                            color: component.bike == null || bikes.containsKey(component.bike) 
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.error,
                          ),
                          Flexible(
                            child: Text(
                              component.bike == null 
                                  ? "Not installed" 
                                  : bikes[component.bike]?.name ?? "BIKE NOT FOUND",
                              style: TextStyle(
                                color: component.bike == null || bikes.containsKey(component.bike) 
                                    ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                    : Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (component.notes != null && component.notes!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.notes,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            component.notes!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index != null)
                    ReorderableDragStartListener(
                      index: index!,
                      child: const Icon(Icons.drag_handle),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit': _editComponent(context, component: component);
                        case 'duplicate': _duplicateComponent(context, component: component);
                        case 'remove': _removeComponent(context, component: component);
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
              child: AdjustmentCompactDisplayList(
                components: [component],
                adjustmentValues: setups.values.lastWhereOrNull((s) => s.bike == component.bike)?.bikeAdjustmentValues ?? {},
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
}
