import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_place.dart';
import '../../models/context/context_position.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/app_hint_service.dart';
import '../../services/setup_comparison_service.dart';
import '../../theme.dart';
import '../app_snackbar.dart';
import '../compare_setups/setup_comparison_header.dart';
import '../compare_setups/setup_comparison_owner_card.dart';
import '../hints/app_hint_slot.dart';
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
    messenger.showSnackBar(AppSnackBar.info(context, message));
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
  late String _setupAId;
  late String _setupBId;
  String? _comparisonBikeId;

  @override
  void initState() {
    super.initState();
    _setupAId = widget.setupAId;
    _setupBId = widget.setupBId;
    final setups = context.read<AppRepository>().setups;
    final setupA = setups[_setupAId];
    final setupB = setups[_setupBId];
    if (setupA != null && setupA.bike == setupB?.bike) {
      _comparisonBikeId = setupA.bike;
    }
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
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final setupA = appRepository.setups[_setupAId];
    final setupB = appRepository.setups[_setupBId];

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
      components: appRepository.components.values,
      persons: appRepository.persons.values,
    );
    final allValueGroups = projection.groups
        .where((group) => group.rows.isNotEmpty || group.isStructuralDifference)
        .toList(growable: false);
    final valueGroups = allValueGroups.where((group) => !_differencesOnly || group.isDifferent).toList(growable: false);
    final valueDifferenceCount = allValueGroups.fold(0, (count, group) => count + group.differenceCount);
    final contextHasChanged = _contextHasChanged(setupA, setupB, appSettings);
    final ratingsA = RatingSummaryData(
      entryCount: appRepository.ratingEntriesForSetup(setupA.id).length,
      score: appRepository.scoreForSetup(setupA.id),
      metricScores: appRepository.metricScoresForSetup(setupA.id),
      metrics: appRepository.allRatingMetricsById,
    );
    final ratingsB = RatingSummaryData(
      entryCount: appRepository.ratingEntriesForSetup(setupB.id).length,
      score: appRepository.scoreForSetup(setupB.id),
      metricScores: appRepository.metricScoresForSetup(setupB.id),
      metrics: appRepository.allRatingMetricsById,
    );
    final hasVisibleRatings = appSettings.enableRating;
    final selectableSetups = _comparisonBikeId == null
        ? appRepository.setups.values
        : appRepository.setups.values.where((setup) => setup.bike == _comparisonBikeId);
    final showComparisonHint = context.select<AppHintService, bool>(
      (hintService) => hintService.activeHintFor(AppHintPlacement.setupComparison) != null,
    );
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        const SetupComparisonHeader(),
        SetupComparisonIdentities(
          setupA: setupA,
          setupB: setupB,
          setups: selectableSetups,
          showBikeNames: _comparisonBikeId == null,
          bikeNamesById: appRepository.bikes.map((id, bike) => MapEntry(id, bike.name)),
          onSetupAChanged: (setup) => setState(() => _setupAId = setup.id),
          onSetupBChanged: (setup) => setState(() => _setupBId = setup.id),
        ),
        if (showComparisonHint)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: AppHintSlot(placement: AppHintPlacement.setupComparison),
            ),
          ),
        SliverSafeArea(
          top: false,
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverMainAxisGroup(
                slivers: [
                  _sectionTitle(
                    context,
                    'Context',
                    trailing: contextHasChanged ? const _ContextChangedBadge() : null,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _ContextSection(
                        setupA: setupA,
                        setupB: setupB,
                        settings: appSettings,
                      ),
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

  bool _contextHasChanged(Setup a, Setup b, AppSettings settings) {
    return a.bike != b.bike ||
        (settings.enablePerson && a.person != b.person) ||
        a.notes != b.notes ||
        (settings.enableSetupTags && !setEquals(a.tags, b.tags)) ||
        (settings.enableSetupImages && !listEquals(a.images, b.images)) ||
        !ContextPosition.equal(a.position, b.position) ||
        !ContextPlace.equal(a.place, b.place) ||
        _visibleWeatherValues(a) != _visibleWeatherValues(b);
  }

  Object? _visibleWeatherValues(Setup setup) {
    final weather = setup.weather;
    if (weather == null) return null;
    return (
      weather.currentWeatherCode,
      weather.condition,
      weather.currentTemperature,
      weather.dayAccumulatedPrecipitation,
      weather.currentHumidity,
      weather.currentWindSpeed,
      weather.currentSoilMoisture0to7cm,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: changedColor.withValues(alpha: 0.08),
          border: Border.all(color: changedColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Context varies',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: changedColor),
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
  final Setup setupA;
  final Setup setupB;
  final AppSettings settings;

  const _ContextSection({
    required this.setupA,
    required this.setupB,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContextMetaCardDiff(
          notesA: setupA.notes,
          tagsA: settings.enableSetupTags ? setupA.tags : const {},
          imagesA: settings.enableSetupImages ? setupA.images : const [],
          notesB: setupB.notes,
          tagsB: settings.enableSetupTags ? setupB.tags : const {},
          imagesB: settings.enableSetupImages ? setupB.images : const [],
        ),
        ContextLocationCardDiff(
          positionA: setupA.position,
          placeA: setupA.place,
          positionB: setupB.position,
          placeB: setupB.place,
        ),
        ContextWeatherCardDiff(
          weatherA: setupA.weather,
          weatherB: setupB.weather,
        ),
        ContextBikePersonCardDiff(
          setupA: setupA,
          setupB: setupB,
          showBike: true,
          showPerson: settings.enablePerson && (setupA.person != null || setupB.person != null),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
