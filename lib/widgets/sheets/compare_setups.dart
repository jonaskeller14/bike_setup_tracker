import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../repositories/app_repository.dart';
import '../../services/setup_comparison_service.dart';
import '../../theme.dart';
import '../../utils/setup_actions.dart';
import '../compare_setups/setup_comparison_header.dart';
import '../compare_setups/setup_comparison_owner_card.dart';
import '../items/context_bike_person_card_diff.dart';
import '../items/context_location_card_diff.dart';
import '../items/context_meta_card_diff.dart';
import '../items/context_weather_card_diff.dart';
import '../text/section_title.dart';
import 'sheet.dart';

Future<void> showCompareSetupsSheet(
  BuildContext context, {
  Setup? setupA,
  required Setup setupB,
}) async {
  final appRepository = context.read<AppRepository>();
  final resolution = SetupComparisonService.resolveTargets(
    setupA: setupA,
    setupB: setupB,
    setups: appRepository.setups.values,
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
    useSafeArea: true,
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
        shrinkWrap: true,
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
        shrinkWrap: true,
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
                                      setupA: setupA,
                                      setupB: setupB,
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
    final changedColor = scoresDiffer ? Theme.of(context).extension<ValueHighlightColors>()!.changed : null;
    return Semantics(
      container: true,
      label: 'Ratings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: changedColor),
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
      children: [
        Text('$label: $score'),
        Text('$count rating${count == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall),
      ],
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
    final different =
        displayedA != displayedB || (ratingsA.metrics.containsKey(id) != ratingsB.metrics.containsKey(id));
    final changedColor = different ? Theme.of(context).extension<ValueHighlightColors>()!.changed : null;
    return Semantics(
      label: '$label, A $displayedA / 10, B $displayedB / 10${different ? ', different' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: changedColor),
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
      ),
    );
  }
}

class _ContextSection extends StatelessWidget {
  final comparison.SetupComparisonGroup group;
  final bool differencesOnly;
  final Setup setupA;
  final Setup setupB;

  const _ContextSection({
    required this.group,
    required this.differencesOnly,
    required this.setupA,
    required this.setupB,
  });

  @override
  Widget build(BuildContext context) {
    final rows = group.visibleRows(differencesOnly: differencesOnly);
    final notes = _row(rows, comparison.SetupComparisonRowKind.notes);
    final tags = _row(rows, comparison.SetupComparisonRowKind.tags);
    final images = _row(rows, comparison.SetupComparisonRowKind.images);
    final bike = _row(rows, comparison.SetupComparisonRowKind.bike);
    final person = _row(rows, comparison.SetupComparisonRowKind.person);
    final location = _row(rows, comparison.SetupComparisonRowKind.location);
    final conditions = _row(rows, comparison.SetupComparisonRowKind.conditions);
    final showMeta = _hasVisibleMeta(notes, tags, images);
    return Column(
      children: [
        if (showMeta)
          ContextMetaCardDiff(
            notesA: notes?.valueA.value as String?,
            tagsA: _stringSet(tags?.valueA.value),
            imagesA: _stringList(images?.valueA.value),
            notesB: notes?.valueB.value as String?,
            tagsB: _stringSet(tags?.valueB.value),
            imagesB: _stringList(images?.valueB.value),
          ),
        if (location != null &&
            (setupA.position != null || setupA.place != null || setupB.position != null || setupB.place != null))
          ContextLocationCardDiff(
            positionA: setupA.position,
            placeA: setupA.place,
            positionB: setupB.position,
            placeB: setupB.place,
            differencesOnly: differencesOnly,
          ),
        if (conditions != null && (setupA.weather != null || setupB.weather != null))
          ContextWeatherCardDiff(
            weatherA: setupA.weather,
            weatherB: setupB.weather,
            differencesOnly: differencesOnly,
          ),
        if (bike != null || person != null)
          ContextBikePersonCardDiff(
            setupA: setupA,
            setupB: setupB,
            showBike: bike != null,
            showPerson: person != null,
          ),
        const SizedBox(height: 8),
      ],
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

  bool _hasVisibleMeta(
    comparison.SetupComparisonRow? notes,
    comparison.SetupComparisonRow? tags,
    comparison.SetupComparisonRow? images,
  ) {
    if (differencesOnly) return notes != null || tags != null || images != null;
    return _hasContent(notes) || _hasContent(tags) || _hasContent(images);
  }

  bool _hasContent(comparison.SetupComparisonRow? row) {
    if (row == null) return false;
    final values = [row.valueA.value, row.valueB.value];
    return values.any((value) => value is String ? value.trim().isNotEmpty : value is Iterable && value.isNotEmpty);
  }

  Set<String> _stringSet(dynamic value) => value is Iterable ? value.cast<String>().toSet() : const {};

  List<String> _stringList(dynamic value) => value is Iterable ? value.cast<String>().toList() : const [];
}
