import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import 'sheet.dart';

Future<void> showSetupListDisplayFilterSheet({required BuildContext context}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) => SetupListDisplayFilterSheetContent(),
  );
}

class SetupListDisplayFilterSheetContent extends StatelessWidget {
  const SetupListDisplayFilterSheetContent({super.key});

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
                sheetTitle(context, 'Display Options'),
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
                        Text("Visibility", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            FilterChip(
                              label: const Text("Setups"),
                              showCheckmark: false,
                              selected: appSettings.displayShowSetups,
                              onSelected: (bool selected) => appSettings.displayShowSetups = selected,
                              onDeleted: appSettings.displayShowSetups
                                  ? () => appSettings.displayShowSetups = false
                                  : null
                            ),
                            if (appSettings.enableStrava)
                              FilterChip(
                                label: const Text("Strava Activities"),
                                showCheckmark: false,
                                selected: appSettings.displayShowActivities,
                                onSelected: (bool selected) => appSettings.displayShowActivities = selected,
                                onDeleted: appSettings.displayShowActivities
                                    ? () => appSettings.displayShowActivities = false
                                    : null
                              ),
                            if (appSettings.enableTask)
                              FilterChip(
                                label: const Text("Tasks"),
                                showCheckmark: false,
                                selected: appSettings.displayShowTasks,
                                onSelected: (bool selected) => appSettings.displayShowTasks = selected,
                                onDeleted: appSettings.displayShowTasks
                                    ? () => appSettings.displayShowTasks = false
                                    : null
                              ),
                            if (appSettings.enableInstallationTimeline)
                              FilterChip(
                                label: const Text("Installations"),
                                showCheckmark: false,
                                selected: appSettings.displayShowInstallations,
                                onSelected: (bool selected) => appSettings.displayShowInstallations = selected,
                                onDeleted: appSettings.displayShowInstallations
                                    ? () => appSettings.displayShowInstallations = false
                                    : null
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              selected: appSettings.setupListOnlyChanges,
                              onSelected: (bool selected) => appSettings.setupListOnlyChanges = selected,
                              tooltip: "Show only changed values",
                              onDeleted: appSettings.setupListOnlyChanges
                                  ? () => appSettings.setupListOnlyChanges = false
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
                                selected: appSettings.setupListBikeAdjustmentValues,
                                onSelected: (bool selected) => appSettings.setupListBikeAdjustmentValues = selected,
                                tooltip: "Show bike/component related values",
                                onDeleted: appSettings.setupListBikeAdjustmentValues
                                      ? () => appSettings.setupListBikeAdjustmentValues = false
                                      : null
                              ),
                              if (context.read<AppSettings>().enablePerson)
                                FilterChip(
                                  avatar: const Icon(Person.iconData, size: 20),
                                  showCheckmark: false,
                                  label: const Text("Person Values"),
                                  selected: appSettings.setupListPersonAdjustmentValues,
                                  onSelected: (bool selected) => appSettings.setupListPersonAdjustmentValues = selected,
                                  tooltip: "Show person related values",
                                  onDeleted: appSettings.setupListPersonAdjustmentValues
                                      ? () => appSettings.setupListPersonAdjustmentValues = false
                                      : null
                                ),
                              if (context.read<AppSettings>().enableRating)
                                FilterChip(
                                  avatar: const Icon(Rating.iconData, size: 20),
                                  showCheckmark: false,
                                  label: const Text("Rating Values"),
                                  selected: appSettings.setupListRatingAdjustmentValues,
                                  onSelected: (bool selected) => appSettings.setupListRatingAdjustmentValues = selected,
                                  tooltip: "Show rating related values",
                                  onDeleted: appSettings.setupListRatingAdjustmentValues
                                      ? () => appSettings.setupListRatingAdjustmentValues = false
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
  }
}
