import 'package:flutter/material.dart';

import 'app_hint_deck.dart';

class StravaGearLinkHint extends StatelessWidget {
  const StravaGearLinkHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      icon: Icons.info_outline,
      label: 'Info',
      title: 'Link your Strava gear',
      pages: const [
        Text('Choose a bike for each gear. Your setups are then matched with the right Strava activities.'),
      ],
      onDismiss: onDismiss,
    );
  }
}
