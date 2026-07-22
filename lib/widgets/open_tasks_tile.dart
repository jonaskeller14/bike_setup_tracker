import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_rule_page.dart';
import '../repositories/app_repository.dart';
import 'items/task_rule_list_card.dart';

sealed class _OTTAssociation {
  final String id;
  const _OTTAssociation({required this.id});
}

class _OTTBikeAssociation extends _OTTAssociation {
  const _OTTBikeAssociation({required super.id});
}

class _OTTComponentAssociation extends _OTTAssociation {
  const _OTTComponentAssociation({required super.id});
}

class OpenTasksTile extends StatelessWidget {
  final _OTTAssociation _association;

  const OpenTasksTile._({
    super.key,
    required this._association,
  });

  factory OpenTasksTile.bike({Key? key, required String bikeId}) =>
    OpenTasksTile._(key: key, association: _OTTBikeAssociation(id: bikeId));

  factory OpenTasksTile.component({Key? key, required String componentId}) =>
    OpenTasksTile._(key: key, association: _OTTComponentAssociation(id: componentId));
  
  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    
    final openTasks = switch (_association) {
      _OTTBikeAssociation(:final id) => appRepository.openTaskRulesForBike(id),
      _OTTComponentAssociation(:final id) => appRepository.openTaskRulesForComponent(id),
    };
    
    final count = openTasks.length;
    final aggregatedStatus = appRepository.getAggregatedTaskStatus(openTasks.map((t) => t.rule));
    final isEnabled = count > 0;

    return ExpansionTile(
      enabled: isEnabled,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: aggregatedStatus.getStatusColor(context),
        child: const Icon(Icons.checklist),
      ),
      title: Text(
        "Open Tasks",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isEnabled ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        ...openTasks.map((t) => TaskRuleListCard(taskRuleId: t.rule.id)),
        // const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              final newTaskRule = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => switch (_association) {
                    _OTTBikeAssociation(:final id) => TaskRulePage.addForBike(bikeId: id),
                    _OTTComponentAssociation(:final id) => TaskRulePage.addForComponent(componentId: id),
                  },
                ),
              );
              if (newTaskRule == null) return;
              await appRepository.addTaskRule(newTaskRule);
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
          ),
        ),
      ],
    );
  }
}
