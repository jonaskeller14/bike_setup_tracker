import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../utils/url.dart';
import 'app_hint_deck.dart';

/// Transient dashboard empty-state guidance, not a persisted app hint.
class StravaNoGearsHint extends StatelessWidget {
  static const _noGearsSteps = [
    'Open the Strava app',
    'Profile picture → Gear → Add a new Bike',
    'Come back here and tap Sync',
  ];

  const StravaNoGearsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppHintDeck(
      icon: Icons.directions_bike_outlined,
      label: 'No gear found',
      title: 'Add a bike in Strava',
      action: AppHintAction(
        label: 'Open Strava',
        icon: Icons.open_in_new,
        completesHint: false,
        onPressed: () => launchStrava(context),
      ),
      pages: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            for (final (index, step) in _noGearsSteps.indexed)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: hint.accent, shape: BoxShape.circle),
                    child: Text(
                      '${index + 1}',
                      style: textTheme.labelSmall?.copyWith(
                        color: hint.onAccent,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Expanded(child: Text(step)),
                ],
              ),
            const SizedBox(height: 2),
            Text(
              'Tip: you can also assign the bike to existing activities in Strava.',
              style: textTheme.bodySmall?.copyWith(
                color: hint.onContainer.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
