import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';
import '../../utils/url.dart';
import 'app_hint_deck.dart';

/// Transient dashboard empty-state guidance, not a persisted app hint.
class StravaNoGearsHint extends StatelessWidget {
  const StravaNoGearsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final noGearsSteps = [l10n.hintStravaNoGearsStep1, l10n.hintStravaNoGearsStep2, l10n.hintStravaNoGearsStep3];

    return AppHintDeck(
      icon: Icons.directions_bike_outlined,
      label: l10n.hintStravaNoGearsLabel,
      pages: [
        AppHintPage(
          title: l10n.hintStravaNoGearsTitle,
          action: AppHintAction(
            label: l10n.hintStravaNoGearsOpen,
            icon: Icons.open_in_new,
            completesHint: false,
            onPressed: () => launchStrava(context),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              for (final (index, step) in noGearsSteps.indexed)
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
                l10n.hintStravaNoGearsTip,
                style: textTheme.bodySmall?.copyWith(
                  color: hint.onContainer.withValues(alpha: 0.75),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
