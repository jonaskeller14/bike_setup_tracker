import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';

class StravaGearLinkHint extends StatelessWidget {
  @Preview(name: "StravaGearLinkHint", group: "Hints")
  const StravaGearLinkHint({super.key});

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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: colors.tertiary),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 6,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: colors.tertiary,
                                ),
                                Text(
                                  'INFO',
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
                              'Link your Strava gear',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Tap a gear below to connect it to one of your bikes.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.read<AppSettings>().showStravaLinkGearHint = false,
                      icon: const Icon(Icons.close, size: 18),
                      color: colors.tertiary,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
