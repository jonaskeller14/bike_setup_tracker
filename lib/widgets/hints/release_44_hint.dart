import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../sheets/subcomponents_hint_sheet.dart';
import 'app_hint_deck.dart';

class Release44Hint extends StatelessWidget {
  const Release44Hint({
    super.key,
    required this.onDismiss,
    required this.onEnableSubcomponents,
  });

  final VoidCallback onDismiss;
  final Future<void> Function() onEnableSubcomponents;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subcomponentsOn = context.select<AppSettings, bool>((s) => s.enableInstallOnComponent);

    return AppHintDeck(
      icon: Icons.new_releases_outlined,
      label: l10n.hintLabelWhatsNew,
      onDismiss: onDismiss,
      pages: [
        AppHintPage(
          title: l10n.hintReleaseFiltersTitle,
          content: Text(l10n.hintReleaseFiltersBody),
        ),
        AppHintPage(
          title: l10n.hintReleaseSubcomponentsTitle,
          onLearnMore: () => showSubcomponentsSettingSheet(context, value: subcomponentsOn),
          action: subcomponentsOn
              ? null
              : AppHintAction(
                  label: l10n.hintReleaseTurnOn,
                  icon: Icons.account_tree_outlined,
                  onPressed: onEnableSubcomponents,
                ),
          content: Text(
            '${l10n.hintReleaseSubcomponentsBody}${subcomponentsOn ? '' : l10n.hintReleaseTurnOnHere}',
          ),
        ),
        AppHintPage(
          title: l10n.hintReleaseAttachmentsTitle,
          content: Text(l10n.hintReleaseAttachmentsBody),
        ),
      ],
    );
  }
}
