import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import 'sheet.dart';

class SelectColumn {
  final String id;
  final String label;
  bool selected = false;
  SelectColumn({required this.id, required this.label, this.selected = false});
}

Future<Map<String, Map<String, bool>>?> showColumnFilterSheet({
  required BuildContext context,
  required Map<String, Map<String, bool>> showColumns,
  required Iterable<Adjustment> adjustments,
  required Iterable<Adjustment> ratingAdjustments,
}) async {
  final Map<String, Map<String, bool>> showColumnsCopy = showColumns.map((key, innerMap) {
    return MapEntry(key, Map<String, bool>.from(innerMap));
  });

  return showModalBottomSheet<Map<String, Map<String, bool>>?>(
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
                      sheetTitle(context, 'Column Select'),
                      sheetCloseButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...showColumnsCopy.entries.map((sectionShowColumnsEntry) {
                          if (sectionShowColumnsEntry.value.entries.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sectionShowColumnsEntry.key, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: sectionShowColumnsEntry.value.entries.map((showColumnEntry) {
                                    return FilterChip(
                                      label: Text(
                                        switch (sectionShowColumnsEntry.key) {
                                          "Adjustments" => adjustments.firstWhereOrNull((a) => a.id == showColumnEntry.key)?.name ?? "-",
                                          "Ratings" => ratingAdjustments.firstWhereOrNull((a) => a.id == showColumnEntry.key)?.name ?? "-",
                                          _ => showColumnEntry.key,
                                        },
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      selected: showColumnEntry.value,
                                      onSelected: (bool newValue) {
                                        setSheetState(() {
                                          showColumnsCopy[sectionShowColumnsEntry.key]?[showColumnEntry.key] = newValue;
                                        });
                                      },
                                      onDeleted: showColumnEntry.value
                                          ? () => setSheetState(() {
                                              showColumnsCopy[sectionShowColumnsEntry.key]?[showColumnEntry.key] = false;
                                            })
                                          : null,
                                      showCheckmark: false,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, showColumnsCopy),
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
