import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';

Future<void> showFilterSheet({
  required BuildContext context, 
  required bool enableSetupTagFilter, 
  bool enableTaskRuleTagFilter = false,
  required bool enableTaskPriorityFilter,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      final appRepository = context.watch<AppRepository>();

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
                    const SheetSectionTitle(title: "Bike"),
                    appRepository.bikes.isEmpty 
                        ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text("No bikes yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
                        )
                        : Wrap(
                            spacing: 6,
                            children: appRepository.bikes.values.map((bike) => FilterChip(
                              avatar: const Icon(Bike.iconData),
                              label: Text(bike.name),
                              selected: bike.id == appRepository.selectedBike,
                              showCheckmark: false,
                              onSelected: (bool newValue) {
                                switch (newValue) {
                                  case true: appRepository.onBikeTap(bike.id);
                                  case false: appRepository.onBikeTap(bike.id);
                                }
                              },
                              onDeleted: appRepository.selectedBike != null && appRepository.selectedBike == bike.id 
                                  ? () => appRepository.onBikeTap(bike.id)
                                  : null,
                            )).toList(),
                          ),
                    if (enableSetupTagFilter) ...[
                      const SheetSectionTitle(title: "Setup Tags"),
                      appRepository.setupTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("No tags yet. Add/Edit a Setup to add a tag.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              children: appRepository.setupTags.map((tag) {
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: appRepository.selectedSetupTags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: (bool newValue) {
                                    switch (newValue) {
                                      case true: appRepository.selectSetupTag(tag);
                                      case false: appRepository.deselectSetupTag(tag);
                                    }
                                  },
                                  onDeleted: appRepository.selectedSetupTags.contains(tag)
                                      ? () => appRepository.deselectSetupTag(tag)
                                      : null,
                                );
                              }).toList(),
                            ),
                    ],
                    if (enableTaskPriorityFilter) ...[
                      const SheetSectionTitle(title: "Task Priority"),
                      Wrap(
                        spacing: 6,
                        children: TaskPriority.values.map((tp) {
                          return FilterChip(
                            label: Text(tp.label),
                            selected: appRepository.selectedTaskPriorities.contains(tp),
                            showCheckmark: false,
                            onSelected: (bool newValue) {
                              switch (newValue) {
                                case true: appRepository.selectTaskPriority(tp);
                                case false: appRepository.deselectTaskPriority(tp);
                              }
                            },
                            onDeleted: appRepository.selectedTaskPriorities.contains(tp)
                                ? () => appRepository.deselectTaskPriority(tp)
                                : null
                          );
                        }).toList(),
                      )
                    ],
                    if (enableTaskRuleTagFilter) ...[
                      const SheetSectionTitle(title: "Task Tags"),
                      appRepository.taskRuleTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("No tags yet. Add/Edit a Task Rule to add a tag.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                              ),
                            )
                          : Wrap(
                              spacing: 6,
                              children: appRepository.taskRuleTags.map((tag) {
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: appRepository.selectedTaskRuleTags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: (bool newValue) {
                                    switch (newValue) {
                                      case true: appRepository.selectTaskRuleTag(tag);
                                      case false: appRepository.deselectTaskRuleTag(tag);
                                    }
                                  },
                                  onDeleted: appRepository.selectedTaskRuleTags.contains(tag)
                                      ? () => appRepository.deselectTaskRuleTag(tag)
                                      : null,
                                );
                              }).toList(),
                            ),
                    ],
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
