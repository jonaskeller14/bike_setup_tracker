import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../sheets/presets_setting_sheets.dart';
import 'app_hint_deck.dart';

class Release48Hint extends StatelessWidget {
  const Release48Hint({super.key, required this.onDismiss, required this.onEnableSetupGuides});

  final VoidCallback onDismiss;
  final Future<void> Function() onEnableSetupGuides;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final guidesOn = context.select<AppSettings, bool>((s) => s.enableSetupGuides);
    // Setup Guides need Component Presets; someone who turned them off is not asked to turn them on.
    final offerGuides = context.select<AppSettings, bool>((s) => s.enableComponentPresets && !s.enableSetupGuides);

    return AppHintDeck(
      icon: Icons.new_releases_outlined,
      label: l10n.hintLabelWhatsNew,
      onDismiss: onDismiss,
      pages: [
        AppHintPage(
          title: l10n.featuresSetupGuides,
          onLearnMore: () => showSetupGuidesSettingSheet(context, value: guidesOn),
          action: offerGuides
              ? AppHintAction(
                  label: l10n.hintReleaseTurnOn,
                  icon: Icons.tips_and_updates_outlined,
                  onPressed: onEnableSetupGuides,
                )
              : null,
          content: Text('${l10n.hintRelease48GuidesBody}${offerGuides ? l10n.hintReleaseTurnOnHere : ''}'),
        ),
        AppHintPage(
          title: l10n.hintRelease48ChartsTitle,
          content: Text(l10n.hintRelease48ChartsBody),
        ),
      ],
    );
  }
}
