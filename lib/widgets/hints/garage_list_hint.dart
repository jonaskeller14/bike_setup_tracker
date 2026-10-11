import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'app_hint_deck.dart';

class GarageListHint extends StatelessWidget {
  static const _tips = [
    'Drag component icons to reorder, swap them to other bikes, or drop them into Uninstalled.',
    'Double-tap a component icon to view its setup history, notes, and charts.',
    'Double-tap a bike card to quickly filter your view and focus on its parts.',
  ];

  final VoidCallback? onDismiss;

  @Preview(name: "GarageListHint", group: "Hints")
  const GarageListHint({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AppHintDeck(
      icon: Icons.touch_app_outlined,
      label: 'Tip',
      title: 'Gestures in Garage',
      pages: [for (final tip in _tips) Text(tip)],
      onDismiss: onDismiss,
    );
  }
}
