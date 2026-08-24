import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/dangling_adjustment_service.dart';
import '../../services/setup_comparison_service.dart';
import '../../utils/setup_actions.dart';
import '../../widgets/current_setup_badge.dart';
import '../../widgets/current_setup_highlight.dart';
import '../../widgets/display_adjustment/display_adjustment_list.dart';
import '../../widgets/display_adjustment/display_dangling_adjustment.dart';
import '../../widgets/empty_state_placeholder2.dart';
import '../../widgets/initial_changed_value_legend.dart';
import '../../widgets/items/card_header_tile.dart';
import '../../widgets/items/context_bike_person_card.dart';
import '../../widgets/items/context_location_card.dart';
import '../../widgets/items/context_meta_card.dart';
import '../../widgets/items/context_weather_card.dart';
import '../../widgets/items/rating_summary_card.dart';
import '../../widgets/map_pins.dart';
import '../../widgets/sheets/compare_setups.dart';
import '../../widgets/sheets/sheet.dart';
import '../../widgets/text/section_title.dart';

class SetupDetailsPage extends StatefulWidget {
  final List<String> setupIds;
  final Setup? initialSetup;

  const SetupDetailsPage({
    super.key, 
    required this.setupIds,
    this.initialSetup,
  });

  @override
  State<SetupDetailsPage> createState() => _SetupDetailsPageState();
}

class _SetupDetailsPageState extends State<SetupDetailsPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialSetup != null) _currentPageIndex = widget.setupIds.indexOf(widget.initialSetup!.id);
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  double _currentTint(List<Setup?> setups) {
    final double page = _pageController.hasClients && _pageController.position.hasContentDimensions
        ? (_pageController.page ?? _currentPageIndex.toDouble())
        : _currentPageIndex.toDouble();

    double tintAt(int index) =>
        (setups[index.clamp(0, setups.length - 1)]?.isCurrent ?? false) ? 1 : 0;

    final double t = page - page.floorToDouble();
    return tintAt(page.floor()) * (1 - t) + tintAt(page.ceil()) * t;
  }

  Row _navigationRow(int index) {
    final bool isSmallScreen = MediaQuery.sizeOf(context).width < 360;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (isSmallScreen)
          IconButton(
            onPressed: index > 0 
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_back),
            color: Theme.of(context).colorScheme.primary,
          )
        else
          TextButton.icon(
            onPressed: index > 0 
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Prev"),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),

        Text(
          "${index + 1} / ${widget.setupIds.length}",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),

        if (isSmallScreen)
          IconButton(
            onPressed: index < widget.setupIds.length - 1 
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_forward),
            color: Theme.of(context).colorScheme.primary,
          )
        else
          TextButton.icon(
            onPressed: index < widget.setupIds.length - 1 
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ) 
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Next"),
            iconAlignment: IconAlignment.end,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final List<Setup?> setups = widget.setupIds.map((setupId) => appRepository.setups[setupId]).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: AnimatedBuilder(
          animation: _pageController,
          builder: (context, _) => Container(
            color: Theme.of(context).colorScheme.primary.withValues(
              alpha: CurrentSetupHighlight.fillAlpha * _currentTint(setups),
            ),
          ),
        ),
        title: _navigationRow(_currentPageIndex),
        actions: [
          IconButton(
            onPressed: () => SetupActions.editSetup(context, setup: setups[_currentPageIndex]!), 
            icon: const Icon(Icons.edit),
          )
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        itemCount: setups.length,
        itemBuilder: (context, index) {
          final Setup? setup = setups[index];
          if (setup == null) return const Expanded(child: Center(child: Text("Setup not found.")));

          return SetupDetailsPageContent(setup: setup);
        },
      )
    );
  }
}

class SetupDetailsPageContent extends StatelessWidget {
  final Setup setup;
  final bool showSheetActions;
  final bool showCloseButton;

  const SetupDetailsPageContent({super.key, required this.setup, this.showSheetActions = false, this.showCloseButton = false});

  Future<void> _onSheetAction(BuildContext context, _SetupDetailsAction action) async {
    switch (action) {
      case _SetupDetailsAction.edit:
        await SetupActions.editSetup(context, setup: setup);
      case _SetupDetailsAction.restore:
        final restored = await SetupActions.duplicateSetup(context, setup: setup);
        if (restored != null && context.mounted) Navigator.pop(context);
      case _SetupDetailsAction.compare:
        await showCompareSetupsSheet(context, setupA: null, setupB: setup);
    }
  }

  Widget _sheetActions(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final setups = context.read<AppRepository>().setups.values;
    final canCompare = settings.enableSetupComparison &&
        SetupComparisonService.resolveTargets(setupB: setup, setups: setups) is SetupComparisonTargets;
    final actions = <_SetupDetailsAction>[
      _SetupDetailsAction.edit,
      //TODO: add "add rating" and "remove" ?
      if (!setup.isCurrent) _SetupDetailsAction.restore,
      if (canCompare) _SetupDetailsAction.compare,
    ];
    return PopupMenuButton<_SetupDetailsAction>(
      tooltip: 'Setup actions',
      onSelected: (action) => _onSheetAction(context, action),
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: Row(spacing: 10, children: [Icon(action.icon), Text(action.label)]),
          ),
      ],
      child: AbsorbPointer(
        child: IconButton.filled(
          iconSize: 20,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  SliverAppBar _setupTitle(BuildContext context, {required Setup setup}) {
    final appSettings = context.read<AppSettings>();
    final colorScheme = Theme.of(context).colorScheme;
    final Color background = setup.isCurrent
        ? CurrentSetupHighlight.opaqueFill(colorScheme)
        : colorScheme.surface;

    return SliverAppBar(
      pinned: true,
      expandedHeight: null,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      backgroundColor: background,
      surfaceTintColor: background,
      centerTitle: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SelectableText(
                        setup.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                      ),
                    ),
                    if (setup.isCurrent) ...[
                      const SizedBox(width: 8),
                      const CurrentSetupBadge(),
                    ],
                  ],
                ),
                Text(
                  "${DateFormat(appSettings.dateFormat).format(setup.datetimeLocal)} • ${DateFormat(appSettings.timeFormat).format(setup.datetimeLocal)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (showSheetActions || showCloseButton)
            const SizedBox(width: 12),
          if (showSheetActions) _sheetActions(context),
          if (showCloseButton)
            sheetCloseButton(context),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1),
      ),
    );
  }

  PinnedHeaderSliver _sectionTitle(BuildContext context, {required String title}) {
    final colorScheme = Theme.of(context).colorScheme;

    return PinnedHeaderSliver(
      child: Container(
        color: setup.isCurrent
            ? CurrentSetupHighlight.opaqueFill(colorScheme)
            : colorScheme.surface,
        child: SectionTitle(title: title),
      ),
    );
  }

  SliverToBoxAdapter _contextSection(BuildContext context, {required Setup setup, required Bike? bike, required Person? person}) {
    final appSettings = context.watch<AppSettings>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContextMetaCard(
              notes: setup.notes,
              tags: appSettings.enableSetupTags ? setup.tags : const {},
              images: appSettings.enableSetupImages ? setup.images : const [],
            ),
            ContextLocationCard(position: setup.position, place: setup.place, displayName: setup.displayName, mapPin: SetupMapPin.icon(isCurrent: setup.isCurrent)),
            ContextWeatherCard(weather: setup.weather),
            ContextBikePersonCard(
              bike: bike,
              person: person,
              personLinked: setup.person != null,
              showPerson: appSettings.enablePerson,
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _legend(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: InitialChangedValueLegend(),
      ),
    );
  }

  Widget _errorBadgeDot(BuildContext context, {double size = 9}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: scheme.error,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.error, size: size, color: scheme.errorContainer),
    );
  }

  Widget _danglingComponentCard(BuildContext context, {required Setup setup, required DanglingComponentGroup group}) {
    final scheme = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeaderTile(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Badge(
                label: _errorBadgeDot(context),
                backgroundColor: Colors.transparent,
                largeSize: 20,
                child: Icon(group.component.componentType.getIconData(), color: scheme.error),
              ),
              title: Text(group.component.name, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
              subtitle: Text("Component was not installed at setup time", style: TextStyle(color: scheme.error)),
            ),
          ),
          AdjustmentDisplayList(
            adjustments: group.adjustments,
            initialAdjustmentValues: setup.previousBikeAdjustmentValues,
            adjustmentValues: setup.bikeAdjustmentValues,
            isError: true,
          ),
        ],
      ),
    );
  }

  Widget _danglingPersonCard(BuildContext context, {required Setup setup, required DanglingPersonGroup group}) {
    final scheme = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeaderTile(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Badge(
                label: _errorBadgeDot(context),
                backgroundColor: Colors.transparent,
                largeSize: 20,
                child: Icon(Person.iconData, color: scheme.error),
              ),
              title: Text(group.person.name, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
              subtitle: Text("Person is not linked to this setup", style: TextStyle(color: scheme.error)),
            ),
          ),
          AdjustmentDisplayList(
            adjustments: group.adjustments,
            initialAdjustmentValues: setup.previousPersonAdjustmentValues,
            adjustmentValues: setup.personAdjustmentValues,
            isError: true,
          ),
        ],
      ),
    );
  }

  Widget _danglingValuesCard(BuildContext context, {
    required Map<String, dynamic> values,
    required String title,
    required String cause,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeaderTile(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: scheme.error),
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.error)),
              subtitle: Text(cause, style: TextStyle(color: scheme.error)),
            ),
          ),
          ...values.entries.map((danglingAdjustmentValue) {
            return DisplayDanglingAdjustmentWidget(
              name: danglingAdjustmentValue.key,
              value: danglingAdjustmentValue.value,
            );
          }),
        ],
      ),
    );
  }

  SliverToBoxAdapter _valueSection(BuildContext context, {
    required Setup setup,
    required Iterable<Component> bikeComponents,
    required Person? person,
    required List<DanglingComponentGroup> danglingComponentGroups,
    required Map<String, dynamic> danglingDeletedBikeAdjustmentValues,
    required List<DanglingPersonGroup> danglingPersonGroups,
    required Map<String, dynamic> danglingDeletedPersonAdjustmentValues,
  }) {
    final appSettings = context.read<AppSettings>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bikeComponents.isEmpty)
              const EmptyStatePlaceholder2(
                iconData: Component.iconData,
                title: "No components yet",
                subtitle: "Add a component to this bike to start tracking adjustments",
              )
            else
              ...bikeComponents.map((bikeComponent) {
                return Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardHeaderTile(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        child: ListTile(
                          title: SelectableText(bikeComponent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(Intl.plural(
                            bikeComponent.adjustments.length,
                            zero: "No adjustments yet.",
                            one: "1 adjustment",
                            other: '${bikeComponent.adjustments.length} adjustments',
                          )),
                          leading: Icon(bikeComponent.componentType.getIconData()),
                          enabled: bikeComponent.adjustments.isNotEmpty,
                        ),
                      ),
                      AdjustmentDisplayList(
                        adjustments: bikeComponent.adjustments,
                        initialAdjustmentValues: setup.previousBikeAdjustmentValues,
                        adjustmentValues: setup.bikeAdjustmentValues,
                      ),
                    ],
                  ),
                );
              }),
            ...danglingComponentGroups.map((group) => _danglingComponentCard(context, setup: setup, group: group)),
            if (danglingDeletedBikeAdjustmentValues.isNotEmpty)
              _danglingValuesCard(
                context,
                values: danglingDeletedBikeAdjustmentValues,
                title: "Dangling Adjustment Values",
                cause: "Component with adjustment was deleted",
              ),
            if (appSettings.enablePerson) ...[
              if (person != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardHeaderTile(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        child: ListTile(
                          title: SelectableText(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(Intl.plural(
                            person.adjustments.length,
                            zero: "No attributes yet.",
                            one: "1 attribute",
                            other: '${person.adjustments.length} attributes',
                          )),
                          leading: const Icon(Person.iconData),
                          enabled: person.adjustments.isNotEmpty,
                        ),
                      ),
                      AdjustmentDisplayList(
                        adjustments: person.adjustments,
                        initialAdjustmentValues: setup.previousPersonAdjustmentValues,
                        adjustmentValues: setup.personAdjustmentValues,
                      ),
                    ],
                  ),
                ),
              ...danglingPersonGroups.map((group) => _danglingPersonCard(context, setup: setup, group: group)),
              if (danglingDeletedPersonAdjustmentValues.isNotEmpty)
                _danglingValuesCard(
                  context,
                  values: danglingDeletedPersonAdjustmentValues,
                  title: "Dangling Attribute Values",
                  cause: "Attribute was deleted",
                ),
            ],
          ],
        )
      ),
    );
  }

  SliverToBoxAdapter _ratingEntriesSection(BuildContext context, {required Setup setup}) {
    final appRepository = context.watch<AppRepository>();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: RatingSummaryCard(
          entryCount: appRepository.ratingEntriesForSetup(setup.id).length,
          score: appRepository.scoreForSetup(setup.id),
          metricScores: appRepository.metricScoresForSetup(setup.id),
          metrics: appRepository.allRatingMetricsById,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final colorScheme = Theme.of(context).colorScheme;
    final bikes = appRepository.bikes;
    final persons = appRepository.persons;
    final components = appRepository.components;

    final Bike? bike = bikes[setup.bike];

    final breakdown = DanglingAdjustmentService.analyzeSetup(
      setup: setup,
      components: components.values,
      persons: persons.values,
    );
    final Iterable<Component> bikeComponents = breakdown.components;
    final Person? person = breakdown.person;
    final componentSplit = breakdown.componentSplit;
    final personSplit = breakdown.personSplit;

    return ColoredBox(
      color: setup.isCurrent
          ? CurrentSetupHighlight.opaqueFill(colorScheme)
          : colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          _setupTitle(context, setup: setup),
          SliverSafeArea(
            top: false,
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverMainAxisGroup(
                  slivers: [
                    _sectionTitle(context, title: "Context"),
                    _contextSection(context, setup: setup, bike: bike, person: person),
                  ],
                ),
                SliverMainAxisGroup(
                  slivers: [
                    const SliverToBoxAdapter(child: Divider(height: 8)),
                    _sectionTitle(context, title: "Values"),
                    _valueSection(
                      context,
                      setup: setup,
                      person: person,
                      bikeComponents: bikeComponents,
                      danglingComponentGroups: componentSplit.groups,
                      danglingDeletedBikeAdjustmentValues: componentSplit.deletedValues,
                      danglingPersonGroups: personSplit.groups,
                      danglingDeletedPersonAdjustmentValues: personSplit.deletedValues,
                    ),
                    _legend(context),
                  ]
                ),
                if (appSettings.enableRating)
                  SliverMainAxisGroup(
                    slivers: [
                      const SliverToBoxAdapter(child: Divider(height: 8)),
                      _sectionTitle(context, title: "Ratings"),
                      _ratingEntriesSection(context, setup: setup),
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

enum _SetupDetailsAction {
  edit('Edit', Icons.edit),
  restore('Restore', Icons.restore),
  compare('Compare', Icons.compare);

  final String label;
  final IconData icon;

  const _SetupDetailsAction(this.label, this.icon);
}
