import 'package:flutter/material.dart';

import 'app_hint_deck.dart';

/// Suggestion hint shown in the Setup timeline once the user has recorded at
/// least one setup, nudging them to turn on Task Management.
class SetupTaskHint extends StatelessWidget {
  const SetupTaskHint({super.key, required this.onActivate, this.onDismiss});

  final Future<void> Function() onActivate;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      icon: Icons.checklist,
      label: 'Suggestion',
      title: 'Organize your bike tasks',
      pages: const [
        Text('Turn on Task Management to note anything bike related — maintenance, tweaks to try, or trails to ride.'),
      ],
      onDismiss: onDismiss,
      action: AppHintAction(label: 'Activate Tasks', icon: Icons.add_task, onPressed: onActivate),
    );
  }
}
