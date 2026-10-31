import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/feedback/test_session.dart';
import '../../utils/test_session_actions.dart';

/// Edit (the name) and Remove of a test session. Ending it stays on the next
/// step card and the session sheet.
class TestSessionOptionsMenu extends StatelessWidget {
  final TestSession session;
  final bool enabled;

  const TestSessionOptionsMenu({super.key, required this.session, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TestSessionOption>(
      enabled: enabled,
      tooltip: context.l10n.testSessionActionsTooltip,
      onSelected: (option) => switch (option) {
        _TestSessionOption.edit => TestSessionActions.editSession(context, session: session),
        _TestSessionOption.remove => TestSessionActions.removeSession(context, session: session),
      },
      itemBuilder: (context) => [
        for (final option in _TestSessionOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              spacing: 10,
              children: [
                Icon(option.iconData, size: 20),
                Text(option.label(context.l10n)),
              ],
            ),
          ),
      ],
    );
  }
}

enum _TestSessionOption {
  edit(Icons.edit),
  remove(Icons.delete);

  final IconData iconData;

  const _TestSessionOption(this.iconData);

  String label(AppLocalizations l10n) => switch (this) {
    edit => l10n.edit,
    remove => l10n.remove,
  };
}
