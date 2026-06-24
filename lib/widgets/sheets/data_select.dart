import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../models/app_settings.dart";
import "../../models/bike.dart";
import "../../models/component.dart";
import "../../models/person.dart";
import "../../models/rating.dart";
import "../../models/rating_entry.dart";
import "../../models/selected_data.dart";
import "../../models/setup.dart";
import "../../models/task/task_entry.dart";
import "../../models/task/task_rule.dart";
import "../../repositories/app_repository.dart";
import "../items/data_select_bike.dart";
import "../items/data_select_component.dart";
import "../items/data_select_person.dart";
import "../items/data_select_rating.dart";
import "../items/data_select_rating_entry.dart";
import "../items/data_select_setup.dart";
import "../items/data_select_task_entry.dart";
import "../items/data_select_task_rule.dart";
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
                  ratingEntries: widget.allData.ratingEntries,
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
                  ratingEntries: widget.allData.ratingEntries,
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

  const SelectDataMethodSheetContent({
    super.key,
    required this.onAllSelected,
    required this.onManualSelected,
    this.onBack,
  });

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

  const SelectDataItemsSheetContent({
    super.key,
    required this.allData,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  State<SelectDataItemsSheetContent> createState() => _SelectDataItemsSheetContentState();
}

class _SelectDataItemsSheetContentState extends State<SelectDataItemsSheetContent> {
  late final List<Bike> selectedBikes;
  late final List<Component> selectedComponents;
  late final List<Setup> selectedSetups;
  late final List<Person> selectedPersons;
  late final List<Rating> selectedRatings;
  late final List<RatingEntry> selectedRatingEntries;
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
    selectedRatingEntries = widget.allData.ratingEntries.values.toList();
    selectedTaskRules = widget.allData.taskRules.values.toList();
    selectedTaskEntries = widget.allData.taskEntries.values.toList();
  }


  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    
    final allCount = widget.allData.bikes.length +
        widget.allData.components.length +
        widget.allData.setups.length +
        widget.allData.persons.length +
        widget.allData.ratings.length +
        widget.allData.ratingEntries.length +
        widget.allData.taskRules.length +
        widget.allData.taskEntries.length;
    final selectedCount = selectedBikes.length +
        selectedComponents.length +
        selectedSetups.length +
        selectedPersons.length +
        selectedRatings.length +
        selectedRatingEntries.length +
        selectedTaskRules.length +
        selectedTaskEntries.length;

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
                sheetBackButton(context, onPressed: widget.onBack),
                sheetTitle(context, 'Select Data Items'),
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
                    trailing: Checkbox(
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
                    children: widget.allData.bikes.values.map((b) => DataSelectBike(
                      bike: b,
                      persons: widget.allData.persons,
                      isSelected: selectedBikes.contains(b),
                      onChanged: (checked) {
                        setState(() { 
                          if (checked == true) {
                            selectedBikes.add(b);
                          } else {
                            selectedBikes.remove(b);
                          } 
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Components (${selectedComponents.length} / ${widget.allData.components.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox(
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
                    children: widget.allData.components.values.map((c) => DataSelectComponent(
                      component: c,
                      bikes: widget.allData.bikes,
                      isSelected: selectedComponents.contains(c),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedComponents.add(c);
                          } else {
                            selectedComponents.remove(c);
                          }
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("Setups (${selectedSetups.length} / ${widget.allData.setups.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                    controlAffinity: ListTileControlAffinity.leading,
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    trailing: Checkbox(
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
                    children: widget.allData.setups.values.toList().reversed.map((s) => DataSelectSetup(
                      setup: s,
                      bikes: widget.allData.bikes,
                      isSelected: selectedSetups.contains(s),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedSetups.add(s);
                          } else {
                            selectedSetups.remove(s);
                          }
                        });
                      },
                    )).toList(),
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
                      trailing: Checkbox(
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
                      children: widget.allData.persons.values.map((p) => DataSelectPerson(
                        item: p,
                        isSelected: selectedPersons.contains(p),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedPersons.add(p);
                            } else {
                              selectedPersons.remove(p);
                            }
                          });
                        },
                      )).toList(),
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
                      trailing: Checkbox(
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
                      children: widget.allData.ratings.values.map((r) => DataSelectRating(
                        item: r,
                        bikes: widget.allData.bikes,
                        persons: widget.allData.persons,
                        components: widget.allData.components,
                        isSelected: selectedRatings.contains(r),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedRatings.add(r);
                            } else {
                              selectedRatings.remove(r);
                            }
                          });
                        },
                      )).toList(),
                    ),
                  ],
                  if (appSettings.enableRating || widget.allData.ratingEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text("Rating Entries (${selectedRatingEntries.length} / ${widget.allData.ratingEntries.length})", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      tilePadding: const EdgeInsets.only(left: 16, right: 16+12),
                      controlAffinity: ListTileControlAffinity.leading,
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      trailing: Checkbox(
                        tristate: true,
                        value: selectedRatingEntries.isEmpty && widget.allData.ratingEntries.isNotEmpty
                            ? false
                            : (selectedRatingEntries.length == widget.allData.ratingEntries.length ? true : null),
                        onChanged: (bool? newValue) {
                          switch (newValue) {
                            case false: setState(() => selectedRatingEntries.clear());
                            case true: setState(() {selectedRatingEntries.clear(); selectedRatingEntries.addAll(widget.allData.ratingEntries.values);});
                            case null: setState(() => selectedRatingEntries.clear());
                          }
                        },
                      ),
                      children: widget.allData.ratingEntries.values.map((re) => DataSelectRatingEntry(
                        item: re,
                        bikes: widget.allData.bikes,
                        isSelected: selectedRatingEntries.contains(re),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedRatingEntries.add(re);
                            } else {
                              selectedRatingEntries.remove(re);
                            } 
                          });
                        },
                      )).toList(),
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
                      trailing: Checkbox(
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
                      children: widget.allData.taskRules.values.map((tr) => DataSelectTaskRule(
                        item: tr,
                        bikes: widget.allData.bikes,
                        components: widget.allData.components,
                        isSelected: selectedTaskRules.contains(tr),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedTaskRules.add(tr);
                            } else {
                              selectedTaskRules.remove(tr);
                            }
                          });
                        },
                      )).toList(),
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
                      trailing: Checkbox(
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
                      children: widget.allData.taskEntries.values.map((te) => DataSelectTaskEntry(
                        item: te,
                        taskRules: widget.allData.taskRules,
                        isSelected: selectedTaskEntries.contains(te),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedTaskEntries.add(te);
                            } else {
                              selectedTaskEntries.remove(te);
                            }
                          });
                        },
                      )).toList(),
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
                  persons: Map.fromEntries(selectedPersons.map((p) => MapEntry(p.id, p))),
                  bikes: Map.fromEntries(selectedBikes.map((b) => MapEntry(b.id, b))),
                  components: Map.fromEntries(selectedComponents.map((c) => MapEntry(c.id, c))),
                  setups: Map.fromEntries(selectedSetups.map((s) => MapEntry(s.id, s))),
                  ratings: Map.fromEntries(selectedRatings.map((r) => MapEntry(r.id, r))),
                  ratingEntries: Map.fromEntries(selectedRatingEntries.map((re) => MapEntry(re.id, re))),
                  taskRules: Map.fromEntries(selectedTaskRules.map((tr) => MapEntry(tr.id, tr))),
                  taskEntries: Map.fromEntries(selectedTaskEntries.map((te) => MapEntry(te.id, te))),
                );
                widget.onConfirm(selectedData);
              },
              child: Text("Confirm Selection ($selectedCount / $allCount)"),
            ),
          ),
        ],
      ),
    );
  }
}
