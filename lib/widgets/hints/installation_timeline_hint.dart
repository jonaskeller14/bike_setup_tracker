import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.lightbulb_outline,
      label: l10n.hintLabelSuggestion,
      pages: [
        AppHintPage(
          title: l10n.hintTimelineTitle,
          onLearnMore: () => showInstallationTimelineSettingSheet(context, value: false),
          action: AppHintAction(label: l10n.hintTimelineAction, icon: Icons.timeline, onPressed: onActivate),
          content: Text(message),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
