import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'app_hint_deck.dart';

class StravaGearLinkHint extends StatelessWidget {
  const StravaGearLinkHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.info_outline,
      label: l10n.hintLabelInfo,
      pages: [
        AppHintPage(
          title: l10n.hintStravaLinkTitle,
          content: Text(l10n.hintStravaLinkBody),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
