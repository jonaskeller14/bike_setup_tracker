import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../sheets/subcomponents_hint_sheet.dart';
import 'app_hint_deck.dart';

class Release44Hint extends StatelessWidget {
  const Release44Hint({
    super.key,
    required this.onDismiss,
    required this.onEnableSubcomponents,
    required this.onEnableAttachments,
  });

  final VoidCallback onDismiss;
  final Future<void> Function() onEnableSubcomponents;
  final Future<void> Function() onEnableAttachments;

  static const _turnOnHere = ' Turn it on here or anytime in Settings › Features.';

  @override
  Widget build(BuildContext context) {
    final subcomponentsOn = context.select<AppSettings, bool>((s) => s.enableInstallOnComponent);
    final attachmentsOn = context.select<AppSettings, bool>((s) => s.enableAttachments);

    return AppHintDeck(
      icon: Icons.new_releases_outlined,
      label: "What's new",
      onDismiss: onDismiss,
      pages: [
        const AppHintPage(
          title: 'Your filters are remembered',
          content: Text(
            'The selected bike and filters now stay applied when you reopen the app. '
            'Prefer a fresh start? Turn off Remember Filters in Settings › Preferences.',
          ),
        ),
        AppHintPage(
          title: 'Subcomponents',
          onLearnMore: () => showSubcomponentsSettingSheet(context, value: subcomponentsOn),
          action: subcomponentsOn
              ? null
              : AppHintAction(label: 'Turn on', icon: Icons.account_tree_outlined, onPressed: onEnableSubcomponents),
          content: Text(
            'Install parts on other parts, like a tire on a wheel. They move between bikes along with their parent.'
            '${subcomponentsOn ? '' : _turnOnHere}',
          ),
        ),
        AppHintPage(
          title: 'Attachments',
          action: attachmentsOn
              ? null
              : AppHintAction(label: 'Turn on', icon: Icons.attach_file, onPressed: onEnableAttachments),
          content: Text(
            'Add photos and files to bikes, components, setups and tasks. They are stored on this device only '
            'and are not included in backups.${attachmentsOn ? '' : _turnOnHere}',
          ),
        ),
      ],
    );
  }
}
