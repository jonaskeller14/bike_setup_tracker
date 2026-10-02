import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../utils/table_column.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';
import 'sheet_header.dart';

Future<void> showColumnFilterSheet({
  required BuildContext context,
  required List<TableColumn> columns,
  required String Function(TableColumn column) columnLabel,
  required VoidCallback onColumnStatusChanged,
  ColumnGroup? Function(TableColumn column)? columnGroup,
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
                SheetHeader(
                  title: 'Column Select',
                  actions: [
                    sheetActionButton(
                      context,
                      icon: Icons.deselect,
                      tooltip: 'Deselect all',
                      onPressed: columnsCopy.any((c) => c.active)
                          ? () {
                              setSheetState(() {
                                for (final column in columnsCopy) {
                                  column.active = false;
                                }
                              });
                              onColumnStatusChanged();
                            }
                          : null,
                    ),
                  ],
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
                          final sectionColumns = columnsCopy.where((c) => c.section == tcs);
                          if (sectionColumns.isEmpty) return const SizedBox.shrink();

                          // Grouped by title: the info rows are lists, which compare by identity.
                          final groupOf = {for (final c in sectionColumns) c: columnGroup?.call(c)};
                          final groups = groupBy(sectionColumns, (c) => groupOf[c]?.title);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SheetSectionTitle(title: tcs.label),
                              for (final MapEntry(key: title, value: groupColumns) in groups.entries) ...[
                                if (title != null) _ColumnGroupHeader(group: groupOf[groupColumns.first]!),
                                Wrap(
                                  spacing: 6,
                                  children: groupColumns.map((column) {
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

/// A sub-header inside a section of the column sheet, e.g. one slot lane.
/// [info] rows are shown as a table in a tooltip behind an info icon.
typedef ColumnGroup = ({String title, List<List<String>>? info});

class _ColumnGroupHeader extends StatelessWidget {
  final ColumnGroup group;

  const _ColumnGroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final info = group.info;
    return SheetGroupTitle(
      title: group.title,
      info: info == null || info.isEmpty
          ? null
          : Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              // The first column shrinks and wraps so the aligned columns stay visible.
              columnWidths: const {0: IntrinsicColumnWidth(flex: 1)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (final row in info)
                  TableRow(
                    children: [
                      for (final (index, cell) in row.indexed)
                        Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 0 : 8, top: 2, bottom: 2),
                          child: Text(cell),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
