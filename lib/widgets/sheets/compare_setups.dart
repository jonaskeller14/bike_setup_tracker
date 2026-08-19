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
import '../items/rating_summary_card_diff.dart';
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

  PinnedHeaderSliver _sectionTitle(BuildContext context, String title, {Widget? trailing}) {
    return PinnedHeaderSliver(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SectionTitle(title: title, trailing: trailing),
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
        .toList(growable: false);
    final allValueGroups = projection.groups
        .where((group) => group.kind != comparison.SetupComparisonGroupKind.context)
        .where((group) => group.rows.isNotEmpty || group.isStructuralDifference)
        .toList(growable: false);
    final valueGroups = allValueGroups
        .where((group) => !_differencesOnly || group.isDifferent)
        .toList(growable: false);
    final valueDifferenceCount = allValueGroups.fold(0, (count, group) => count + group.differenceCount);
    final contextHasChanged = contextGroups.any((group) => group.isDifferent);
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
    final hasVisibleRatings = settings.enableRating;

    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SetupComparisonHeader(
          onRestoreB: setupB.isCurrent ? null : () => _restoreSetupB(setupB),
        ),
        SliverToBoxAdapter(
          child: SetupComparisonSummary(
            setupA: setupA,
            setupB: setupB,
          ),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverMainAxisGroup(
            slivers: [
              if (contextGroups.isNotEmpty)
                SliverMainAxisGroup(
                  slivers: [
                    _sectionTitle(
                      context,
                      'Context',
                      trailing: contextHasChanged ? const _ContextChangedBadge() : null,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverList.list(
                        children: [
                          for (final group in contextGroups)
                            _ContextSection(
                              group: group,
                              setupA: setupA,
                              setupB: setupB,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(child: Divider(height: 8)),
                  _sectionTitle(
                    context,
                    'Values',
                    trailing: _ValueFilter(
                      differenceCount: valueDifferenceCount,
                      differencesOnly: _differencesOnly,
                      onChanged: (value) => setState(() => _differencesOnly = value),
                    ),
                  ),
                  if (valueGroups.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: SheetFilterEmptyHint(
                          icon: Icons.check_circle_outline,
                          title: _differencesOnly ? 'These setups have no value differences' : 'No comparable values',
                          hint: _differencesOnly
                              ? 'Show every recorded value instead.'
                              : 'No setup values are available to compare.',
                          onTap: _differencesOnly ? () => setState(() => _differencesOnly = false) : null,
                        ),
                      ),
                    )
                  else
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
                        child: RatingSummaryCardDiff(
                          ratingsA: ratingsA,
                          ratingsB: ratingsB,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContextChangedBadge extends StatelessWidget {
  const _ContextChangedBadge();

  @override
  Widget build(BuildContext context) {
    final changedColor = Theme.of(context).extension<ValueHighlightColors>()!.changed;
    return Semantics(
      label: 'Context varies',
      excludeSemantics: true,
      child: Container(
        key: const Key('compare-context-changed-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: changedColor.withValues(alpha: 0.08),
          border: Border.all(color: changedColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Context varies',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: changedColor),
        ),
      ),
    );
  }
}

class _ValueFilter extends StatelessWidget {
  final int differenceCount;
  final bool differencesOnly;
  final ValueChanged<bool> onChanged;

  const _ValueFilter({
    required this.differenceCount,
    required this.differencesOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      key: const Key('compare-filter-control'),
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: true,
          label: Text('Differences ($differenceCount)'),
        ),
        const ButtonSegment(value: false, label: Text('All')),
      ],
      selected: {differencesOnly},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

class _ContextSection extends StatelessWidget {
  final comparison.SetupComparisonGroup group;
  final Setup setupA;
  final Setup setupB;

  const _ContextSection({
    required this.group,
    required this.setupA,
    required this.setupB,
  });

  @override
  Widget build(BuildContext context) {
    final rows = group.rows;
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
          ),
        if (conditions != null && (setupA.weather != null || setupB.weather != null))
          ContextWeatherCardDiff(
            weatherA: setupA.weather,
            weatherB: setupB.weather,
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
