import 'package:flutter/material.dart';

import '../../icons/simple_icons.dart';
import 'sheet_header.dart';

/// Settings sheet with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showComponentPresetsSettingSheet(BuildContext context, {required bool value}) {
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _PresetsSettingSheet(
      value: value,
      title: 'Component Presets',
      icon: Icons.auto_awesome_outlined,
      intro:
          'Set up a fork or shock in seconds: pick the model from the built-in catalog '
          'instead of entering every adjustment by hand.',
      steps: const [
        (Icons.search, 'Add a fork or shock and search for its model and year, e.g. "Fox 36".'),
        (
          Icons.tune,
          'Name, notes and adjustments are filled in: rebound and compression with their click ranges, '
              'air pressure and SAG.',
        ),
        (
          Icons.link,
          'Already have the component? Link the model on its edit page and choose whether its '
              'adjustments merge with yours or replace them.',
        ),
      ],
      caption:
          'Covers forks and shocks from FOX, RockShox, Öhlins and other brands. Everything stays editable. '
          'Turning this off hides the catalog; your components keep their adjustments.',
    ),
  );
}

/// Settings sheet with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showTaskPresetsSettingSheet(BuildContext context, {required bool value}) {
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _PresetsSettingSheet(
      value: value,
      title: 'Task Presets',
      icon: Icons.auto_awesome_outlined,
      intro: 'Get recommended maintenance tasks for your components, like a chain wear check or a fork service.',
      steps: const [
        (
          Icons.add_task,
          'Whenever you add, duplicate or replace a component, its recommended tasks are '
              'offered. Pick the ones you want.',
        ),
        (Icons.edit_note, 'Adding a task for a component? Tap a suggestion to fill in its name, notes and interval.'),
        (
          SimpleIcons.strava,
          'With Strava connected, intervals follow your rides, like distance or riding time. '
              'Without it, they are time-based. Catalog forks and shocks use the manufacturer’s service intervals.',
        ),
      ],
      caption:
          'Covers chains, cassettes, forks, shocks, brakes, tires, headsets, bottom brackets, seatposts, '
          'frames and shift cables. Added tasks are normal tasks you can edit or delete.',
    ),
  );
}

class _PresetsSettingSheet extends StatelessWidget {
  const _PresetsSettingSheet({
    required this.value,
    required this.title,
    required this.icon,
    required this.intro,
    required this.steps,
    required this.caption,
  });

  final bool value;
  final String title;
  final IconData icon;
  final String intro;
  final List<(IconData, String)> steps;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: title, leadingIcon: Icon(icon)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(intro, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  for (final (stepIcon, text) in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Icon(stepIcon, size: 20, color: theme.colorScheme.primary),
                          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                  Text(
                    caption,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          RadioGroup<bool>(
            groupValue: value,
            onChanged: (selected) => Navigator.pop(context, selected),
            child: const Column(
              children: [
                RadioListTile(value: false, title: Text('Off')),
                RadioListTile(value: true, title: Text('On')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
