import 'package:flutter/material.dart';

class SetupComparisonHint extends StatelessWidget {
  const SetupComparisonHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tintBg = Color.alphaBlend(
      colors.tertiary.withValues(alpha: 0.10),
      colors.surface,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        key: const Key('compare-setups-hint'),
        decoration: BoxDecoration(
          color: tintBg,
          border: Border.all(color: colors.tertiary.withValues(alpha: 0.30)),
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
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: colors.tertiary),
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
                          'Compare two setups',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By default, A is your current setup and B is the setup you chose. Tap either setup above to pick another one. Orange values indicate differences; switch to All to include all recorded values.',
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
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
