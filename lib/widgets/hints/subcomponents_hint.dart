import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../sheets/subcomponents_hint_sheet.dart';
import 'app_hint_deck.dart';

/// Suggests Subcomponents, either for a part that has a typical parent in the
/// garage ([parentName]) or for a crowded bike.
class SubcomponentsHint extends StatelessWidget {
  const SubcomponentsHint({super.key, required this.onActivate, this.onDismiss, this.parentName});

  final Future<void> Function() onActivate;
  final VoidCallback? onDismiss;
  final String? parentName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parentName = this.parentName;
    return AppHintDeck(
      icon: Icons.lightbulb_outline,
      label: l10n.hintLabelSuggestion,
      pages: [
        AppHintPage(
          title: parentName == null ? l10n.hintSubcomponentsTitle : l10n.hintSubcomponentsTitleParent(parentName),
          onLearnMore: () => showSubcomponentsSettingSheet(context, value: false),
          action: AppHintAction(
            label: l10n.hintSubcomponentsAction,
            icon: Icons.account_tree_outlined,
            onPressed: onActivate,
          ),
          content: Text(l10n.hintSubcomponentsBody),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
