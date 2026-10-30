import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../l10n/l10n.dart';
import 'app_hint_deck.dart';

class TaskListHint extends StatelessWidget {
  final VoidCallback? onDismiss;

  @Preview(name: "TaskListHint", group: "Hints")
  const TaskListHint({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.swipe_left_outlined,
      label: l10n.hintLabelTip,
      pages: [
        AppHintPage(
          title: l10n.hintTaskListTitle,
          content: Text(l10n.hintTaskListBody),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
