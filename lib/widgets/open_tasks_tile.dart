import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task/task_rule.dart';
import '../pages/task_rule_page.dart';
import '../repositories/app_repository.dart';
import 'empty_state_placeholder2.dart';
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
    return ExpansionTile(
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
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        if (openTasks.isEmpty) ...[
          EmptyStatePlaceholder2(
            iconData: Icons.checklist,
            title: 'No open tasks',
            subtitle: 'Add a task to keep track of maintenance',
            onTap: () => _addTaskRule(context, appRepository),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _addTaskRule(context, appRepository),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
        ] else ...[
          ...openTasks.map(
            (t) => TaskRuleListCard(
              taskRuleId: t.rule.id,
              heroTag: 'open-task-card-${t.rule.id}',
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () => _addTaskRule(context, appRepository),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addTaskRule(BuildContext context, AppRepository appRepository) async {
    final newTaskRule = await Navigator.push<TaskRule>(
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
  }
}
