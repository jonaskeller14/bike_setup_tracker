import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../models/rating/rating.dart';
import '../models/setup.dart';
import '../models/task/task_rule.dart';
import '../models/timeline_selection.dart';
import '../repositories/app_repository.dart';
import '../utils/bike_actions.dart';
import '../utils/person_actions.dart';
import '../utils/rating_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';
import '../utils/timeline_actions.dart';
import '../widgets/animated_app_bar_switcher.dart';
import '../widgets/google_drive_sync_button.dart';
import '../widgets/lists/garage_list.dart';
import '../widgets/lists/list_scroll_controller.dart';
import '../widgets/lists/list_selection_controller.dart';
import '../widgets/lists/person_list.dart';
import '../widgets/lists/rating_list.dart';
import '../widgets/lists/setup_list.dart';
import '../widgets/lists/task_list.dart';
import '../widgets/sheets/export.dart';
import '../widgets/sheets/import.dart';
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
  }

  void _selectionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _deleteSelectedBikes() {
    return _bikeSelection.run((bikeIds) async {
      final appRepository = context.read<AppRepository>();
      final bikes = bikeIds.map((id) => appRepository.bikes[id]).whereType<Bike>().toList();
      await BikeActions.removeBikes(context, bikes: bikes);
    });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appRepository = context.read<AppRepository>();
    _taskRuleSelection.retainWhere(appRepository.filteredTaskRules.containsKey);
    _bikeSelection.retainWhere(appRepository.filteredBikes.containsKey);
    _timelineSelection.retainWhere(
      (entry) => switch (entry.kind) {
        TimelineSelectionKind.setup => appRepository.filteredSetups.containsKey(entry.id),
        TimelineSelectionKind.taskEntry => appRepository.filteredTaskEntries.containsKey(entry.id),
        TimelineSelectionKind.ratingEntry => appRepository.filteredRatingEntries.containsKey(entry.id),
      },
    );
  }

  @override
  void dispose() {
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
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final actionableTaskRulesCount = appRepository.actionableTaskRulesCount;

    final defaultIndex = appRepository.bikes.isEmpty || appRepository.components.isEmpty ? 0 : 1;
    final pageIndex = (_currentPageIndex ?? defaultIndex).clamp(
      0,
      1 + (appSettings.enablePerson ? 1 : 0) + (appSettings.enableRating ? 1 : 0) + (appSettings.enableTask ? 1 : 0),
    );
    final taskPageIndex = 2 + (appSettings.enablePerson ? 1 : 0) + (appSettings.enableRating ? 1 : 0);
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
                title: Text('${_bikeSelection.length} selected'),
                actions: [
                  IconButton(
                    onPressed: _bikeSelection.isBusy ? null : _deleteSelectedBikes,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete selected',
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
                title: Text('${_timelineSelection.length} selected'),
                actions: [
                  if (appSettings.enableSetupBookmark && selectedSetupsOnly)
                    IconButton(
                      onPressed: _timelineSelection.isBusy ? null : _toggleBookmarkForSelectedSetups,
                      icon: Icon(removesBookmarks ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
                      tooltip: removesBookmarks ? 'Remove bookmark' : 'Bookmark',
                    ),
                  if (appSettings.enableSetupTags && selectedSetupsOnly)
                    IconButton(
                      onPressed: _timelineSelection.isBusy ? null : _setTagsForSelectedSetups,
                      icon: const Icon(Icons.tag),
                      tooltip: 'Set tags',
                    ),
                  IconButton(
                    onPressed: _timelineSelection.isBusy ? null : _deleteSelectedTimelineEntries,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete selected',
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
                title: Text('${_taskRuleSelection.length} selected'),
                actions: [
                  IconButton(
                    onPressed: _taskRuleSelection.isBusy ? null : _setPriorityForSelectedTaskRules,
                    icon: const Icon(Icons.traffic),
                    tooltip: 'Set priority',
                  ),
                  if (appSettings.enableTaskTags)
                    IconButton(
                      onPressed: _taskRuleSelection.isBusy ? null : _setTagsForSelectedTaskRules,
                      icon: const Icon(Icons.tag),
                      tooltip: 'Set tags',
                    ),
                  IconButton(
                    onPressed: _taskRuleSelection.isBusy ? null : _deleteSelectedTaskRules,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete selected',
                  ),
                ],
              )
            : AppBar(
                key: const ValueKey('default-app-bar'),
                leading: Padding(
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
                title: <Text>[
                  const Text("Bikes"),
                  const Text("Setup History"),
                  if (appSettings.enablePerson) const Text("Profile"),
                  if (appSettings.enableRating) const Text("Ratings"),
                  if (appSettings.enableTask) const Text("Tasks"),
                ][pageIndex],
                actions: [
                  if (appSettings.enableStrava) const StravaSyncButton(),
                  if (appSettings.enableGoogleDrive) const GoogleDriveSyncButton(),
                  PopupMenuButton<_AppOptions>(
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
                            Text(appOption.label),
                          ],
                        ),
                      );
                    }).toList(),
                    icon: const Icon(Icons.more_vert),
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
          NavigationDestination(
            icon: Badge(
              isLabelVisible: appRepository.selectedBike != null,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Bike.iconData),
            ),
            label: 'Bikes',
          ),
          const NavigationDestination(icon: Icon(Setup.iconData), label: 'Setups'),
          if (appSettings.enablePerson) const NavigationDestination(icon: Icon(Person.iconData), label: "Profile"),
          if (appSettings.enableRating) const NavigationDestination(icon: Icon(Rating.iconData), label: "Ratings"),
          if (appSettings.enableTask)
            NavigationDestination(
              icon: Badge.count(
                count: actionableTaskRulesCount,
                maxCount: 99,
                isLabelVisible: actionableTaskRulesCount > 0,
                backgroundColor: (appRepository.worstActionableTaskStatus ?? TaskStatusType.completed).getStatusColor(context),
                child: const Icon(Icons.checklist),
              ),
              label: "Tasks",
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
            if (appSettings.enablePerson) const PersonList(),
            if (appSettings.enableRating) const RatingList(),
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
            children: [
              if (_garageListController.showBackToTop) ...[
                FloatingActionButton.small(
                  heroTag: "garageBackToTop",
                  onPressed: _garageListController.scrollBackToTop,
                  tooltip: 'Back to top',
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 12),
              ],
              FloatingActionButton(
                heroTag: "addBike",
                onPressed: () async {
                  await BikeActions.addBike(context);
                },
                tooltip: 'Add Bike',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _setupListController,
          builder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_setupListController.showBackToTop) ...[
                FloatingActionButton.small(
                  heroTag: "setupBackToTop",
                  onPressed: _setupListController.scrollBackToTop,
                  tooltip: 'Back to top',
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 12),
              ],
              FloatingActionButton(
                heroTag: "addSetup",
                onPressed: () async {
                  await SetupActions.addSetup(context);
                },
                tooltip: 'Add Setup',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        if (appSettings.enablePerson)
          FloatingActionButton(
            heroTag: "addPerson",
            onPressed: () async {
              await PersonActions.addPerson(context);
            },
            tooltip: 'Add Person',
            child: const Icon(Icons.add),
          ),
        if (appSettings.enableRating)
          FloatingActionButton(
            heroTag: "addRating",
            onPressed: () async {
              await RatingActions.addRating(context);
            },
            tooltip: 'Add Rating',
            child: const Icon(Icons.add),
          ),
        if (appSettings.enableTask)
          ListenableBuilder(
            listenable: _taskListController,
            builder: (context, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_taskListController.showBackToTop) ...[
                  FloatingActionButton.small(
                    heroTag: "taskBackToTop",
                    onPressed: _taskListController.scrollBackToTop,
                    tooltip: 'Back to top',
                    child: const Icon(Icons.arrow_upward),
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: "addTask",
                  onPressed: () async {
                    await TaskActions.addTaskRule(context);
                  },
                  tooltip: 'Add Task',
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
  import('Import Data', Icons.file_upload),
  export('Export Data', Icons.file_download),
  share('Share Data', Icons.share),
  trash('Trash', Icons.delete),
  settings("Settings", Icons.settings);

  final String label;
  final IconData iconData;
  const _AppOptions(this.label, this.iconData);
}
