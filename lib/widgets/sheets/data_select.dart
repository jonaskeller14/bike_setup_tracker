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
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Confirm Selection"),
                  ),
                  //TODO: Add select all / none toggle which also shows state where subselection is selected
                  //TODO: Add this also for categories indivdually?
                  //TOOD: Make sections collapsable?
                  const Divider(),
                  const Text("Bikes"),
                  ...allBikes.map((bike) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: CheckboxListTile(
                        title: Text(bike.name),
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
                  }),
                  const Text("Components"),
                  ...allComponents.map((component) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: CheckboxListTile(
                        title: Text(component.name),
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
                  }),
                  const Text("Setups"),
                  ...allSetups.map((setup) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: CheckboxListTile(
                        title: Text(setup.name),
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
                  }),
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
