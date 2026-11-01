import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/entity_names.dart';
import '../../l10n/l10n.dart';
import '../../l10n/test_session_text.dart';
import '../../models/app_settings.dart';
import '../../models/feedback/test_session.dart';
import '../../repositories/app_repository.dart';
import '../running_badge.dart';
import 'test_session_options_menu.dart';
import 'tile_meta_row.dart';

class TestSessionTile extends StatelessWidget {
  final TestSession session;
  final VoidCallback? onTap;

  const TestSessionTile({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final runs = context.select<AppRepository, int>((repository) => repository.setupsInSession(session.id).length);
    final scheme = Theme.of(context).colorScheme;

    // Laid out like the component cards beside it, so the menus line up.
    return ListTile(
      onTap: onTap,
      leading: const Icon(TestSession.iconData),
      titleAlignment: ListTileTitleAlignment.titleHeight,
      minTileHeight: 0,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      title: Row(
        spacing: 8,
        children: [
          Flexible(
            child: Text(
              session.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (session.isRunning) const RunningBadge(),
        ],
      ),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            DateFormat(appSettings.dateFormat, context.l10n.localeName).format(session.startedAtLocal),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          TileMetaRow(icon: Icons.psychology, text: testSessionMethodLabel(session.method, context.l10n)),
          TileMetaRow(icon: Icons.repeat, text: context.l10n.testSessionRunsCount(runs)),
        ],
      ),
      trailing: TestSessionOptionsMenu(session: session),
    );
  }
}
