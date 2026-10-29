import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component/component.dart';
import '../../theme.dart';
import 'app_hint_deck.dart';

class Release45Hint extends StatelessWidget {
  const Release45Hint({super.key, required this.onDismiss, required this.onEnableTasks});

  final VoidCallback onDismiss;
  final Future<void> Function() onEnableTasks;

  @override
  Widget build(BuildContext context) {
    // Someone who turned Task Presets off is not asked to turn on Tasks for them.
    final offerTasks = context.select<AppSettings, bool>((s) => s.enableTaskPresets && !s.showTaskPresets);

    return AppHintDeck(
      icon: Icons.new_releases_outlined,
      label: "What's new",
      onDismiss: onDismiss,
      pages: [
        const AppHintPage(
          title: 'Fork & shock catalog',
          content: Text(
            'Adding a fork or shock? Pick the model from the built-in catalog and its adjustments, like click '
            'ranges, air pressure and SAG, are filled in for you. Everything stays editable.',
          ),
        ),
        AppHintPage(
          title: 'Recommended tasks',
          action: offerTasks
              ? AppHintAction(label: 'Turn on Tasks', icon: Icons.add_task, onPressed: onEnableTasks)
              : null,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                'Whenever you add a component, matching maintenance tasks like a chain wear check or a fork '
                'service are suggested. Catalog forks and shocks use the manufacturer’s service intervals.'
                '${offerTasks ? ' Turn on Tasks to get them.' : ''}',
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ExampleChip(ComponentType.chain.getIconData(), 'Check chain wear'),
                  _ExampleChip(ComponentType.fork.getIconData(), 'Lower leg service'),
                  _ExampleChip(ComponentType.shock.getIconData(), 'Air can service'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: hint.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(icon, size: 14, color: hint.accent),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: hint.onContainer),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
