import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/entity_names.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/feedback/test_session.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/task/task_rule.dart';
import '../models/timeline_selection.dart';
import '../repositories/app_repository.dart';
import '../services/navigation_service.dart';
import '../utils/automation_ids.dart';
import '../utils/bike_actions.dart';
import '../utils/person_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';
import '../utils/test_session_actions.dart';
import '../utils/timeline_actions.dart';
import '../widgets/animated_app_bar_switcher.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/google_drive_sync_button.dart';
import '../widgets/lists/garage_list.dart';
import '../widgets/lists/list_scroll_controller.dart';
import '../widgets/lists/list_selection_controller.dart';
import '../widgets/lists/person_list.dart';
import '../widgets/lists/setup_list.dart';
import '../widgets/lists/task_list.dart';
import '../widgets/sheets/export.dart';
import '../widgets/sheets/import.dart';
import '../widgets/sheets/rider_sheet.dart';
import '../widgets/sheets/share.dart';
import '../widgets/strava_sync_button.dart';
import 'settings/app_settings_page.dart';
import 'trash_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _currentPageIndex;
  final ListScrollController _garageListController = ListScrollController();
  final ListScrollController _setupListController = ListScrollController();
  final ListScrollController _taskListController = ListScrollController();
  final ListSelectionController<String> _bikeSelection = ListSelectionController<String>();
  final ListSelectionController<String> _taskRuleSelection = ListSelectionController<String>();
  final ListSelectionController<TimelineSelectionId> _timelineSelection =
      ListSelectionController<TimelineSelectionId>();

  @override
  void initState() {
    super.initState();
    _bikeSelection.addListener(_selectionChanged);
    _taskRuleSelection.addListener(_selectionChanged);
    _timelineSelection.addListener(_selectionChanged);
    NavigationService.tasksTabRequested.addListener(_showRequestedTasksTab);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRequestedTasksTab());
  }

  void _selectionChanged() {
    if (mounted) setState(() {});
  }

  static int _taskPageIndexOf(AppSettings appSettings) => 2 + (appSettings.showAdvancedPersonUi ? 1 : 0);

  void _showRequestedTasksTab() {
    if (!mounted || !NavigationService.tasksTabRequested.value) return;
    NavigationService.tasksTabRequested.value = false;
    final appSettings = context.read<AppSettings>();
    if (!appSettings.enableTask) return;
    setState(() => _currentPageIndex = _taskPageIndexOf(appSettings));
    _taskRuleSelection.clear();
    _bikeSelection.clear();
    _timelineSelection.clear();
  }

  void _toggleDeveloperMode() {
    final appSettings = context.read<AppSettings>();
    final enabled = !appSettings.developerMode;
    appSettings.developerMode = enabled;
    unawaited(HapticFeedback.mediumImpact());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.info(context, enabled ? 'Developer mode on' : 'Developer mode off'));
  }

  Future<void> _deleteSelectedBikes() {
    return _bikeSelection.run((bikeIds) async {
      final appRepository = context.read<AppRepository>();
      final bikes = bikeIds.map((id) => appRepository.bikes[id]).whereType<Bike>().toList();
      await BikeActions.removeBikes(context, bikes: bikes);
    });
  }

  Future<void> _setPersonForSelectedBikes() {
    return _bikeSelection.runIfApplied((bikeIds) => BikeActions.setBikesPerson(context, bikeIds: bikeIds));
  }

  Future<void> _deleteSelectedTaskRules() {
    return _taskRuleSelection.run((ids) => TaskActions.removeTaskRules(context, taskRuleIds: ids));
  }

  Future<void> _setPriorityForSelectedTaskRules() {
    return _taskRuleSelection.runIfApplied((ids) => TaskActions.setTaskRulesPriority(context, taskRuleIds: ids));
  }

  Future<void> _setTagsForSelectedTaskRules() {
    return _taskRuleSelection.runIfApplied((ids) => TaskActions.setTaskRulesTags(context, taskRuleIds: ids));
  }

  Future<void> _completeSelectedTaskRules() {
    return _taskRuleSelection.run((ids) => TaskActions.addDefaultTaskEntries(context, taskRuleIds: ids));
  }

  Future<void> _deleteSelectedTimelineEntries() {
    return _timelineSelection.run(
      (selection) => TimelineActions.removeSelection(context, selection: selection),
    );
  }

  Future<void> _setTagsForSelectedSetups() {
    return _timelineSelection.runIfApplied(
      (selection) => SetupActions.setSetupsTags(
        context,
        setupIds: selection.idsOf(TimelineSelectionKind.setup),
      ),
    );
  }

  Future<void> _toggleBookmarkForSelectedSetups() {
    return _timelineSelection.run(
      (selection) => SetupActions.toggleBookmarks(
        context,
        setupIds: selection.idsOf(TimelineSelectionKind.setup),
      ),
    );
  }

  Widget _addSetupFab(AppRepository appRepository) {
    final step = TestSessionActions.nextStepFor(appRepository, context.l10n);
    final label = step?.label ?? context.l10n.homeAddSetup;

    return FloatingActionButton.extended(
      heroTag: "addSetup",
      onPressed: () async {
        await (step?.run(context) ?? SetupActions.addSetup(context));
      },
      tooltip: label,
      isExtended: _setupListController.isNearTop,
      extendedPadding: _setupListController.isNearTop ? null : const EdgeInsets.symmetric(horizontal: 16),
      icon: Icon(step?.icon ?? Icons.add),
      label: Text(label),
    );
  }

  Widget _testSessionFab(AppRepository appRepository) {
    final bikeId = TestSessionActions.activeBikeId(appRepository);
    final running = bikeId == null ? null : appRepository.runningSessionFor(bikeId);
    if (running != null) {
      final scheme = Theme.of(context).colorScheme;
      return FloatingActionButton.small(
        heroTag: "testSession",
        onPressed: () => TestSessionActions.endSession(context, session: running),
        tooltip: context.l10n.homeTooltipEndTestSession(running.label(context.l10n)),
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        child: const Icon(Icons.stop),
      );
    }
    return FloatingActionButton.small(
      heroTag: "testSession",
      onPressed: () => TestSessionActions.startSession(context, initialBike: appRepository.bikes[bikeId]),
      tooltip: context.l10n.homeTooltipStartTestSession,
      child: const Icon(TestSession.iconData),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appRepository = context.read<AppRepository>();
    _taskRuleSelection.retainWhere(appRepository.view.taskRules.containsKey);
    _bikeSelection.retainWhere(appRepository.view.bikes.containsKey);
    _timelineSelection.retainWhere(
      (entry) => switch (entry.kind) {
        TimelineSelectionKind.setup => appRepository.view.setups.containsKey(entry.id),
        TimelineSelectionKind.taskEntry => appRepository.view.taskEntries.containsKey(entry.id),
        TimelineSelectionKind.feedback => appRepository.view.feedbacks.containsKey(entry.id),
        TimelineSelectionKind.testSession => appRepository.view.testSessions.containsKey(entry.id),
      },
    );
  }

  @override
  void dispose() {
    NavigationService.tasksTabRequested.removeListener(_showRequestedTasksTab);
    _garageListController.dispose();
    _setupListController.dispose();
    _taskListController.dispose();
    _bikeSelection
      ..removeListener(_selectionChanged)
      ..dispose();
    _taskRuleSelection
      ..removeListener(_selectionChanged)
      ..dispose();
    _timelineSelection
      ..removeListener(_selectionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final actionableTaskRulesCount = appRepository.actionableTaskRulesCount;

    final defaultIndex = appRepository.bikes.isEmpty || appRepository.components.isEmpty ? 0 : 1;
    final pageIndex = (_currentPageIndex ?? defaultIndex).clamp(
      0,
      1 + (appSettings.showAdvancedPersonUi ? 1 : 0) + (appSettings.enableTask ? 1 : 0),
    );
    final taskPageIndex = _taskPageIndexOf(appSettings);
    final showTaskSelectionAppBar =
        appSettings.enableTask && pageIndex == taskPageIndex && _taskRuleSelection.isSelectionMode;
    final showBikeSelectionAppBar = pageIndex == 0 && _bikeSelection.isSelectionMode;
    final showTimelineSelectionAppBar = pageIndex == 1 && _timelineSelection.isSelectionMode;

    final selectedSetupsOnly = _timelineSelection.selected.isSetupsOnly;
    final selectedSetups = _timelineSelection.selected
        .idsOf(TimelineSelectionKind.setup)
        .map((id) => appRepository.setups[id])
        .whereType<Setup>();
    final removesBookmarks = selectedSetups.isNotEmpty && selectedSetups.every((setup) => setup.isBookmarked);

    return PopScope(
      canPop: !showTaskSelectionAppBar && !showBikeSelectionAppBar && !showTimelineSelectionAppBar,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (showBikeSelectionAppBar) _bikeSelection.clear();
        if (showTaskSelectionAppBar) _taskRuleSelection.clear();
        if (showTimelineSelectionAppBar) _timelineSelection.clear();
      },
      child: Scaffold(
      appBar: AnimatedAppBarSwitcher(
        child: showBikeSelectionAppBar
            ? AppBar(
                key: const ValueKey('bike-selection-app-bar'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _bikeSelection.clear,
                ),
                title: Text(l10n.selectionCount(_bikeSelection.length)),
                actions: [
                  if (appSettings.enablePerson)
                    IconButton(
                      onPressed: _bikeSelection.isBusy ? null : _setPersonForSelectedBikes,
                      icon: const Icon(Person.iconData),
                      tooltip: l10n.homeTooltipSetRider,
                    ),
                  IconButton(
                    onPressed: _bikeSelection.isBusy ? null : _deleteSelectedBikes,
                    icon: const Icon(Icons.delete),
                    tooltip: l10n.deleteSelectedTooltip,
                  ),
                ],
              )
            : showTimelineSelectionAppBar
            ? AppBar(
                key: const ValueKey('timeline-selection-app-bar'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _timelineSelection.clear,
                ),
                title: Text(l10n.selectionCount(_timelineSelection.length)),
                actions: [
                  if (appSettings.enableSetupBookmark && selectedSetupsOnly)
                    IconButton(
                      onPressed: _timelineSelection.isBusy ? null : _toggleBookmarkForSelectedSetups,
                      icon: Icon(removesBookmarks ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
                      tooltip: removesBookmarks ? l10n.homeTooltipRemoveBookmark : l10n.homeTooltipBookmark,
                    ),
                  if (appSettings.enableSetupTags && selectedSetupsOnly)
                    IconButton(
                      onPressed: _timelineSelection.isBusy ? null : _setTagsForSelectedSetups,
                      icon: const Icon(Icons.tag),
                      tooltip: l10n.homeTooltipSetTags,
                    ),
                  IconButton(
                    onPressed: _timelineSelection.isBusy ? null : _deleteSelectedTimelineEntries,
                    icon: const Icon(Icons.delete),
                    tooltip: l10n.deleteSelectedTooltip,
                  ),
                ],
              )
            : showTaskSelectionAppBar
            ? AppBar(
                key: const ValueKey('task-selection-app-bar'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _taskRuleSelection.clear,
                ),
                title: Text(l10n.selectionCount(_taskRuleSelection.length)),
                actions: [
                  IconButton(
                    onPressed: _taskRuleSelection.isBusy ? null : _setPriorityForSelectedTaskRules,
                    icon: const Icon(TaskPriority.iconData),
                    tooltip: l10n.homeTooltipSetPriority,
                  ),
                  if (appSettings.enableTaskTags)
                    IconButton(
                      onPressed: _taskRuleSelection.isBusy ? null : _setTagsForSelectedTaskRules,
                      icon: const Icon(Icons.tag),
                      tooltip: l10n.homeTooltipSetTags,
                    ),
                  IconButton(
                    onPressed: _taskRuleSelection.isBusy ? null : _deleteSelectedTaskRules,
                    icon: const Icon(Icons.delete),
                    tooltip: l10n.deleteSelectedTooltip,
                  ),
                ],
              )
            : AppBar(
                key: const ValueKey('default-app-bar'),
                leading: GestureDetector(
                  onDoubleTap: kDebugMode ? _toggleDeveloperMode : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 30,
                      width: 30,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/logo_256.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                title: <Text>[
                  Text(l10n.homeTitleBikes),
                  Text(l10n.homeTitleSetupHistory),
                  if (appSettings.showAdvancedPersonUi) Text(l10n.homeTitleRiders),
                  if (appSettings.enableTask) Text(l10n.homeTitleTasks),
                ][pageIndex],
                actions: [
                  if (appSettings.enablePerson)
                    Semantics(
                      container: true,
                      identifier: AutomationIds.appBarRider,
                      child: IconButton(
                        onPressed: () => showRiderSheet(context),
                        icon: Badge(
                          isLabelVisible: appRepository.persons.isEmpty,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Person.iconData),
                        ),
                        tooltip: l10n.homeTooltipRider,
                      ),
                    ),
                  if (appSettings.enableStrava) const StravaSyncButton(),
                  if (appSettings.enableGoogleDrive) const GoogleDriveSyncButton(),
                  Semantics(
                    container: true,
                    identifier: AutomationIds.appBarOptions,
                    child: PopupMenuButton<_AppOptions>(
                      onSelected: (_AppOptions result) async {
                        switch (result) {
                          case _AppOptions.import:
                            await importData(context);
                          case _AppOptions.export:
                            await exportData(context);
                          case _AppOptions.share:
                            await shareData(context);
                          case _AppOptions.trash:
                            await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const TrashPage()));
                          case _AppOptions.settings:
                            await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AppSettingsPage()));
                        }
                      },
                      itemBuilder: (BuildContext context) => _AppOptions.values.map((appOption) {
                        return PopupMenuItem<_AppOptions>(
                          value: appOption,
                          child: Row(
                            children: [
                              Icon(appOption.iconData),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Semantics(
                                  identifier: appOption == _AppOptions.settings ? AutomationIds.appBarOptionsSettings : null,
                                  child: Text(appOption.label(l10n), overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      icon: const Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: pageIndex,
        onDestinationSelected: (int index) {
          if (index == pageIndex) {
            if (index == 0) {
              unawaited(_garageListController.scrollBackToTop());
              return;
            }
            if (index == 1) {
              unawaited(_setupListController.scrollBackToTop());
              return;
            }
            if (index == taskPageIndex) {
              unawaited(_taskListController.scrollBackToTop());
              return;
            }
          }
          setState(() => _currentPageIndex = index);
          if (index != pageIndex) {
            _taskRuleSelection.clear();
            _bikeSelection.clear();
            _timelineSelection.clear();
          }
        },
        destinations: <Widget>[
          Semantics(
            container: true,
            identifier: AutomationIds.navBikes,
            child: NavigationDestination(
              icon: Badge(
                isLabelVisible: appRepository.filters.bikeId != null,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Bike.iconData),
              ),
              label: l10n.homeNavBikes,
            ),
          ),
          Semantics(
            container: true,
            identifier: AutomationIds.navSetups,
            child: NavigationDestination(icon: const Icon(Setup.iconData), label: l10n.homeNavSetups),
          ),
          if (appSettings.showAdvancedPersonUi)
            NavigationDestination(icon: const Icon(Person.iconData), label: l10n.homeNavRiders),
          if (appSettings.enableTask)
            Semantics(
              container: true,
              identifier: AutomationIds.navTasks,
              child: NavigationDestination(
                icon: Badge.count(
                  count: actionableTaskRulesCount,
                  maxCount: 99,
                  isLabelVisible: actionableTaskRulesCount > 0,
                  backgroundColor: (appRepository.worstActionableTaskStatus ?? TaskStatusType.completed).getStatusColor(context),
                  child: const Icon(Icons.checklist),
                ),
                label: l10n.homeNavTasks,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: pageIndex,
          children: <Widget>[
            GarageList(
              controller: _garageListController,
              selectedBikes: _bikeSelection.selected,
              onBikeSelectionChanged: _bikeSelection.isBusy ? null : _bikeSelection.toggle,
            ),
            SetupList(
              controller: _setupListController,
              selection: _timelineSelection.selected,
              onSelectionChanged: _timelineSelection.isBusy ? null : _timelineSelection.toggle,
            ),
            if (appSettings.showAdvancedPersonUi) const PersonList(),
            if (appSettings.enableTask)
              TaskList(
                controller: _taskListController,
                selectedTaskRules: _taskRuleSelection.selected,
                onTaskRuleSelectionChanged: _taskRuleSelection.isBusy ? null : _taskRuleSelection.toggle,
                onSelectedTaskRulesCompleted: _taskRuleSelection.isBusy ? null : _completeSelectedTaskRules,
              ),
          ],
        ),
      ),
      floatingActionButton: <Widget>[
        ListenableBuilder(
          listenable: _garageListController,
          builder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              if (_garageListController.showBackToTop) ...[
                FloatingActionButton.small(
                  heroTag: "garageBackToTop",
                  onPressed: _garageListController.scrollBackToTop,
                  tooltip: l10n.backToTopTooltip,
                  child: const Icon(Icons.arrow_upward),
                ),
              ],
              // Distinct keys: the tabs share this slot, and an identifier-only
              // change on a reused semantics node never reaches the platform.
              Semantics(
                key: const ValueKey(AutomationIds.addBikeFab),
                container: true,
                identifier: AutomationIds.addBikeFab,
                child: FloatingActionButton(
                  heroTag: "addBike",
                  onPressed: () async {
                    await BikeActions.addBike(context);
                  },
                  tooltip: l10n.homeTooltipAddBike,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _setupListController,
          builder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              if (_setupListController.showBackToTop) ...[
                FloatingActionButton.small(
                  heroTag: "setupBackToTop",
                  onPressed: _setupListController.scrollBackToTop,
                  tooltip: l10n.backToTopTooltip,
                  child: const Icon(Icons.arrow_upward),
                ),
              ],
              if (appSettings.enableRating) ...[
                _testSessionFab(appRepository),
              ],
              Semantics(
                key: const ValueKey(AutomationIds.addSetupFab),
                container: true,
                identifier: AutomationIds.addSetupFab,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: _addSetupFab(appRepository),
                ),
              ),
            ],
          ),
        ),
        if (appSettings.showAdvancedPersonUi)
          FloatingActionButton(
            heroTag: "addPerson",
            onPressed: () async {
              await PersonActions.addPerson(context);
            },
            tooltip: l10n.homeTooltipAddRider,
            child: const Icon(Icons.add),
          ),
        if (appSettings.enableTask)
          ListenableBuilder(
            listenable: _taskListController,
            builder: (context, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                if (_taskListController.showBackToTop) ...[
                  FloatingActionButton.small(
                    heroTag: "taskBackToTop",
                    onPressed: _taskListController.scrollBackToTop,
                    tooltip: l10n.backToTopTooltip,
                    child: const Icon(Icons.arrow_upward),
                  ),
                ],
                FloatingActionButton(
                  heroTag: "addTask",
                  onPressed: () async {
                    await TaskActions.addTaskRule(context);
                  },
                  tooltip: l10n.homeTooltipAddTask,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
      ][pageIndex],
      ),
    );
  }
}

enum _AppOptions {
  import(Icons.file_upload),
  export(Icons.file_download),
  share(Icons.share),
  trash(Icons.delete),
  settings(Icons.settings);

  final IconData iconData;
  const _AppOptions(this.iconData);

  String label(AppLocalizations l10n) => switch (this) {
    _AppOptions.import => l10n.homeMenuImport,
    _AppOptions.export => l10n.homeMenuExport,
    _AppOptions.share => l10n.homeMenuShare,
    _AppOptions.trash => l10n.homeMenuTrash,
    _AppOptions.settings => l10n.homeMenuSettings,
  };
}
