import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/component_stats.dart';
import '../../models/person.dart';
import '../../models/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';
import '../../widgets/component_stats_card.dart';
import '../../widgets/items/component_list_card.dart';
import '../../widgets/open_tasks_tile.dart';

class BikeDetailsPage extends StatelessWidget {
  final String bikeId;

  const BikeDetailsPage({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();

    final bike = appRepository.bikes[bikeId];
    if (bike == null) return const SizedBox.shrink();

    final person = appRepository.persons[bike.person];
    final stravaGear = appRepository.stravaGears[bike.stravaGear];
    final components = appRepository.components.values.where((c) => c.bike == bike.id);
    final stats = appRepository.bikeStats[bikeId] ?? ComponentStats.zero();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Bike.iconData),
            Expanded(
              child: Text(bike.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => BikeActions.editBike(context, bike: bike),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appSettings.enableStrava && appSettings.enableInstallationTimeline) ...[
                ComponentStatsCard(componentStats: stats),
                const Divider(height: 1),
              ],

              if (appSettings.enablePerson)
                ListTile(
                  leading: bike.person != null
                      ? const Icon(Person.iconData)
                      : const Icon(Icons.person_off),
                  title: Text(
                    person?.name ?? (bike.person == null ? "No bike owner person specified." : "PERSON NOT FOUND"),
                    style: TextStyle(
                      color: bike.person == null || person != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),
              
              if (appSettings.enableStrava)
                ListTile(
                  leading: Badge(
                    label: const Icon(SimpleIcons.strava, size: 11),
                    backgroundColor: Colors.transparent,
                    child: bike.stravaGear != null
                        ? Icon(Icons.link, color: appRepository.stravaGears.containsKey(bike.stravaGear) ? null : Theme.of(context).colorScheme.error)
                        : const Icon(Icons.link_off),
                  ),                
                  title: Text(
                    stravaGear?.name ?? (bike.stravaGear == null ? "No Strava Gear linked to this bike." : "STRAVA GEAR NOT FOUND"),
                    style: TextStyle(
                      color: bike.stravaGear == null || stravaGear != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),

              if (bike.notes != null)
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.top,
                  title: SelectableText(bike.notes!),
                  dense: true,
                ),

              if (appSettings.enableStrava || appSettings.enablePerson || bike.notes != null)
                const Divider(height: 1),

              if (appSettings.enableTask) ...[
                () {
                  final openTasks = appRepository.taskRules.values.where((rule) {
                    if (rule.bikeId == bikeId) return true;
                    if (rule.componentId != null) {
                      final component = appRepository.components[rule.componentId];
                      return component?.bike == bikeId;
                    }
                    return false;
                  }).map((rule) => TaskRuleWithStatus(rule: rule, status: appRepository.getTaskRuleStatus(rule)))
                  .where((t) => t.status.type != TaskStatusType.completed).toList();

                  openTasks.sort((a, b) {
                    if (a.status.type != b.status.type) {
                      return b.status.type.index.compareTo(a.status.type.index);
                    }
                    return b.status.progress.compareTo(a.status.progress);
                  });

                  return OpenTasksTile(openTasks: openTasks, repository: appRepository);
                }(),
                const Divider(height: 1),
              ],

              ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: const Icon(Component.iconData),
                title: Text(
                  "Components (${components.length})",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: components.isNotEmpty ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                enabled: components.isNotEmpty,
                children: components.map((component) => ComponentListCard(
                  component: component,
                  showCurrentAdjustmentValues: false,
                )).toList(),
              ),
              const Divider(height: 1),
            ],
          ),
        )
      ),
    );
  }
}