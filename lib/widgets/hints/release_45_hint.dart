import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
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

    final l10n = context.l10n;

    return AppHintDeck(
      icon: Icons.new_releases_outlined,
      label: l10n.hintLabelWhatsNew,
      onDismiss: onDismiss,
      pages: [
        AppHintPage(
          title: l10n.hintRelease45CatalogTitle,
          content: Text(l10n.hintRelease45CatalogBody),
        ),
        AppHintPage(
          title: l10n.hintRelease45TasksTitle,
          action: offerTasks
              ? AppHintAction(label: l10n.hintTurnOnTasks, icon: Icons.add_task, onPressed: onEnableTasks)
              : null,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(offerTasks ? l10n.hintRelease45TasksBodyOfferTasks : l10n.hintRelease45TasksBody),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ExampleChip(ComponentType.chain.getIconData(), l10n.taskTemplateChainWearCheckName),
                  _ExampleChip(ComponentType.fork.getIconData(), l10n.taskTemplateForkLowerLegServiceName),
                  _ExampleChip(ComponentType.shock.getIconData(), l10n.taskTemplateShockAirCanServiceName),
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
