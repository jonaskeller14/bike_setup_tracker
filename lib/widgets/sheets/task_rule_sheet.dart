import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/details/task_rule_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import 'sheet_header.dart';

Future<void> showTaskRuleSheet(BuildContext context, {required String taskRuleId, String? highlightTaskEntryId}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) {
      final appRepository = context.watch<AppRepository>();
      final taskRule = appRepository.taskRules[taskRuleId];

      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: taskRule?.name ?? "-",
              onEdit: taskRule != null ? () => TaskActions.editTaskRule(context, taskRule: taskRule) : null,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: TaskRuleDetailsPageContent(
                taskRuleId: taskRuleId,
                highlightTaskEntryId: highlightTaskEntryId,
              ),
            ),
          ],
        ),
      );
    }
  );
}
