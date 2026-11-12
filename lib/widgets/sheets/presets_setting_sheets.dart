import 'package:flutter/material.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/l10n.dart';
import '../../l10n/markup_text.dart';
import 'sheet_header.dart';

/// Settings sheet with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showComponentPresetsSettingSheet(BuildContext context, {required bool value}) {
  final l10n = context.l10n;
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _PresetsSettingSheet(
      value: value,
      title: l10n.featuresComponentPresets,
      icon: Icons.auto_awesome_outlined,
      intro: l10n.presetsComponentIntro,
      steps: [
        (Icons.search, l10n.presetsComponentStepSearch),
        (Icons.tune, l10n.presetsComponentStepFilled),
        (Icons.link, l10n.presetsComponentStepLink),
      ],
      caption: l10n.presetsComponentCaption,
    ),
  );
}

/// Settings sheet with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showTaskPresetsSettingSheet(BuildContext context, {required bool value}) {
  final l10n = context.l10n;
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _PresetsSettingSheet(
      value: value,
      title: l10n.featuresTaskPresets,
      icon: Icons.auto_awesome_outlined,
      intro: l10n.presetsTaskIntro,
      steps: [
        (Icons.add_task, l10n.presetsTaskStepOffered),
        (Icons.edit_note, l10n.presetsTaskStepSuggestion),
        (SimpleIcons.strava, l10n.presetsTaskStepStrava),
      ],
      caption: l10n.presetsTaskCaption,
    ),
  );
}

/// Settings sheet with Off/On radios; resolves to the selected value, or null if dismissed.
Future<bool?> showSetupGuidesSettingSheet(BuildContext context, {required bool value}) {
  final l10n = context.l10n;
  return showModalBottomSheet<bool>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => _PresetsSettingSheet(
      value: value,
      title: l10n.featuresSetupGuides,
      icon: Icons.tips_and_updates_outlined,
      intro: l10n.setupGuidesIntro,
      steps: [
        (Icons.link, l10n.setupGuidesStepLink),
        (Icons.tips_and_updates_outlined, l10n.setupGuidesStepCard),
        (Icons.touch_app_outlined, l10n.setupGuidesStepApply),
      ],
      caption: l10n.setupGuidesCaption,
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
    final l10n = context.l10n;

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
                  Text.rich(markupTextSpan(intro), style: theme.textTheme.bodyMedium),
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
            child: Column(
              children: [
                RadioListTile(value: false, title: Text(l10n.valueOff)),
                RadioListTile(value: true, title: Text(l10n.valueOn)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
