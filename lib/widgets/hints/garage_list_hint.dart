import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../l10n/l10n.dart';
import 'app_hint_deck.dart';

class GarageListHint extends StatelessWidget {
  final VoidCallback? onDismiss;

  @Preview(name: "GarageListHint", group: "Hints")
  const GarageListHint({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tips = [l10n.hintGarageTip1, l10n.hintGarageTip2, l10n.hintGarageTip3];

    return AppHintDeck(
      icon: Icons.touch_app_outlined,
      label: l10n.hintLabelTip,
      pages: [for (final tip in tips) AppHintPage(title: l10n.hintGarageTitle, content: Text(tip))],
      onDismiss: onDismiss,
    );
  }
}
