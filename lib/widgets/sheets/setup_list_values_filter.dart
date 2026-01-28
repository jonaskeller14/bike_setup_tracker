import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import 'sheet.dart';

enum SetupListValuesFilterOptions {
  onlyChanges,
  bikeValues,
  personValues,
  ratingValues,
}

Future<Map<SetupListValuesFilterOptions, bool>?> showSetupListValuesFilterSheet({
  required BuildContext context, 
  required Map<SetupListValuesFilterOptions, bool> setupListValuesFilter
  }) async {
  return showModalBottomSheet<Map<SetupListValuesFilterOptions, bool>?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
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
                      sheetTitle(context, 'Values Filter'),
                      sheetCloseButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("General", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: [
                                  FilterChip(
                                    // avatar: const Icon(Icons.published_with_changes),
                                    label: const Text("Display Only Changes"),
                                    showCheckmark: false,
                                    selected: setupListValuesFilter[SetupListValuesFilterOptions.onlyChanges] ?? false,
                                    onSelected: (bool selected) {setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.onlyChanges] = selected);},
                                    tooltip: "Show only changed values",
                                    onDeleted: setupListValuesFilter[SetupListValuesFilterOptions.onlyChanges] ?? true
                                        ? () => setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.onlyChanges] = false)
                                        : null
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (context.read<AppSettings>().enablePerson || context.read<AppSettings>().enableRating) ...[  
                          Padding(
                            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("By Category", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    FilterChip(
                                      avatar: const Icon(Bike.iconData, size: 20),
                                      showCheckmark: false,
                                      label: const Text("Bike Values"),
                                      selected: setupListValuesFilter[SetupListValuesFilterOptions.bikeValues] ?? false,
                                      onSelected: (bool selected) {setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.bikeValues] = selected);},
                                      tooltip: "Show bike/component related values",
                                      onDeleted: setupListValuesFilter[SetupListValuesFilterOptions.bikeValues] ?? true
                                            ? () => setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.bikeValues] = false)
                                            : null
                                    ),
                                    if (context.read<AppSettings>().enablePerson)
                                      FilterChip(
                                        avatar: const Icon(Person.iconData, size: 20),
                                        showCheckmark: false,
                                        label: const Text("Person Values"),
                                        selected: setupListValuesFilter[SetupListValuesFilterOptions.personValues] ?? false,
                                        onSelected: (bool selected) {setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.personValues] = selected);},
                                        tooltip: "Show person related values",
                                        onDeleted: setupListValuesFilter[SetupListValuesFilterOptions.personValues] ?? true
                                            ? () => setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.personValues] = false)
                                            : null
                                      ),
                                    if (context.read<AppSettings>().enableRating)
                                      FilterChip(
                                        avatar: const Icon(Rating.iconData, size: 20),
                                        showCheckmark: false,
                                        label: const Text("Rating Values"),
                                        selected: setupListValuesFilter[SetupListValuesFilterOptions.ratingValues] ?? false,
                                        onSelected: (bool selected) {setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.ratingValues] = selected);},
                                        tooltip: "Show rating related values",
                                        onDeleted: setupListValuesFilter[SetupListValuesFilterOptions.ratingValues] ?? true
                                            ? () => setSheetState(() => setupListValuesFilter[SetupListValuesFilterOptions.ratingValues] = false)
                                            : null
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, setupListValuesFilter);
                    },
                    child: const Text("Confirm Selection"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
