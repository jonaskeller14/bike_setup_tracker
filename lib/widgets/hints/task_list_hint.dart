import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'app_hint_deck.dart';

class TaskListHint extends StatelessWidget {
  final VoidCallback? onDismiss;

  @Preview(name: "TaskListHint", group: "Hints")
  const TaskListHint({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      icon: Icons.swipe_left_outlined,
      label: 'Tip',
      pages: const [
        AppHintPage(
          title: 'Postpone a task',
          content: Text('Swipe a task to the left to add a delay. This works for every interval type except a fixed date.'),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
