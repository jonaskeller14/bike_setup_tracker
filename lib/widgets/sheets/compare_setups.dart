import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../repositories/app_repository.dart';
import '../../services/image_storage_service.dart';
import '../../services/setup_comparison_service.dart';
import '../../theme.dart';
import '../../utils/setup_actions.dart';
import '../compare_setups/setup_comparison_header.dart';
import '../compare_setups/setup_comparison_owner_card.dart';
import '../compare_setups/setup_comparison_row.dart';
import '../image_strip.dart';
import '../notes_text.dart';
import '../text/section_title.dart';
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

  Future<void> _restoreSetupB(Setup setupB) async {
    final restored = await SetupActions.duplicateSetup(context, setup: setupB);
    if (restored != null && mounted) Navigator.pop(context);
  }

  PinnedHeaderSliver _sectionTitle(BuildContext context, String title) {
    return PinnedHeaderSliver(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SectionTitle(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AppRepository>();
    final settings = context.watch<AppSettings>();
    final setupA = repository.setups[widget.setupAId];
    final setupB = repository.setups[widget.setupBId];

    if (setupA == null || setupB == null) {
      return CustomScrollView(
        slivers: [
          const SetupComparisonHeader(),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: SheetFilterEmptyHint(
                  icon: Icons.error_outline,
                  title: 'A setup is no longer available',
                  hint: 'Close this sheet and choose two available setups to compare.',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
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
    final contextGroups = projection.groups
        .where((group) => group.kind == comparison.SetupComparisonGroupKind.context)
        .where((group) => !_differencesOnly || group.isDifferent)
        .toList(growable: false);
    final valueGroups = projection.groups
        .where((group) => group.kind != comparison.SetupComparisonGroupKind.context)
        .where((group) => group.rows.isNotEmpty || group.isStructuralDifference)
        .where((group) => !_differencesOnly || group.isDifferent)
        .toList(growable: false);
    final ratingsA = comparison.SetupComparisonRatingSummary(
      entryCount: repository.ratingEntriesForSetup(setupA.id).length,
      score: repository.scoreForSetup(setupA.id),
      metricScores: repository.metricScoresForSetup(setupA.id),
      metrics: repository.allRatingMetricsById,
    );
    final ratingsB = comparison.SetupComparisonRatingSummary(
      entryCount: repository.ratingEntriesForSetup(setupB.id).length,
      score: repository.scoreForSetup(setupB.id),
      metricScores: repository.metricScoresForSetup(setupB.id),
      metrics: repository.allRatingMetricsById,
    );
    final hasVisibleRatings =
        settings.enableRating && (!_differencesOnly || ratingsA.entryCount != 0 || ratingsB.entryCount != 0);
    final hasVisibleContent = contextGroups.isNotEmpty || valueGroups.isNotEmpty || hasVisibleRatings;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SetupComparisonHeader(
            onRestoreB: setupB.isCurrent ? null : () => _restoreSetupB(setupB),
          ),
          SliverToBoxAdapter(
            child: SetupComparisonSummary(
              setupA: setupA,
              setupB: setupB,
              differenceCount: projection.differenceCount,
              differencesOnly: _differencesOnly,
              onDifferencesOnlyChanged: (value) {
                setState(() => _differencesOnly = value);
              },
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: !hasVisibleContent
                ? SliverPadding(
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
                : SliverMainAxisGroup(
                    slivers: [
                      if (contextGroups.isNotEmpty)
                        SliverMainAxisGroup(
                          slivers: [
                            _sectionTitle(context, 'Context'),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              sliver: SliverList.list(
                                children: [
                                  for (final group in contextGroups)
                                    _ContextSection(
                                      group: group,
                                      differencesOnly: _differencesOnly,
                                      setupAId: setupA.id,
                                      setupBId: setupB.id,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (valueGroups.isNotEmpty)
                        SliverMainAxisGroup(
                          slivers: [
                            const SliverToBoxAdapter(child: Divider(height: 8)),
                            _sectionTitle(context, 'Values'),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              sliver: SliverList.list(
                                children: [
                                  for (final group in valueGroups)
                                    SetupComparisonOwnerCard(
                                      group: group,
                                      differencesOnly: _differencesOnly,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (hasVisibleRatings)
                        SliverMainAxisGroup(
                          slivers: [
                            const SliverToBoxAdapter(child: Divider(height: 8)),
                            _sectionTitle(context, 'Ratings'),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              sliver: SliverToBoxAdapter(
                                child: _RatingsSection(
                                  ratingsA: ratingsA,
                                  ratingsB: ratingsB,
                                  differencesOnly: _differencesOnly,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RatingsSection extends StatelessWidget {
  final comparison.SetupComparisonRatingSummary ratingsA;
  final comparison.SetupComparisonRatingSummary ratingsB;
  final bool differencesOnly;

  const _RatingsSection({required this.ratingsA, required this.ratingsB, required this.differencesOnly});

  String _score(double? score) => score == null ? '– / 10' : '${score.toStringAsFixed(1)} / 10';

  bool get _scoresDiffer => ratingsA.score?.toStringAsFixed(1) != ratingsB.score?.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final noRatings = ratingsA.entryCount == 0 && ratingsB.entryCount == 0;
    if (differencesOnly && noRatings) return const SizedBox.shrink();
    final metricIds = {...ratingsA.metricScores.keys, ...ratingsB.metricScores.keys}.toList()..sort();
    final scoresDiffer = _scoresDiffer || ratingsA.entryCount != ratingsB.entryCount;
    final delta = ratingsA.score != null && ratingsB.score != null ? ratingsB.score! - ratingsA.score! : null;
    return Semantics(
      container: true,
      label: 'Ratings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: scoresDiffer ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _RatingValue(label: 'A', score: _score(ratingsA.score), count: ratingsA.entryCount),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RatingValue(label: 'B', score: _score(ratingsB.score), count: ratingsB.entryCount),
                    ),
                  ],
                ),
                if (delta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Δ ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (noRatings) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No ratings yet')),
                if (metricIds.isNotEmpty)
                  ExpansionTile(
                    title: const Text('Metric breakdown'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      for (final id in metricIds) _MetricRow(id: id, ratingsA: ratingsA, ratingsB: ratingsB),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingValue extends StatelessWidget {
  final String label;
  final String score;
  final int count;

  const _RatingValue({required this.label, required this.score, required this.count});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label overall $score from $count rating${count == 1 ? '' : 's'}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('$label: $score'), Text('$count rating${count == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall)],
    ),
  );
}

class _MetricRow extends StatelessWidget {
  final String id;
  final comparison.SetupComparisonRatingSummary ratingsA;
  final comparison.SetupComparisonRatingSummary ratingsB;

  const _MetricRow({required this.id, required this.ratingsA, required this.ratingsB});

  @override
  Widget build(BuildContext context) {
    final scoreA = ratingsA.metricScores[id];
    final scoreB = ratingsB.metricScores[id];
    final metric = ratingsA.metrics[id] ?? ratingsB.metrics[id];
    final label = metric?.adjustment.name ?? 'Metric unavailable ($id)';
    final weight = metric?.weight.abs();
    final displayedA = scoreA?.toStringAsFixed(1) ?? '–';
    final displayedB = scoreB?.toStringAsFixed(1) ?? '–';
    final different = displayedA != displayedB || (ratingsA.metrics.containsKey(id) != ratingsB.metrics.containsKey(id));
    return Semantics(
      label: '$label, A $displayedA / 10, B $displayedB / 10${different ? ', different' : ''}',
      child: Container(
        color: different ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill : null,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
            Text('$displayedA / 10'),
            const SizedBox(width: 8),
            Text('$displayedB / 10'),
            if (weight != null) ...[
              const SizedBox(width: 8),
              Text('×${weight == weight.roundToDouble() ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1)}'),
            ],
          ],
        ),
      ),
    );
  }
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
