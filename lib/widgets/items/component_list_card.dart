import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../../models/component/installation.dart';
import '../../models/task/task_rule.dart';
import '../../pages/details/component_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/automation_ids.dart';
import '../../utils/component_actions.dart';
import '../component_ancestors_column.dart';
import '../component_stats_bar.dart';
import '../lists/adjustment_compact_display/adjustment_compact_display_list.dart';
import '../notes_text.dart';
import 'tile_meta_row.dart';

class ComponentListCard extends StatelessWidget{
  final Component component;
  final int? index;
  final double? elevation;
  final Color? color;
  final bool showCurrentAdjustmentValues;

  const ComponentListCard({
    super.key,
    required this.component,
    this.index,
    this.elevation,
    this.color,
    this.showCurrentAdjustmentValues = true,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final bikes = appRepository.bikes;
    final stats = appRepository.componentStatsOf(component.id);

    TaskStatusType? indicatorStatus;
    if (appSettings.enableTask && appSettings.enableGarageTaskIndicator) {
      indicatorStatus = appRepository.componentTaskIndicatorStatus(component.id);
    }
    final indicatorBorderColor = color ?? Theme.of(context).colorScheme.surface;
    final notes = component.notes;
    final hasNotes = notes != null && notes.isNotEmpty;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final notesColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Card(
      key: ValueKey(component.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      color: color,
      child: InkWell(
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => ComponentDetailsPage(componentId: component.id),
            ),
          );
        },
        onDoubleTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => ComponentDetailsPage(componentId: component.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(component.componentType.getIconData()),
                  if (indicatorStatus != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: indicatorStatus.getStatusColor(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: indicatorBorderColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              titleAlignment: ListTileTitleAlignment.titleHeight,
              minTileHeight: 0,
              minVerticalPadding: 0,
              contentPadding: EdgeInsets.fromLTRB(16, 8, 16, hasNotes ? 6 : 8),
              title: Text(
                component.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  // The counter sits beside the whole installation stack so every
                  // level is cut off at the same edge and no line is added.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Flexible(
                        child: ComponentAncestorsColumn(
                          ancestors: appRepository.componentHierarchy.currentAncestors(component.id),
                          bikes: bikes,
                          iconSize: 12,
                          spacing: 2,
                          textStyle: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                      ),
                      if (appSettings.enableAttachments && component.attachments.isNotEmpty)
                        TileMetaRow(icon: Icons.attach_file, text: '${component.attachments.length}'),
                    ],
                  ),
                  if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement)
                    ComponentStatsBar(stats: stats),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index != null)
                    ReorderableDragStartListener(
                      index: index!,
                      child: const Icon(Icons.drag_handle),
                    ),
                  Semantics(
                    container: true,
                    identifier: AutomationIds.componentActions,
                    child: PopupMenuButton<_ComponentOptions>(
                      onSelected: (value) {
                        switch (value) {
                          case _ComponentOptions.edit:
                            unawaited(ComponentActions.editComponent(context, component: component));
                          case _ComponentOptions.duplicate:
                            unawaited(ComponentActions.duplicateComponent(context, component: component));
                          case _ComponentOptions.replace:
                            unawaited(ComponentActions.replaceComponent(context, component: component));
                          case _ComponentOptions.remove:
                            unawaited(ComponentActions.removeComponent(context, component: component));
                        }
                      },
                      itemBuilder: (BuildContext context) => _ComponentOptions.values.where((option) {
                        if (option == _ComponentOptions.replace) {
                          final installation = appRepository.componentHierarchy.currentInstallation(component.id);
                          return (installation is BikeInstallation || installation is ComponentInstallation) &&
                              appSettings.enableInstallationTimeline;
                        }

                        return true;
                      }).map((option) {
                        return PopupMenuItem<_ComponentOptions>(
                          value: option,
                          child: Row(
                            spacing: 10,
                            children: [
                              Icon(option.iconData, size: 20),
                              Semantics(
                                identifier: option == _ComponentOptions.duplicate ? AutomationIds.componentActionsDuplicate : null,
                                child: Text(option.label),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            if (hasNotes)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.notes, size: 12, color: notesColor),
                    ),
                    Expanded(child: NotesText(notes, fontSize: 12, color: notesColor)),
                  ],
                ),
              ),
            if (showCurrentAdjustmentValues)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AdjustmentCompactDisplayList(
                  components: [component],
                  adjustmentValues: appRepository.currentAdjustmentValues,
                  showRowIcons: false,
                  missingValuesPlaceholder: true,
                  displayBikeAdjustmentValues: true,
                  displayPersonAdjustmentValues: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _ComponentOptions {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  replace("Replace", Icons.swap_horiz),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _ComponentOptions(this.label, this.iconData);
}
