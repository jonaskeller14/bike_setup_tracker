import 'package:flutter/material.dart';

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
    final parentName = this.parentName;
    return AppHintDeck(
      icon: Icons.lightbulb_outline,
      label: 'Suggestion',
      pages: [
        AppHintPage(
          title: parentName == null ? 'Group parts under their parent' : 'Mount it on $parentName?',
          onLearnMore: () => showSubcomponentsSettingSheet(context, value: false),
          action: AppHintAction(
            label: 'Activate Subcomponents',
            icon: Icons.account_tree_outlined,
            onPressed: onActivate,
          ),
          content: const Text(
            'Turn on Subcomponents to install parts on other parts, like a tire on a wheel. They move along with their parent.',
          ),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
