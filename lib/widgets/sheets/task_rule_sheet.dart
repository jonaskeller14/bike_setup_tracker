import 'package:flutter/material.dart';
import '../../pages/details/task_rule_details_page.dart';

Future<void> showTaskRuleSheet(BuildContext context, {required String taskRuleId, String? highlightTaskEntryId}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) {
      return SafeArea(
        child: TaskRuleDetailsPageContent(
          taskRuleId: taskRuleId,
          highlightTaskEntryId: highlightTaskEntryId,
          showEditButton: true,
          showCloseButton: true
        ),
      );
    }
  );
}
