import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../models/component.dart';
import '../../models/bike.dart';
import '../../utils/component_actions.dart';
import '../lists/adjustment_compact_display_list.dart';
import '../../pages/component_overview_page.dart';
import '../../models/app_settings.dart';

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
    final bikes = appRepository.bikes;
    return Card(
      key: ValueKey(component.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      color: color,
      child: InkWell(
        onTap: () async {
          await Navigator.push<Component>(
            context,
            MaterialPageRoute(
              builder: (context) => ComponentOverviewPage(componentId: component.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(component.componentType.getIconData()),
              minTileHeight: 0,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              title: Text(
                component.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 2,
                        children: [
                          Icon(component.bike != null 
                              ? Bike.iconData 
                              : Icons.shelves, 
                            size: 13, 
                            color: component.bike == null || bikes.containsKey(component.bike) 
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.error,
                          ),
                          Flexible(
                            child: Text(
                              component.bike == null 
                                  ? "Not installed" 
                                  : bikes[component.bike]?.name ?? "BIKE NOT FOUND",
                              style: TextStyle(
                                color: component.bike == null || bikes.containsKey(component.bike) 
                                    ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                    : Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (component.notes != null && component.notes!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.notes,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            component.notes!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (appSettings.enableInstallationTimeline && appSettings.enableStrava)
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        _StatItem(
                          icon: Icons.speed,
                          label: '${NumberFormat.decimalPattern().format((component.totalDistance / 1000).round())} km',
                        ),
                        _StatItem(
                          icon: Icons.terrain,
                          label: '${NumberFormat.decimalPattern().format(component.totalElevationGain.round())} m',
                        ),
                        _StatItem(
                          icon: Icons.timer,
                          label: '${NumberFormat.decimalPattern().format(component.totalMovingTime.inHours)}h ${component.totalMovingTime.inMinutes.remainder(60)}m',
                        ),
                      ],
                    ),
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
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit': ComponentActions.editComponent(context, component: component);
                        case 'duplicate': ComponentActions.duplicateComponent(context, component: component);
                        case 'remove': ComponentActions.removeComponent(context, component: component);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 10),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 10),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showCurrentAdjustmentValues)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: AdjustmentCompactDisplayList(
                  components: [component],
                  adjustmentValues: appRepository.currentAdjustmentValues,
                  showComponentIcons: false,
                  missingValuesPlaceholder: true,
                  displayBikeAdjustmentValues: true,
                  displayPersonAdjustmentValues: false,
                  displayRatingAdjustmentValues: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(
          icon,
          size: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
