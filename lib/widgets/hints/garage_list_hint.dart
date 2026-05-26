import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';

class GarageListHint extends StatelessWidget {
  static const _tips = [
    'Drag component icons to reorder, swap them to other bikes, or drop them into Uninstalled.',
    'Double-tap a component icon to view its setup history, notes, and charts.',
    'Double-tap a bike card to quickly filter your view and focus on its parts.',
  ];

  const GarageListHint({super.key});

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
                                Icon(Icons.touch_app_outlined, size: 14, color: colors.tertiary),
                                Text(
                                  'TIPS',
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
                              'Gestures in Garage',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._tips.map((tip) => Padding(
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
                                      '${_tips.indexOf(tip) + 1}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colors.tertiary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.read<AppSettings>().showGarageListHint = false,
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
