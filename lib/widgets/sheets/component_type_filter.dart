import 'package:flutter/material.dart';

import '../../models/component.dart';
import '../text/sheet_section_title.dart';
import 'sheet_header.dart';

Future<void> showComponentTypeFilterSheet({
  required BuildContext context,
  required List<ComponentType> availableComponentTypes,
  required Set<ComponentType> hiddenComponentTypes,
  required VoidCallback onChanged,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final int totalCount = availableComponentTypes.length;
          final int selectedCount =
              availableComponentTypes.where((t) => !hiddenComponentTypes.contains(t)).length;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeader(title: 'Component Types ($selectedCount/$totalCount)'),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...ComponentTypeCategory.values.map((category) {
                          final typesInCategory =
                              ComponentType.values.where((t) => t.category == category).toList();
                          if (typesInCategory.isEmpty) return const SizedBox.shrink();

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SheetSectionTitle(title: category.label),
                              Wrap(
                                spacing: 6,
                                children: typesInCategory.map((type) {
                                  final bool isAvailable = availableComponentTypes.contains(type);
                                  final bool selected = isAvailable && !hiddenComponentTypes.contains(type);
                                  return FilterChip(
                                    avatar: selected ? null : Icon(type.getIconData(), size: 18),
                                    label: Text(type.label),
                                    selected: selected,
                                    onSelected: isAvailable
                                        ? (bool newValue) {
                                            setSheetState(() {
                                              if (newValue) {
                                                hiddenComponentTypes.remove(type);
                                              } else {
                                                hiddenComponentTypes.add(type);
                                              }
                                            });
                                            onChanged();
                                          }
                                        : null,
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
