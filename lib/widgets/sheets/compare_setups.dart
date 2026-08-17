import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../repositories/app_repository.dart';
import '../../services/image_storage_service.dart';
import '../../services/setup_comparison_service.dart';
import '../../theme.dart';
import '../compare_setups/setup_comparison_header.dart';
import '../compare_setups/setup_comparison_row.dart';
import '../compare_setups/setup_comparison_section.dart';
import '../image_strip.dart';
import '../notes_text.dart';
import 'sheet.dart';

Future<void> showCompareSetupsSheet(
  BuildContext context, {
  Setup? setupA,
  required Setup setupB,
}) async {
  final repository = context.read<AppRepository>();
  final resolution = SetupComparisonService.resolveTargets(
    setupA: setupA,
    setupB: setupB,
    setups: repository.setups.values,
  );
  if (resolution is! SetupComparisonTargets) {
    final message = resolution is SetupComparisonTargetsEqualInput
        ? 'Choose two different setups to compare.'
        : 'No current setup is available to compare.';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return;
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => CompareSetups(
      setupAId: resolution.setupA.id,
      setupBId: resolution.setupB.id,
    ),
  );
}

class CompareSetups extends StatefulWidget {
  final String setupAId;
  final String setupBId;

  const CompareSetups({
    super.key,
    required this.setupAId,
    required this.setupBId,
  });

  @override
  State<CompareSetups> createState() => _CompareSetupsState();
}

class _CompareSetupsState extends State<CompareSetups> {
  bool _differencesOnly = true;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AppRepository>();
    final settings = context.watch<AppSettings>();
    final setupA = repository.setups[widget.setupAId];
    final setupB = repository.setups[widget.setupBId];
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    if (setupA == null || setupB == null) {
      return SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SheetFilterEmptyHint(
            icon: Icons.error_outline,
            title: 'A setup is no longer available',
            hint: 'Close this sheet and choose two available setups to compare.',
            onTap: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final projection = SetupComparisonService.build(
      setupA: setupA,
      setupB: setupB,
      bikes: repository.bikes.values,
      components: repository.components.values,
      persons: repository.persons.values,
      includePerson: settings.enablePerson,
      includeTags: settings.enableSetupTags,
      includeImages: settings.enableSetupImages,
      includeContext: true,
    );
    final groups = projection.visibleGroups(differencesOnly: _differencesOnly);

    return SizedBox(
      height: maxHeight,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ComparisonHeaderDelegate(
              child: SetupComparisonHeader(
                setupA: setupA,
                setupB: setupB,
                differenceCount: projection.differenceCount,
                differencesOnly: _differencesOnly,
                onDifferencesOnlyChanged: (value) {
                  setState(() => _differencesOnly = value);
                },
              ),
            ),
          ),
          if (groups.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: SheetFilterEmptyHint(
                  icon: Icons.check_circle_outline,
                  title: 'These setups have no differences',
                  hint: 'Show every recorded value instead.',
                  onTap: () => setState(() => _differencesOnly = false),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  for (final group in groups)
                    group.kind == comparison.SetupComparisonGroupKind.context
                        ? _ContextSection(
                            group: group,
                            differencesOnly: _differencesOnly,
                            setupAId: setupA.id,
                            setupBId: setupB.id,
                          )
                        : SetupComparisonSection(group: group, differencesOnly: _differencesOnly),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparisonHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ComparisonHeaderDelegate({required this.child});

  @override
  double get minExtent => 232;

  @override
  double get maxExtent => 232;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final surface = Theme.of(context).colorScheme.surface;
    return Material(color: surface, child: child);
  }

  @override
  bool shouldRebuild(_ComparisonHeaderDelegate oldDelegate) => child != oldDelegate.child;
}

class _ContextSection extends StatelessWidget {
  final comparison.SetupComparisonGroup group;
  final bool differencesOnly;
  final String setupAId;
  final String setupBId;

  const _ContextSection({
    required this.group,
    required this.differencesOnly,
    required this.setupAId,
    required this.setupBId,
  });

  @override
  Widget build(BuildContext context) {
    final rows = group.visibleRows(differencesOnly: differencesOnly);
    final notes = _row(rows, comparison.SetupComparisonRowKind.notes);
    final tags = _row(rows, comparison.SetupComparisonRowKind.tags);
    final images = _row(rows, comparison.SetupComparisonRowKind.images);
    final directRows = rows.where(
      (row) => switch (row.kind) {
        comparison.SetupComparisonRowKind.notes ||
        comparison.SetupComparisonRowKind.tags ||
        comparison.SetupComparisonRowKind.images ||
        comparison.SetupComparisonRowKind.location ||
        comparison.SetupComparisonRowKind.conditions => false,
        _ => true,
      },
    );
    final showNotesTags = _hasVisibleNotesOrTags(notes, tags);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Text(group.label, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final row in directRows) SetupComparisonRow(groupId: group.ownerId, row: row),
            if (showNotesTags) _NotesAndTags(notes: notes, tags: tags),
            if (images != null) _ComparisonImages(row: images, setupAId: setupAId, setupBId: setupBId),
            for (final row in rows.where(
              (row) =>
                  row.kind == comparison.SetupComparisonRowKind.location ||
                  row.kind == comparison.SetupComparisonRowKind.conditions,
            ))
              _ContextDisclosure(groupId: group.ownerId, row: row, differencesOnly: differencesOnly),
          ],
        ),
      ),
    );
  }

  comparison.SetupComparisonRow? _row(
    Iterable<comparison.SetupComparisonRow> rows,
    comparison.SetupComparisonRowKind kind,
  ) {
    for (final row in rows) {
      if (row.kind == kind) return row;
    }
    return null;
  }

  bool _hasVisibleNotesOrTags(
    comparison.SetupComparisonRow? notes,
    comparison.SetupComparisonRow? tags,
  ) {
    if (differencesOnly) return notes != null || tags != null;
    return _hasContent(notes) || _hasContent(tags);
  }

  bool _hasContent(comparison.SetupComparisonRow? row) {
    if (row == null) return false;
    final values = [row.valueA.value, row.valueB.value];
    return values.any((value) => value is String ? value.trim().isNotEmpty : value is Iterable && value.isNotEmpty);
  }
}

class _NotesAndTags extends StatelessWidget {
  final comparison.SetupComparisonRow? notes;
  final comparison.SetupComparisonRow? tags;

  const _NotesAndTags({required this.notes, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (notes?.isDifferent ?? false) || (tags?.isDifferent ?? false)
          ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
          : null,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes & tags'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NotesAndTagsPanel(notes: notes?.valueA.value as String?, tags: tags?.valueA.value),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NotesAndTagsPanel(notes: notes?.valueB.value as String?, tags: tags?.valueB.value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesAndTagsPanel extends StatelessWidget {
  final String? notes;
  final dynamic tags;

  const _NotesAndTagsPanel({required this.notes, required this.tags});

  @override
  Widget build(BuildContext context) {
    final Object? rawTags = tags;
    final tagValues = rawTags is Iterable ? rawTags.cast<String>() : const <String>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notes?.trim().isNotEmpty ?? false) NotesText(notes!, maxLines: 10) else const Text('No notes'),
          if (tagValues.isNotEmpty) ...[
            if (notes?.trim().isNotEmpty ?? false) const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final tag in tagValues) Chip(avatar: const Icon(Icons.tag, size: 14), label: Text(tag))],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonImages extends StatelessWidget {
  final comparison.SetupComparisonRow row;
  final String setupAId;
  final String setupBId;

  const _ComparisonImages({required this.row, required this.setupAId, required this.setupBId});

  @override
  Widget build(BuildContext context) {
    final imagesA = (row.valueA.value as List?)?.cast<String>() ?? const <String>[];
    final imagesB = (row.valueB.value as List?)?.cast<String>() ?? const <String>[];
    return Container(
      color: row.isDifferent ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<String>(
        future: ImageStorageService().getImagesPath(),
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Images'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _imageSide(context, imagesA, snapshot.data, 'compare-$setupAId-a')),
                const SizedBox(width: 8),
                Expanded(child: _imageSide(context, imagesB, snapshot.data, 'compare-$setupBId-b')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSide(BuildContext context, List<String> images, String? path, String prefix) {
    if (path == null || images.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('No images'),
      );
    }
    return ImageStrip(images: images, imagesDir: path, heroTagPrefix: prefix);
  }
}

class _ContextDisclosure extends StatelessWidget {
  final String groupId;
  final comparison.SetupComparisonRow row;
  final bool differencesOnly;

  const _ContextDisclosure({required this.groupId, required this.row, required this.differencesOnly});

  @override
  Widget build(BuildContext context) {
    final children = row.children.where((child) => !differencesOnly || child.isDifferent).toList();
    if (children.isEmpty) return const SizedBox.shrink();
    final summary = row.kind == comparison.SetupComparisonRowKind.location
        ? row.children.firstWhere((child) => child.id == 'address')
        : row.children.firstWhere((child) => child.id == 'weather-code');
    return ExpansionTile(
      key: Key('compare-disclosure-${row.id}'),
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(
        row.kind == comparison.SetupComparisonRowKind.location ? Icons.location_city : Icons.cloud_outlined,
      ),
      title: _DisclosureTitle(label: row.label, summary: summary),
      children: [for (final child in children) SetupComparisonRow(groupId: '$groupId-${row.id}', row: child)],
    );
  }
}

class _DisclosureTitle extends StatelessWidget {
  final String label;
  final comparison.SetupComparisonRow summary;

  const _DisclosureTitle({required this.label, required this.summary});

  @override
  Widget build(BuildContext context) {
    String text(comparison.SetupComparisonSideValue value) => value.isRecorded ? '${value.value}' : 'Not recorded';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(child: Text(text(summary.valueA), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(child: Text(text(summary.valueB), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }
}
