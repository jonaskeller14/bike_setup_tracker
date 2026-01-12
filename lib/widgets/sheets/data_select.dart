import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "../../models/bike.dart";
import "../../models/component.dart";
import "../../models/setup.dart";
import "../../utils/data.dart";
import 'sheet.dart';

Future<Data?> showDataSelectSheet({required BuildContext context, required Data data}) async {
  final bool? applySelection = await showModalBottomSheet<bool?>(
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    sheetTitle(context, 'Select Data'),
                    sheetCloseButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.select_all, color: Theme.of(context).colorScheme.primary),
                title: const Text("Entire dataset"),
                subtitle: const Text("Use all items from the provided data"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
                title: const Text("Choose specific items"),
                subtitle: const Text("Pick which items to include"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (applySelection == false) return data;
  if (applySelection == null) return null;

  final List<Bike> allBikes = data.bikes.values.toList();
  final List<Component> allComponents = data.components;
  final List<Setup> allSetups = data.setups;

  final List<Bike> selectedBikes = allBikes.toList();
  final List<Component> selectedComponents = allComponents.toList();
  final List<Setup> selectedSetups = allSetups.toList();

  if (!context.mounted) return null;
  final selectionConfirmed = await showModalBottomSheet<bool?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        sheetTitle(context, 'Select Data'),
                        sheetCloseButton(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Bikes (${selectedBikes.length} / ${allBikes.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox(
                      tristate: true,
                      value: selectedBikes.isEmpty && allBikes.isNotEmpty
                          ? false 
                          : (selectedBikes.length == allBikes.length ? true : null),
                      onChanged: (bool? newValue) {
                        switch (newValue) {
                          case false: setSheetState(() => selectedBikes.clear());
                          case true: setSheetState(() {selectedBikes.clear(); selectedBikes.addAll(allBikes);});
                          case null: setSheetState(() => selectedBikes.clear());
                        }
                      },
                    ),
                    children: allBikes.map((bike) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: CheckboxListTile(
                          secondary: const Icon(Icons.pedal_bike),
                          title: Text(
                            bike.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: bike.isDeleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          dense: true,
                          value: selectedBikes.contains(bike),
                          onChanged: (bool? checked) {
                            setSheetState(() {
                              if (checked == true) {
                                selectedBikes.add(bike);
                              } else {
                                selectedBikes.remove(bike);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Components (${selectedComponents.length} / ${allComponents.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox(
                      tristate: true,
                      value: selectedComponents.isEmpty && allComponents.isNotEmpty
                          ? false 
                          : (selectedComponents.length == allComponents.length ? true : null),
                      onChanged: (bool? newValue) {
                        switch (newValue) {
                          case false: setSheetState(() => selectedComponents.clear());
                          case true: setSheetState(() {selectedComponents.clear(); selectedComponents.addAll(allComponents);});
                          case null: setSheetState(() => selectedComponents.clear());
                        }
                      },
                    ),
                    children: allComponents.map((component) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: CheckboxListTile(
                          secondary: Component.getIcon(component.componentType),
                          title: Text(
                            component.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: component.isDeleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pedal_bike, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Text(
                                allBikes.firstWhereOrNull((b) => b.id == component.bike)?.name ?? "-",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          dense: true,
                          value: selectedComponents.contains(component),
                          onChanged: (bool? checked) {
                            setSheetState(() {
                              if (checked == true) {
                                selectedComponents.add(component);
                              } else {
                                selectedComponents.remove(component);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Setups (${selectedSetups.length} / ${allSetups.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox(
                      tristate: true,
                      value: selectedSetups.isEmpty && allSetups.isNotEmpty
                          ? false 
                          : (selectedSetups.length == allSetups.length ? true : null),
                      onChanged: (bool? newValue) {
                        switch (newValue) {
                          case false: setSheetState(() => selectedSetups.clear());
                          case true: setSheetState(() {selectedSetups.clear(); selectedSetups.addAll(allSetups);});
                          case null: setSheetState(() => selectedSetups.clear());
                        }
                      },
                    ),
                    children: allSetups.map((setup) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: CheckboxListTile(
                          secondary: const Icon(Icons.tune),
                          title: Text(
                            setup.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: setup.isDeleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pedal_bike, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Text(
                                allBikes.firstWhereOrNull((b) => b.id == setup.bike)?.name ?? "-",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          dense: true,
                          value: selectedSetups.contains(setup),
                          onChanged: (bool? checked) {
                            setSheetState(() {
                              if (checked == true) {
                                selectedSetups.add(setup);
                              } else {
                                selectedSetups.remove(setup);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirm Selection"),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      );
    }
  );

  if (selectionConfirmed == true) {
    return Data(
      bikes: <String, Bike>{for (var item in selectedBikes) item.id: item},
      setups: selectedSetups,
      components: selectedComponents,
    );
  }

  return null;
}
