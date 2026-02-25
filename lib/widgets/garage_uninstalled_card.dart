import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/filtered_data.dart';
import 'component_list_card.dart';
import 'garage_component_icon_card.dart';

class GarageUninstalledCard extends StatelessWidget{
  final String? componentToShowDetails;
  final void Function(Component) onPressedComponent;

  const GarageUninstalledCard({super.key, required this.componentToShowDetails, required this.onPressedComponent});

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final Map<String, Component> deinstalledComponents = Map.fromEntries(filteredData.components.entries.where((ce) => !filteredData.bikes.keys.contains(ce.value.bike)));

    return DragTarget<Component>(
      builder: (context, candidateItems, rejectedItems) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.shelves),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  "Archive - Deinstalled components",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: null,
                trailing: null,
              ),

              if (candidateItems.isEmpty || candidateItems.every((c) => c != null && deinstalledComponents.values.contains(c)))
                if (deinstalledComponents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 40),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(), 
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        child: const Center(
                          child: Text("Drag components here to deinstall from bike"),
                        )
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap( //TODO: make it draggable?!
                      spacing: 6,
                      runSpacing: 6,
                      children: deinstalledComponents.values.map((component) => GestureDetector(
                        onTap: () => onPressedComponent(component),
                        child: GarageComponentIconCard(
                          component: component, 
                          componentToShowDetails: componentToShowDetails
                        ),
                      )).toList(),
                    ),
                  )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 40),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(), 
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: const Center(
                        child: Text("Release to remove component from bike"),
                      )
                    ),
                  ),
                ),
              if (componentToShowDetails != null && deinstalledComponents.keys.contains(componentToShowDetails))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: LongPressDraggable<Component>(
                    data: deinstalledComponents[componentToShowDetails]!,
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: GarageComponentIconCard(
                      component: deinstalledComponents[componentToShowDetails]!, 
                      componentToShowDetails: componentToShowDetails
                    ),
                    child: ComponentListCard(
                      component: deinstalledComponents[componentToShowDetails]!,
                      index: null,
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      onAcceptWithDetails: (details) {
        final Component component = details.data;
        context.read<AppData>().editComponent(component.copyWith(bike: null));
      },
    ); 
  }
}
