import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Transient dashboard empty-state guidance, not a persisted app hint.
class StravaNoGearsHint extends StatelessWidget {
  static const _noGearsSteps = [
    'Open the Strava app',
    'Profile picture → Gear → Add a new Bike',
    'Come back here and tap Sync',
  ];

  @Preview(name: "StravaNoGearsHint", group: "Hints")
  const StravaNoGearsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tintBg = Color.alphaBlend(
      colors.tertiary.withValues(alpha: 0.10),
      colors.surface,
    );
    final tintBorder = colors.tertiary.withValues(alpha: 0.30);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: tintBg,
          border: Border.all(color: tintBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(width: 4, color: colors.tertiary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Icon(
                        Icons.directions_bike_outlined,
                        size: 14,
                        color: colors.tertiary,
                      ),
                      Text(
                        'NO GEAR FOUND',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.tertiary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a bike in Strava',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a bike in the Strava app, then tap Sync here.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._noGearsSteps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: colors.tertiary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_noGearsSteps.indexOf(step) + 1}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.tertiary,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: you can also assign the bike to existing activities in Strava.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
