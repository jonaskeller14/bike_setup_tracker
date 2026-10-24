import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/feedback/test_session.dart';
import '../../repositories/app_repository.dart';
import '../../services/test_session_service.dart';
import '../running_badge.dart';
import 'test_session_options_menu.dart';
import 'tile_meta_row.dart';

/// A test session as one list row: name, method, number of runs, whether it is
/// still running, and its Edit / Remove menu.
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
              session.displayName,
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
            DateFormat(appSettings.dateFormat).format(session.startedAtLocal),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          TileMetaRow(icon: Icons.tune, text: TestSessionService.methodLabel(session.method)),
          TileMetaRow(icon: Icons.directions_bike, text: Intl.plural(runs, one: '1 run', other: '$runs runs')),
        ],
      ),
      trailing: TestSessionOptionsMenu(session: session),
    );
  }
}
