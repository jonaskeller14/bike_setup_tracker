import 'package:flutter/material.dart';

import 'app_hint_deck.dart';

class SetupComparisonHint extends StatelessWidget {
  const SetupComparisonHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      key: const Key('compare-setups-hint'),
      icon: Icons.info_outline,
      label: 'Info',
      title: 'Compare two setups',
      pages: const [
        Text(
          'By default, A is your current setup and B is the setup you chose. Tap either setup above to pick another one. Orange values indicate differences; switch to All to include all recorded values.',
        ),
      ],
      onDismiss: onDismiss,
    );
  }
}
