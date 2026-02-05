import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/filtered_data.dart';
import 'sheet.dart';

Future<void> showFilterSheet({required BuildContext context, required bool enableSetupTagFilter}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      final filteredData = context.watch<FilteredData>();

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
                  sheetTitle(context, 'Filter'),
                  sheetCloseButton(context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Bike", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    filteredData.bikes.isEmpty 
                        ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text("No bikes yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
                        )
                        : Wrap(
                            spacing: 6,
                            children: filteredData.bikes.values.map((bike) => FilterChip(
                              avatar: const Icon(Bike.iconData),
                              label: Text(bike.name),
                              selected: bike.id == filteredData.selectedBike,
                              showCheckmark: false,
                              onSelected: (bool newValue) {
                                switch (newValue) {
                                  case true: filteredData.onBikeTap(bike.id);
                                  case false: filteredData.onBikeTap(bike.id);
                                }
                              },
                              onDeleted: filteredData.selectedBike != null && filteredData.selectedBike == bike.id 
                                  ? () => filteredData.onBikeTap(bike.id)
                                  : null,
                            )).toList(),
                          ),
                    if (enableSetupTagFilter) ...[
                      Text("Setup Tags", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      filteredData.setupTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("No tags yet. Add/Edit a Setup to add a tag.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              children: filteredData.setupTags.map((tag) {
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: filteredData.selectedSetupTags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: (bool newValue) {
                                    switch (newValue) {
                                      case true: filteredData.selectSetupTag(tag);
                                      case false: filteredData.deselectSetupTag(tag);
                                    }
                                  },
                                  onDeleted: filteredData.selectedSetupTags.contains(tag)
                                      ? () => filteredData.deselectSetupTag(tag)
                                      : null,
                                );
                              }).toList(),
                            ),
                    ]
                  ],
                ),
              )
            ),
          ],
        ),
      );
    },
  );
}
