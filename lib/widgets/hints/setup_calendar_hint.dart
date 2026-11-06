import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'app_hint_deck.dart';

/// Suggestion hint shown in the Setup timeline once the user has a few setups or
/// Strava activities, nudging them to turn on the Calendar view.
class SetupCalendarHint extends StatelessWidget {
  const SetupCalendarHint({super.key, required this.onActivate, this.onDismiss});

  final Future<void> Function() onActivate;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.event,
      label: l10n.hintLabelSuggestion,
      pages: [
        AppHintPage(
          title: l10n.hintCalendarTitle,
          action: AppHintAction(label: l10n.hintCalendarAction, icon: Icons.calendar_month, onPressed: onActivate),
          content: Text(l10n.hintCalendarBody),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
