import 'package:flutter/material.dart';

import '../sheets/installation_timeline_hint_sheet.dart';
import 'app_hint_deck.dart';

/// Suggests the Installation Timeline where a component is moved or replaced.
class InstallationTimelineHint extends StatelessWidget {
  const InstallationTimelineHint({super.key, required this.message, required this.onActivate, this.onDismiss});

  final String message;
  final Future<void> Function() onActivate;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      icon: Icons.lightbulb_outline,
      label: 'Suggestion',
      title: 'Track installation history',
      pages: [Text(message)],
      onDismiss: onDismiss,
      onLearnMore: () => showInstallationTimelineSettingSheet(context, value: false),
      action: AppHintAction(label: 'Activate Timeline', icon: Icons.timeline, onPressed: onActivate),
    );
  }
}
