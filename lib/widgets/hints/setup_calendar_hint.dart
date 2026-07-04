import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';

/// Suggestion hint shown in the Setup timeline once the user has a few setups or
/// Strava activities, nudging them to turn on the Calendar view.
class SetupCalendarHint extends StatelessWidget {
  @Preview(name: "SetupCalendarHint", group: "Hints")
  const SetupCalendarHint({super.key});

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: colors.tertiary,
                            ),
                            Text(
                              'SUGGESTION',
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
                          'See your history at a glance',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Turn on the Calendar to browse your setups and entries by date.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            final settings = context.read<AppSettings>();
                            settings.enableCalendar = true;
                            settings.hintShownThisSession = true;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                persist: false,
                                showCloseIcon: true,
                                content: Text(
                                  'Calendar enabled — find it next to the search button on the Setups tab',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Turn on Calendar'),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final settings = context.read<AppSettings>();
                    settings.showSetupCalendarHint = false;
                    settings.hintShownThisSession = true;
                  },
                  icon: const Icon(Icons.close, size: 18),
                  color: colors.tertiary,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
