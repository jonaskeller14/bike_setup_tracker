import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../utils/table_column.dart';
import 'sheet.dart';

class SelectColumn {
  final String id;
  final String label;
  bool selected = false;
  SelectColumn({required this.id, required this.label, this.selected = false});
}

Future<void> showColumnFilterSheet({
  required BuildContext context,
  required List<TableColumn> sortedColumns,
  required Iterable<Adjustment> componentAdjustments,
  required Iterable<Adjustment> personAdjustments,
  required Iterable<Adjustment> ratingAdjustments,
  required VoidCallback onColumnStatusChanged,
}) async {
  final sortedColumnsCopy = sortedColumns.toList();
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
                      sheetTitle(context, 'Column Select'),
                      sheetCloseButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...TableColumnSection.values.map((tcs) {
                          final columns = sortedColumnsCopy.where((c) => c.section == tcs);
                          if (columns.isEmpty) return const SizedBox.shrink();

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                tcs.label, 
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: columns.map((column) {
                                  return FilterChip(
                                    label: Text(
                                      switch (column.section) {
                                        TableColumnSection.componentAdjustments => componentAdjustments.firstWhereOrNull((a) => a.id == column.label)?.name ?? "-",
                                        TableColumnSection.ratingMetrics => ratingAdjustments.firstWhereOrNull((a) => a.id == column.label)?.name ?? "-",
                                        TableColumnSection.personAttributes => personAdjustments.firstWhereOrNull((a) => a.id == column.label)?.name ?? "-",
                                        _ => column.label,
                                      },
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    selected: column.active,
                                    onSelected: (bool newValue) {
                                      setSheetState(() => column.active = newValue);
                                      onColumnStatusChanged();
                                    },
                                    onDeleted: column.active
                                        ? () {
                                            setSheetState(() => column.active = false);
                                            onColumnStatusChanged();
                                          }
                                        : null,
                                    showCheckmark: false,
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
