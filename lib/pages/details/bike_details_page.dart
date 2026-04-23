import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/component_stats.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';
import '../../models/task_rule.dart';
import '../../widgets/open_tasks_card.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (appSettings.enableStrava && appSettings.enableInstallationTimeline)
                _buildStatCard(context, stats),
              if (bike.notes != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.notes),
                    titleAlignment: ListTileTitleAlignment.top,
                    title: SelectableText(bike.notes!),
                    dense: true,
                  ),
                ),
              if (appSettings.enablePerson)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
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
                ),
              if (appSettings.enableStrava)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: bike.stravaGear != null
                        ? const Icon(Icons.link)
                        : const Icon(Icons.link_off),                  
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
                ),
              if (appSettings.enableTask) () {
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

                return OpenTasksCard(openTasks: openTasks, repository: appRepository);
              }(),
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Components", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(Intl.plural(
                          components.length,
                          zero: "No components yet.",
                          one: "1 component",
                          other: '${components.length} components',
                        )),
                    ),
                    ...components.map((component) {
                      return ListTile(
                        leading: Icon(component.componentType.getIconData()),
                        title: Text(component.name),
                        dense: true,
                      );
                    })
                  ],
                )
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, ComponentStats stats) {
    final totalDistance = stats.distance;
    final totalElevation = stats.elevationGain;
    final totalMovingTime = stats.movingTime;

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.route,
                  label: "Distance",
                  value: '${NumberFormat.decimalPattern().format((totalDistance / 1000).round())} km',
                ),
                _buildStatItem(
                  context,
                  icon: Icons.terrain_outlined,
                  label: "Elevation",
                  value: '${NumberFormat.decimalPattern().format(totalElevation.round())} m',
                ),
                _buildStatItem(
                  context,
                  icon: Icons.timer_outlined,
                  label: "Moving Time",
                  value: '${NumberFormat.decimalPattern().format(totalMovingTime.inHours)}h ${totalMovingTime.inMinutes.remainder(60)}m',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}