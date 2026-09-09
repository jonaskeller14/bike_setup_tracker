import 'package:flutter/material.dart';

import '../../utils/table_column.dart';
import '../text/sheet_section_title.dart';
import 'sheet_header.dart';

Future<void> showColumnFilterSheet({
  required BuildContext context,
  required List<TableColumn> columns,
  required String Function(TableColumn column) columnLabel,
  required VoidCallback onColumnStatusChanged,
}) async {
  final columnsCopy = columns.toList();
  return showModalBottomSheet<void>(
    useSafeArea: true,
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
                const SheetHeader(title: 'Column Select'),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...TableColumnSection.values.map((tcs) {
                          final sectionColumns = columnsCopy.where((c) => c.section == tcs);
                          if (sectionColumns.isEmpty) return const SizedBox.shrink();

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SheetSectionTitle(title: tcs.label),
                              Wrap(
                                spacing: 6,
                                children: sectionColumns.map((column) {
                                  return FilterChip(
                                    label: Text(columnLabel(column), overflow: TextOverflow.ellipsis),
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
