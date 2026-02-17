import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import 'sheet.dart';

Future<void> showSetupListValuesFilterSheet({
  required BuildContext context, 
  required bool onlyChanges,
  required bool bikeValues,
  required bool personValues,
  required bool ratingValues,
  required ValueChanged<bool> onOnlyChangesChanged,
  required ValueChanged<bool> onBikeValuesChanged,
  required ValueChanged<bool> onPersonValuesChanged,
  required ValueChanged<bool> onRatingValuesChanged,
}) async {
  return showModalBottomSheet<void>(
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
                                    selected: onlyChanges,
                                    onSelected: (bool selected) {
                                      setSheetState(() => onlyChanges = selected);
                                      onOnlyChangesChanged(selected);
                                    },
                                    tooltip: "Show only changed values",
                                    onDeleted: onlyChanges
                                        ? () {
                                            setSheetState(() => onlyChanges = false);
                                            onOnlyChangesChanged(false);
                                          }
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
                                      selected: bikeValues,
                                      onSelected: (bool selected) {
                                        setSheetState(() => bikeValues = selected);
                                        onBikeValuesChanged(selected);
                                      },
                                      tooltip: "Show bike/component related values",
                                      onDeleted: bikeValues
                                            ? () {
                                                setSheetState(() => bikeValues = false);
                                                onBikeValuesChanged(false);
                                              }
                                            : null
                                    ),
                                    if (context.read<AppSettings>().enablePerson)
                                      FilterChip(
                                        avatar: const Icon(Person.iconData, size: 20),
                                        showCheckmark: false,
                                        label: const Text("Person Values"),
                                        selected: personValues,
                                        onSelected: (bool selected) {
                                          setSheetState(() => personValues = selected);
                                          onPersonValuesChanged(selected);
                                        },
                                        tooltip: "Show person related values",
                                        onDeleted: personValues
                                            ? () {
                                                setSheetState(() => personValues = false);
                                                onPersonValuesChanged(false);
                                              }
                                            : null
                                      ),
                                    if (context.read<AppSettings>().enableRating)
                                      FilterChip(
                                        avatar: const Icon(Rating.iconData, size: 20),
                                        showCheckmark: false,
                                        label: const Text("Rating Values"),
                                        selected: ratingValues,
                                        onSelected: (bool selected) {
                                          setSheetState(() => ratingValues = selected);
                                          onRatingValuesChanged(selected);
                                        },
                                        tooltip: "Show rating related values",
                                        onDeleted: ratingValues
                                            ? () {
                                                setSheetState(() => ratingValues = false);
                                                onRatingValuesChanged(false);
                                              }
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
              ],
            ),
          );
        },
      );
    },
  );
}
