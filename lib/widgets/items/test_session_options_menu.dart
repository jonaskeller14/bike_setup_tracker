import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/feedback/test_session.dart';
import '../../repositories/app_repository.dart';
import '../../utils/test_session_actions.dart';

/// Resume (once ended), Edit (the name) and Remove of a test session. Ending it
/// stays on the next step card and the session sheet. Resume stays listed but
/// disabled when blocked, so the reason is visible.
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
        _TestSessionOption.resume => TestSessionActions.resumeSession(context, session: session),
        _TestSessionOption.edit => TestSessionActions.editSession(context, session: session),
        _TestSessionOption.remove => TestSessionActions.removeSession(context, session: session),
      },
      itemBuilder: (context) {
        final canResume = context.read<AppRepository>().canResumeTestSession(session);
        return [
          for (final option in _TestSessionOption.values)
            if (option != _TestSessionOption.resume || !session.isRunning)
              PopupMenuItem(
                value: option,
                enabled: option != _TestSessionOption.resume || canResume,
                child: Row(
                  spacing: 10,
                  children: [
                    Icon(option.iconData, size: 20),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(option.label(context.l10n)),
                          if (option == _TestSessionOption.resume && !canResume)
                            Text(
                              context.l10n.testSessionResumeBlocked,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ];
      },
    );
  }
}

enum _TestSessionOption {
  resume(Icons.play_arrow),
  edit(Icons.edit),
  remove(Icons.delete);

  final IconData iconData;

  const _TestSessionOption(this.iconData);

  String label(AppLocalizations l10n) => switch (this) {
    resume => l10n.testSessionResume,
    edit => l10n.edit,
    remove => l10n.remove,
  };
}
