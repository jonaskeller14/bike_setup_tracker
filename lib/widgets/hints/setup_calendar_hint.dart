import 'package:flutter/material.dart';

import 'app_hint_deck.dart';

/// Suggestion hint shown in the Setup timeline once the user has a few setups or
/// Strava activities, nudging them to turn on the Calendar view.
class SetupCalendarHint extends StatelessWidget {
  const SetupCalendarHint({super.key, required this.onActivate, this.onDismiss});

  final Future<void> Function() onActivate;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      icon: Icons.event,
      label: 'Suggestion',
      pages: [
        AppHintPage(
          title: 'See your history at a glance',
          action: AppHintAction(label: 'Turn on Calendar', icon: Icons.calendar_month, onPressed: onActivate),
          content: const Text('Turn on the Calendar to browse your setups and entries by date.'),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
