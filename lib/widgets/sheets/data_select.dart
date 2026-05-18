import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../models/app_settings.dart";
import "../../models/bike.dart";
import "../../models/component.dart";
import "../../models/person.dart";
import "../../models/rating.dart";
import "../../models/selected_data.dart";
import "../../models/setup.dart";
import "../../models/task_entry.dart";
import "../../models/task_rule.dart";
import "../../repositories/app_repository.dart";
import 'sheet.dart';

Future<SelectedData?> showDataSelectSheet({required BuildContext context, required AppRepository data}) async {
  return showModalBottomSheet<SelectedData?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DataSelectFlow(allData: data);
    },
  );
}

class DataSelectFlow extends StatefulWidget {
  final AppRepository allData;
  const DataSelectFlow({super.key, required this.allData});

  @override
  State<DataSelectFlow> createState() => _DataSelectFlowState();
}

class _DataSelectFlowState extends State<DataSelectFlow> {
  bool isManualSelection = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 'canPop' is true if we are on Step One (let it close).
      // 'canPop' is false if we are on Step Two (we want to intercept it).
      canPop: !isManualSelection, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;  // If the pop already happened (Step One), do nothing.
        setState(() => isManualSelection = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isManualSelection
            ? SelectDataItemsSheetContent(
                allData: SelectedData(
                  persons: widget.allData.persons,
                  bikes: widget.allData.bikes,
                  components: widget.allData.components,
                  setups: widget.allData.setups,
                  ratings: widget.allData.ratings,
                  taskRules: widget.allData.taskRules,
                  taskEntries: widget.allData.taskEntries,
                ),
                onBack: () => setState(() => isManualSelection = false),
                onConfirm: (data) => Navigator.of(context).pop(data),
              )
            : SelectDataMethodSheetContent(
                onAllSelected: () => Navigator.of(context).pop(SelectedData(
                  persons: widget.allData.persons,
                  bikes: widget.allData.bikes,
                  components: widget.allData.components,
                  setups: widget.allData.setups,
                  ratings: widget.allData.ratings,
                  taskRules: widget.allData.taskRules,
                  taskEntries: widget.allData.taskEntries,
                )),
                onManualSelected: () => setState(() => isManualSelection = true),
              ),
      ),
    );
  }
}

class SelectDataMethodSheetContent extends StatelessWidget {
  final VoidCallback onAllSelected;
  final VoidCallback onManualSelected;
  final VoidCallback? onBack;

  const SelectDataMethodSheetContent({super.key, required this.onAllSelected, required this.onManualSelected, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  sheetBackButton(context, onPressed: onBack!),
                sheetTitle(context, 'Select Data'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.select_all, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Entire dataset"),
                    subtitle: const Text("Use all items from the provided data"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onAllSelected,
                  ),
                  ListTile(
                    leading: Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Choose specific items"),
                    subtitle: const Text("Pick which items to include"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onManualSelected,
                  ),
                ],
              ),
            )
          ),
        ],
      ),
    );
  }
}

class SelectDataItemsSheetContent extends StatefulWidget {
  final SelectedData allData;
  final Function(SelectedData) onConfirm;
  final VoidCallback onBack;

  const SelectDataItemsSheetContent({super.key, required this.allData, required this.onConfirm, required this.onBack});

  @override
  State<SelectDataItemsSheetContent> createState() => _SelectDataItemsSheetContentState();
}

class _SelectDataItemsSheetContentState extends State<SelectDataItemsSheetContent> {
  late final List<Bike> selectedBikes;
  late final List<Component> selectedComponents;
  late final List<Setup> selectedSetups;
  late final List<Person> selectedPersons;
  late final List<Rating> selectedRatings;
  late final List<TaskRule> selectedTaskRules;
  late final List<TaskEntry> selectedTaskEntries;

  @override
  void initState() {
    super.initState();

    selectedBikes = widget.allData.bikes.values.toList();
    selectedComponents = widget.allData.components.values.toList();
    selectedSetups = widget.allData.setups.values.toList();
    selectedPersons = widget.allData.persons.values.toList();
    selectedRatings = widget.allData.ratings.values.toList();
    selectedTaskRules = widget.allData.taskRules.values.toList();
    selectedTaskEntries = widget.allData.taskEntries.values.toList();
  }

  Widget _bikeWidget(Bike bike) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Bike.iconData),
        title: Text(
          bike.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: bike.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        //TODO: Add Person subtitle
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedBikes.contains(bike),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedBikes.add(bike);
            } else {
              selectedBikes.remove(bike);
            }
          });
        },
      ),
    );
  }

  Widget _componentWidget(Component component) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: Icon(component.componentType.getIconData()),
        title: Text(
          component.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: component.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(component.bike != null 
                ? Bike.iconData 
                : Icons.shelves, 
              size: 13, 
              color: component.bike == null || widget.allData.bikes.containsKey(component.bike) 
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                component.bike == null 
                    ? "Not installed" 
                    : widget.allData.bikes[component.bike]?.name ?? "BIKE NOT FOUND",
                style: TextStyle(
                  color: component.bike == null || widget.allData.bikes.containsKey(component.bike) 
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedComponents.contains(component),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedComponents.add(component);
            } else {
              selectedComponents.remove(component);
            }
          });
        },
      ),
    );
  }

  Widget _setupWidget(Setup setup) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Setup.iconData),
        title: Text(
          setup.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: setup.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(Bike.iconData, 
              size: 13, 
              color: widget.allData.bikes.containsKey(setup.bike)
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                widget.allData.bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
                style: TextStyle(
                  color: widget.allData.bikes.containsKey(setup.bike) 
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedSetups.contains(setup),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedSetups.add(setup);
            } else {
              selectedSetups.remove(setup);
            }
          });
        },
      ),
    );
  }

  Widget _personWidget(Person person) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Person.iconData),
        title: Text(
          person.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: person.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedPersons.contains(person),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedPersons.add(person);
            } else {
              selectedPersons.remove(person);
            }
          });
        },
      ),
    );
  }

  Widget _ratingWidget(Rating rating) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Rating.iconData),
        title: Text(
          rating.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: rating.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        //TODO: Add subtitle with filter
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedRatings.contains(rating),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedRatings.add(rating);
            } else {
              selectedRatings.remove(rating);
            }
          });
        },
      ),
    );
  }

  Widget _taskRuleWidget(TaskRule taskRule) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Icons.check_box_outline_blank),
        title: Text(
          taskRule.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: taskRule.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        //TODO: Add subtitle with filter
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedTaskRules.contains(taskRule),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedTaskRules.add(taskRule);
            } else {
              selectedTaskRules.remove(taskRule);
            }
          });
        },
      ),
    );
  }

  Widget _taskEntryWidget(TaskEntry taskEntry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Icons.check_box_outlined),
        title: Text(
          taskEntry.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: taskEntry.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        //TODO: Add subtitle with rule
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: selectedTaskEntries.contains(taskEntry),
        onChanged: (bool? checked) {
          setState(() {
            if (checked == true) {
              selectedTaskEntries.add(taskEntry);
            } else {
              selectedTaskEntries.remove(taskEntry);
            }
          });
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sheetBackButton(context, onPressed:  widget.onBack),
                sheetTitle(context, 'Select Data'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExpansionTile(
                    title: Text("Bikes (${selectedBikes.length} / ${widget.allData.bikes.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox.adaptive(
                      tristate: true,
                      value: selectedBikes.isEmpty && widget.allData.bikes.isNotEmpty
                          ? false 
                          : (selectedBikes.length == widget.allData.bikes.length ? true : null),
                      onChanged: (bool? newValue) {
                        switch (newValue) {
                          case false: setState(() => selectedBikes.clear());
                          case true: setState(() {selectedBikes.clear(); selectedBikes.addAll(widget.allData.bikes.values);});
                          case null: setState(() => selectedBikes.clear());
                        }
                      },
                    ),
                    children: widget.allData.bikes.values.map((b) => _bikeWidget(b)).toList(),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Components (${selectedComponents.length} / ${widget.allData.components.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox.adaptive(
                      tristate: true,
                      value: selectedComponents.isEmpty && widget.allData.components.isNotEmpty
                          ? false 
                          : (selectedComponents.length == widget.allData.components.length ? true : null),
                      onChanged: (bool? newValue) {
                        switch (newValue) {
                          case false: setState(() => selectedComponents.clear());
                          case true: setState(() {selectedComponents.clear(); selectedComponents.addAll(widget.allData.components.values);});
                          case null: setState(() => selectedComponents.clear());
                        }
                      },
                    ),
                    children: widget.allData.components.values.map((c) => _componentWidget(c)).toList(),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Setups (${selectedSetups.length} / ${widget.allData.setups.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox.adaptive(
                      tristate: true,
                      value: selectedSetups.isEmpty && widget.allData.setups.isNotEmpty
                          ? false 
                          : (selectedSetups.length == widget.allData.setups.length ? true : null),
                      onChanged: (bool? newValue) {
                        switch (newValue) {
                          case false: setState(() => selectedSetups.clear());
                          case true: setState(() {selectedSetups.clear(); selectedSetups.addAll(widget.allData.setups.values);});
                          case null: setState(() => selectedSetups.clear());
                        }
                      },
                    ),
                    children: widget.allData.setups.values.toList().reversed.map((s) => _setupWidget(s)).toList(),
                  ),
                  if (appSettings.enablePerson || widget.allData.persons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text("Profiles (${selectedPersons.length} / ${widget.allData.persons.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                      controlAffinity: ListTileControlAffinity.leading,
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      trailing: Checkbox.adaptive(
                        tristate: true,
                        value: selectedPersons.isEmpty && widget.allData.persons.isNotEmpty
                            ? false 
                            : (selectedPersons.length == widget.allData.persons.length ? true : null),
                        onChanged: (bool? newValue) {
                          switch (newValue) {
                            case false: setState(() => selectedPersons.clear());
                            case true: setState(() {selectedPersons.clear(); selectedPersons.addAll(widget.allData.persons.values);});
                            case null: setState(() => selectedPersons.clear());
                          }
                        },
                      ),
                      children: widget.allData.persons.values.map((p) => _personWidget(p)).toList(),
                    ),
                  ],
                  if (appSettings.enableRating || widget.allData.ratings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text("Ratings (${selectedRatings.length} / ${widget.allData.ratings.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                      controlAffinity: ListTileControlAffinity.leading,
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      trailing: Checkbox.adaptive(
                        tristate: true,
                        value: selectedRatings.isEmpty && widget.allData.ratings.isNotEmpty
                            ? false 
                            : (selectedRatings.length == widget.allData.ratings.length ? true : null),
                        onChanged: (bool? newValue) {
                          switch (newValue) {
                            case false: setState(() => selectedRatings.clear());
                            case true: setState(() {selectedRatings.clear(); selectedRatings.addAll(widget.allData.ratings.values);});
                            case null: setState(() => selectedRatings.clear());
                          }
                        },
                      ),
                      children: widget.allData.ratings.values.map((r) => _ratingWidget(r)).toList(),
                    ),
                  ],
                  if (appSettings.enableTask || widget.allData.taskRules.isNotEmpty) ... [
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text("Tasks (${selectedTaskRules.length} / ${widget.allData.taskRules.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                      controlAffinity: ListTileControlAffinity.leading,
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      trailing: Checkbox.adaptive(
                        tristate: true,
                        value: selectedTaskRules.isEmpty && widget.allData.taskRules.isNotEmpty
                            ? false 
                            : (selectedTaskRules.length == widget.allData.taskRules.length ? true : null),
                        onChanged: (bool? newValue) {
                          switch (newValue) {
                            case false: setState(() => selectedTaskRules.clear());
                            case true: setState(() {selectedTaskRules.clear(); selectedTaskRules.addAll(widget.allData.taskRules.values);});
                            case null: setState(() => selectedTaskRules.clear());
                          }
                        },
                      ),
                      children: widget.allData.taskRules.values.map((tr) => _taskRuleWidget(tr)).toList(),
                    ),
                  ],
                  if (appSettings.enableTask || widget.allData.taskEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text("Task Entries (${selectedTaskEntries.length} / ${widget.allData.taskEntries.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                      controlAffinity: ListTileControlAffinity.leading,
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      trailing: Checkbox.adaptive(
                        tristate: true,
                        value: selectedTaskEntries.isEmpty && widget.allData.taskEntries.isNotEmpty
                            ? false 
                            : (selectedTaskEntries.length == widget.allData.taskEntries.length ? true : null),
                        onChanged: (bool? newValue) {
                          switch (newValue) {
                            case false: setState(() => selectedTaskEntries.clear());
                            case true: setState(() {selectedTaskEntries.clear(); selectedTaskEntries.addAll(widget.allData.taskEntries.values);});
                            case null: setState(() => selectedTaskEntries.clear());
                          }
                        },
                      ),
                      children: widget.allData.taskEntries.values.map((te) => _taskEntryWidget(te)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final selectedData = SelectedData(
                  persons: <String, Person>{for (var item in selectedPersons) item.id: item},
                  bikes: <String, Bike>{for (var item in selectedBikes) item.id: item},
                  components: <String, Component>{for (var item in selectedComponents) item.id: item},
                  setups: <String, Setup>{for (var item in selectedSetups) item.id: item},
                  ratings: <String, Rating>{for (var item in selectedRatings) item.id: item},
                  taskRules: <String, TaskRule>{for (var item in selectedTaskRules) item.id: item},
                  taskEntries: <String, TaskEntry>{for (var item in selectedTaskEntries) item.id: item}
                );
                widget.onConfirm(selectedData);
              },
              child: const Text("Confirm Selection"),
            ),
          ),
        ],
      ),
    );
  }
}
