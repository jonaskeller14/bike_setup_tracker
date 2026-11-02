import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'app_hint_deck.dart';

class Release46Hint extends StatelessWidget {
  const Release46Hint({super.key, required this.onDismiss, required this.onChooseLanguage});

  final VoidCallback onDismiss;
  final Future<void> Function() onChooseLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.new_releases_outlined,
      label: l10n.hintLabelWhatsNew,
      onDismiss: onDismiss,
      pages: [
        AppHintPage(
          title: l10n.hintRelease46LanguageTitle,
          action: AppHintAction(
            label: l10n.hintRelease46ChooseLanguage,
            icon: Icons.language,
            onPressed: onChooseLanguage,
            completesHint: false,
          ),
          content: Text(l10n.hintRelease46LanguageBody),
        ),
      ],
    );
  }
}
