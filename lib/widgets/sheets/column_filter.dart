import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../utils/table_column.dart';
import '../text/sheet_section_title.dart';
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

                          final groups = groupBy(sectionColumns, (c) => columnGroup?.call(c));
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SheetSectionTitle(title: tcs.label),
                              for (final MapEntry(key: group, value: groupColumns) in groups.entries) ...[
                                if (group != null) _ColumnGroupHeader(group: group),
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
typedef ColumnGroup = ({String title, String? subtitle});

class _ColumnGroupHeader extends StatelessWidget {
  final ColumnGroup group;

  const _ColumnGroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.title, style: textTheme.labelLarge, overflow: TextOverflow.ellipsis),
          if (group.subtitle case final subtitle?)
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
