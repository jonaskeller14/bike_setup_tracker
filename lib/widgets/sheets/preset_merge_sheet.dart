import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../../utils/preset_merge.dart';
import '../items/adjustment_properties.dart';
import '../items/adjustment_type_icon.dart';
import 'sheet_header.dart';

/// Lets the rider decide how [productName]'s adjusters combine with the
/// component's [existing] adjustments: merged into them, starting from
/// [proposal], or replacing them. [unknownMaxKeys] are the catalog preset keys
/// whose max is a placeholder. Returns the resulting adjustments, or null when
/// dismissed.
Future<PresetMergeResult?> showPresetMergeSheet(
  BuildContext context, {
  required String productName,
  required List<Adjustment> existing,
  required List<PresetMergeRow> proposal,
  required Map<String, List<AdjustmentValue>> recordedValues,
  Set<String> unknownMaxKeys = const {},
}) {
  return showModalBottomSheet<PresetMergeResult>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _PresetMergeSheet(
      productName: productName,
      existing: existing,
      proposal: proposal,
      recordedValues: recordedValues,
      unknownMaxKeys: unknownMaxKeys,
    ),
  );
}

enum _Mode { merge, replace }

enum _Status {
  merged('Merged'),
  unchanged('Unchanged'),
  newAdjustment('New'),
  notAdded('Not added');

  final String label;
  const _Status(this.label);
}

/// One card of the preview: an adjustment as it will be after confirming, and
/// the changes the rider can make to it.
class _Entry {
  final Adjustment result;
  final _Status status;
  final Adjustment? own;
  final Adjustment? catalog;
  final bool keptOwnRange;
  final List<(String, PresetMergeRow)> choices;

  const _Entry(this.result, this.status, {this.own, this.catalog, this.keptOwnRange = false, this.choices = const []});
}

class _PresetMergeSheet extends StatefulWidget {
  final String productName;
  final List<Adjustment> existing;
  final List<PresetMergeRow> proposal;
  final Map<String, List<AdjustmentValue>> recordedValues;
  final Set<String> unknownMaxKeys;

  const _PresetMergeSheet({
    required this.productName,
    required this.existing,
    required this.proposal,
    required this.recordedValues,
    required this.unknownMaxKeys,
  });

  @override
  State<_PresetMergeSheet> createState() => _PresetMergeSheetState();
}

class _PresetMergeSheetState extends State<_PresetMergeSheet> {
  late final List<PresetMergeRow> _rows = List.of(widget.proposal);
  _Mode _mode = _Mode.merge;

  List<Adjustment> get _catalog => [for (final row in _rows) row.catalog];

  void _select(PresetMergeRow row) {
    setState(() => _rows[_rows.indexWhere((r) => r.catalog == row.catalog)] = row);
  }

  /// The existing adjustments [catalog] could merge into: same type, not merged yet.
  List<(String, PresetMergeRow)> _mergeChoices(Adjustment catalog) => [
    for (final own in widget.existing)
      if (canMergeAdjustment(own, catalog) && _rows.every((row) => row.existing != own))
        ('Merge into "${own.name}"', PresetMergeRow.merged(catalog, own)),
  ];

  List<_Entry> _mergeEntries() {
    final mergedRows = {for (final row in _rows) ?row.existing?.id: row};
    return [
      for (final own in widget.existing)
        if (mergedRows[own.id] case final row?)
          _merged(own, row.catalog)
        else
          _Entry(
            own,
            _Status.unchanged,
            own: own,
            choices: [
              for (final row in _rows)
                if (row.action != PresetMergeAction.merged && canMergeAdjustment(own, row.catalog))
                  ('Merge with "${row.catalog.name}" (preset)', PresetMergeRow.merged(row.catalog, own)),
            ],
          ),
      for (final row in _rows)
        if (row.action == PresetMergeAction.newAdjustment)
          _Entry(
            row.catalog,
            _Status.newAdjustment,
            catalog: row.catalog,
            choices: [
              ..._mergeChoices(row.catalog),
              ("Don't add", PresetMergeRow.notAdded(row.catalog)),
            ],
          ),
      for (final row in _rows)
        if (row.action == PresetMergeAction.notAdded)
          _Entry(
            row.catalog,
            _Status.notAdded,
            catalog: row.catalog,
            choices: [
              ('Add as new', PresetMergeRow.newAdjustment(row.catalog)),
              ..._mergeChoices(row.catalog),
            ],
          ),
    ];
  }

  _Entry _merged(Adjustment own, Adjustment catalog) {
    final merged = mergeAdjustment(
      own,
      catalog,
      widget.recordedValues[own.id] ?? const [],
      unknownMaxKeys: widget.unknownMaxKeys,
    );
    return _Entry(
      merged.adjustment,
      _Status.merged,
      own: own,
      catalog: catalog,
      keptOwnRange: merged.keptOwnRange,
      choices: [
        ('Separate again', PresetMergeRow.newAdjustment(catalog)),
        ("Separate, drop preset's", PresetMergeRow.notAdded(catalog)),
      ],
    );
  }

  String _summary(List<_Entry> entries) {
    if (_mode == _Mode.replace) {
      return '${_catalog.length} from the preset · ${widget.existing.length} of yours removed';
    }
    int count(_Status status) => entries.where((entry) => entry.status == status).length;
    return [
      '${count(_Status.merged)} merged',
      if (count(_Status.newAdjustment) > 0) '${count(_Status.newAdjustment)} new',
      if (count(_Status.unchanged) > 0) '${count(_Status.unchanged)} unchanged',
    ].join(' · ');
  }

  PresetMergeResult _result() => switch (_mode) {
    _Mode.merge => applyPresetMerge(
      widget.existing,
      _rows,
      widget.recordedValues,
      unknownMaxKeys: widget.unknownMaxKeys,
    ),
    _Mode.replace => replaceWithPreset(widget.existing, _catalog),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final entries = switch (_mode) {
      _Mode.merge => _mergeEntries(),
      _Mode.replace => [for (final catalog in _catalog) _Entry(catalog, _Status.newAdjustment, catalog: catalog)],
    };
    final shown = entries.where((entry) => entry.status != _Status.notAdded).toList();
    final notAdded = entries.where((entry) => entry.status == _Status.notAdded).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Merge adjustments'),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  'Your component already has adjustments. Choose how the ones of ${widget.productName} combine with them.',
                  style: muted,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Mode>(
                    segments: const [
                      ButtonSegment(value: _Mode.merge, label: Text('Merge'), icon: Icon(Icons.merge)),
                      ButtonSegment(value: _Mode.replace, label: Text('Replace'), icon: Icon(Icons.swap_horiz)),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() => _mode = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (_mode == _Mode.merge)
                  Text(
                    'Merged adjustments keep their name and recorded values and get linked to the preset. '
                    'Tap a badge to change it.',
                    style: muted,
                  )
                else
                  _ReplaceNotice(existing: widget.existing, recordedValues: widget.recordedValues),
                const SizedBox(height: 16),
                Text(
                  'Result · ${_summary(entries)}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                for (final entry in shown) _EntryCard(entry: entry, onSelected: _select),
                if (notAdded.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Not added',
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  for (final entry in notAdded) _EntryCard(entry: entry, onSelected: _select),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(_mode == _Mode.merge ? Icons.merge : Icons.swap_horiz),
              onPressed: () {
                unawaited(HapticFeedback.mediumImpact());
                Navigator.pop(context, _result());
              },
              label: Text(_mode == _Mode.merge ? 'Merge' : 'Replace'),
            ),
          ),
        ],
      ),
    );
  }
}

/// What replacing loses: recorded values of the removed adjustments stay in the
/// setups but no longer belong to an adjustment.
class _ReplaceNotice extends StatelessWidget {
  final List<Adjustment> existing;
  final Map<String, List<AdjustmentValue>> recordedValues;

  const _ReplaceNotice({required this.existing, required this.recordedValues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withValues = existing.where((a) => recordedValues[a.id]?.isNotEmpty ?? false).length;
    final valueCount = existing.fold(0, (sum, a) => sum + (recordedValues[a.id]?.length ?? 0));
    if (withValues == 0) {
      return Text(
        "Your adjustments are removed and the preset's are used instead. "
        'None of yours has recorded values yet, so nothing is lost.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(Icons.warning_amber, color: colors.onErrorContainer, size: 20),
          Expanded(
            child: Text(
              '$withValues of your adjustments ${withValues == 1 ? 'has' : 'have'} '
              '$valueCount recorded ${valueCount == 1 ? 'value' : 'values'}. '
              'Replacing removes them from this component: the values stay in your setups, '
              'but no longer belong to an adjustment. Merge keeps them.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// A result card. When its entry can change, the status badge carries a
/// chevron and opens the choices; tapping anywhere on the card opens them too.
class _EntryCard extends StatefulWidget {
  final _Entry entry;
  final ValueChanged<PresetMergeRow> onSelected;

  const _EntryCard({required this.entry, required this.onSelected});

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  final _menu = MenuController();

  _Entry get entry => widget.entry;

  void _toggleMenu() => _menu.isOpen ? _menu.close() : _menu.open();

  Widget _badge(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (entry.status) {
      _Status.merged => (colors.primaryContainer, colors.onPrimaryContainer),
      _Status.newAdjustment => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _Status.unchanged || _Status.notAdded => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    final changeable = entry.choices.isNotEmpty;
    final label = Text(
      entry.status.label,
      style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w500),
    );
    if (!changeable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
        child: label,
      );
    }
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: [
        for (final (text, row) in entry.choices)
          MenuItemButton(
            onPressed: () => widget.onSelected(row),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggleMenu,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 2, top: 3, bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                label,
                Icon(Icons.arrow_drop_down, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: color),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final own = entry.own;
    final catalog = entry.catalog;
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.titleHeight,
        leading: AdjustmentTypeIcon(entry.result),
        contentPadding: const EdgeInsets.only(left: 16, right: 12, top: 4, bottom: 4),
        onTap: entry.choices.isEmpty ? null : _toggleMenu,
        title: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                entry.result.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _badge(context),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            AdjustmentProperties(entry.result, compact: true),
            if (entry.status == _Status.merged && own != null && catalog != null)
              _line(
                context,
                Icons.merge,
                '${own.name} + ${catalog.name} (preset)',
                colors.onSurfaceVariant,
              ),
            if (entry.keptOwnRange)
              _line(
                context,
                Icons.info_outline,
                "Keeps your range: recorded values lie outside the preset's",
                colors.tertiary,
              ),
          ],
        ),
      ),
    );
    return entry.status == _Status.notAdded ? Opacity(opacity: 0.6, child: card) : card;
  }
}
