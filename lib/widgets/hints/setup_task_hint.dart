import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'app_hint_deck.dart';

/// Suggestion hint shown in the Setup timeline once the user has recorded at
/// least one setup, nudging them to turn on Task Management.
class SetupTaskHint extends StatelessWidget {
  const SetupTaskHint({super.key, required this.onActivate, this.onDismiss});

  final Future<void> Function() onActivate;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.checklist,
      label: l10n.hintLabelSuggestion,
      pages: [
        AppHintPage(
          title: l10n.hintTasksTitle,
          action: AppHintAction(label: l10n.hintTasksAction, icon: Icons.add_task, onPressed: onActivate),
          content: Text(l10n.hintTasksBody),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
