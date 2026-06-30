import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/component.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../open_tasks_tile.dart';

class GarageComponentIconCard extends StatelessWidget {
  final Component component;
  final String? componentToShowDetails;

  const GarageComponentIconCard({super.key, required this.component, required this.componentToShowDetails});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = componentToShowDetails == component.id;
    final appSettings = context.watch<AppSettings>();

    TaskStatusType? indicatorStatus;
    if (appSettings.enableTask && appSettings.enableGarageTaskIndicator) {
      final appRepository = context.watch<AppRepository>();
      final openRules = appRepository.taskRules.values
          .where((rule) => rule.componentId == component.id)
          .where((rule) => appRepository.getTaskRuleStatus(rule).type != TaskStatusType.completed)
          .toList();
      if (openRules.isNotEmpty) {
        indicatorStatus = OpenTasksTile.getAggregatedStatus(openRules, appRepository);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: ValueKey(component.id),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.tertiaryContainer
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.tertiary
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(
                    color: colorScheme.tertiary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )]
                : null,
          ),
          child: Icon(
            component.componentType.getIconData(),
            size: 24,
            color: isSelected
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurface,
          ),
        ),
        if (indicatorStatus != null)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: indicatorStatus.getStatusColor(),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
