import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/import_preview.dart';
import '../../models/syncable.dart';
import '../../services/data_selection_dependencies.dart';
import 'data_item_name.dart';
import 'tile_meta_row.dart';

/// One item of the import summary: the file's version and this device's
/// version side by side. The version the import doesn't keep is dimmed, and a
/// badge on the affected card says what happens.
class ImportSummaryRow extends StatelessWidget {
  final ImportPreviewEntry entry;
  final ImportSourceOptions source;

  /// Shows when each version was last edited. Only Merge decides by it.
  final bool showEdited;

  const ImportSummaryRow({super.key, required this.entry, required this.source, required this.showEdited});

  static const arrowWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final remote = entry.remote;
    final local = entry.local;
    final isNew = _BadgeColors(scheme.primaryContainer, scheme.onPrimaryContainer);
    final neutral = _BadgeColors(scheme.surfaceContainerHighest, scheme.onSurfaceVariant);

    // A deleted item (a tombstone in the file, or in the trash here) is struck through unless told otherwise.
    Widget card(Syncable item, {_Badge? badge, bool dimmed = false, bool? struck}) => _ItemCard(
      kind: entry.kind,
      item: item,
      showEdited: showEdited,
      badge: badge,
      dimmed: dimmed,
      struck: struck ?? item.isDeleted,
    );
    Widget missing(String text) => _Placeholder(text: text);

    final (file, device) = switch (entry.outcome) {
      ImportOutcome.added => (
        card(
          remote!,
          badge: local != null
              ? _Badge(l10n.importSummaryBadgeRestored, isNew)
              : _Badge(l10n.importSummaryBadgeNew, isNew),
        ),
        local != null
            ? card(local, dimmed: true, badge: _Badge(l10n.importSummaryInTrash, neutral))
            : missing(l10n.importSummaryNotOnDevice),
      ),
      ImportOutcome.updated => (
        card(remote!),
        card(
          local!,
          dimmed: true,
          badge: _Badge(
            l10n.importSummaryBadgeOverwritten,
            _BadgeColors(scheme.secondary, scheme.onSecondary),
          ),
        ),
      ),
      ImportOutcome.unchanged => (
        card(
          remote!,
          dimmed: true,
          badge: _Badge(
            remote.hasSameContent(local!) ? l10n.importSummaryBadgeIdentical : l10n.importSummaryBadgeOlder,
            neutral,
          ),
        ),
        card(local),
      ),
      ImportOutcome.trashed => (
        remote == null
            ? missing(l10n.importSummaryNotInSource(source.name))
            : card(remote, dimmed: true, badge: _Badge(l10n.importSummaryDeletedInSource(source.name), neutral)),
        card(
          local!,
          dimmed: true,
          struck: true,
          badge: _Badge(l10n.importSummaryBadgeTrashed, _BadgeColors(scheme.errorContainer, scheme.onErrorContainer)),
        ),
      ),
    };
    // The file's version (or its deletion) replaces the device's.
    final flows = switch (entry.outcome) {
      ImportOutcome.added || ImportOutcome.updated => true,
      ImportOutcome.trashed => remote != null,
      ImportOutcome.unchanged => false,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: file),
            SizedBox(
              width: arrowWidth,
              child: flows ? Icon(Icons.arrow_forward, size: 18, color: scheme.onSurfaceVariant) : null,
            ),
            Expanded(child: device),
          ],
        ),
      ),
    );
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;

  const _BadgeColors(this.background, this.foreground);
}

class _Badge extends StatelessWidget {
  final String label;
  final _BadgeColors colors;

  const _Badge(this.label, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        label,
        style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

/// An item card in the look of the data select rows: icon, name and, if
/// [showEdited], when it was last edited.
class _ItemCard extends StatelessWidget {
  final DataKind kind;
  final Syncable item;
  final bool showEdited;
  final _Badge? badge;
  final bool dimmed;
  final bool struck;

  const _ItemCard({
    required this.kind,
    required this.item,
    required this.showEdited,
    this.badge,
    this.dimmed = false,
    this.struck = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.read<AppSettings>();
    final edited = item.lastModified.toLocal();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          // The badge goes last, so the names of the two cards in a row line up.
          children: [
            Opacity(
              opacity: dimmed ? 0.45 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Icon(dataItemIcon(kind, item), size: 18),
                      Expanded(
                        child: Text(
                          dataItemName(kind, item, l10n, appSettings),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: struck ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showEdited)
                    TileMetaRow(
                      icon: Icons.history,
                      text:
                          '${DateFormat(appSettings.dateFormat, l10n.localeName).format(edited)} • '
                          '${DateFormat(appSettings.timeFormat, l10n.localeName).format(edited)}',
                    ),
                ],
              ),
            ),
            ?badge,
          ],
        ),
      ),
    );
  }
}

/// Muted text in place of the side that has no item, centred on the card next to it.
class _Placeholder extends StatelessWidget {
  final String text;

  const _Placeholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style:
              Theme.of(
                    context,
                  ).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
