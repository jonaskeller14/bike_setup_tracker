import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/details/task_rule_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import 'sheet.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: sheetTitle(context, taskRule?.name ?? "-"),
                  ),
                  sheetEditButton(context, onPressed: () async {
                    if (taskRule == null) return;
                    await TaskActions.editTaskRule(context, taskRule: taskRule);
                  }),
                  sheetCloseButton(context),
                ],
              ),
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
