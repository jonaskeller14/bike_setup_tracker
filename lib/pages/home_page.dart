import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../models/task/task_rule.dart';
import '../repositories/app_repository.dart';
import '../utils/bike_actions.dart';
import '../utils/person_actions.dart';
import '../utils/rating_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';
import '../widgets/animated_app_bar_switcher.dart';
import '../widgets/google_drive_sync_button.dart';
import '../widgets/lists/garage_list.dart';
import '../widgets/lists/list_scroll_controller.dart';
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
  final Set<String> _selectedTaskRules = {};
  bool _isDeletingTaskRules = false;
  bool _isCompletingTaskRules = false;

  bool get _isTaskSelectionMode => _selectedTaskRules.isNotEmpty;

  void _clearTaskRuleSelection() {
    setState(() => _selectedTaskRules.clear());
  }

  void _toggleTaskRuleSelection(String taskRuleId) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_selectedTaskRules.remove(taskRuleId)) {
        _selectedTaskRules.add(taskRuleId);
      }
    });
  }

  Future<void> _deleteSelectedTaskRules() async {
    if (_isDeletingTaskRules) return;

    final selectedTaskRules = Set<String>.of(_selectedTaskRules);
    setState(() => _isDeletingTaskRules = true);

    try {
      await TaskActions.removeTaskRules(context, taskRuleIds: selectedTaskRules);
      if (!mounted) return;
      setState(() => _selectedTaskRules.clear());
    } finally {
      if (mounted) setState(() => _isDeletingTaskRules = false);
    }
  }

  Future<void> _completeSelectedTaskRules() async {
    if (_isCompletingTaskRules) return;

    final selectedTaskRules = Set<String>.of(_selectedTaskRules);
    setState(() => _isCompletingTaskRules = true);

    try {
      await TaskActions.addDefaultTaskEntries(context, taskRuleIds: selectedTaskRules);
      if (!mounted) return;
      setState(() => _selectedTaskRules.clear());
    } finally {
      if (mounted) setState(() => _isCompletingTaskRules = false);
    }
  }

  @override
  void dispose() {
    _garageListController.dispose();
    _setupListController.dispose();
    _taskListController.dispose();
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
    final showTaskSelectionAppBar = appSettings.enableTask && pageIndex == taskPageIndex && _isTaskSelectionMode;

    return PopScope(
      canPop: !showTaskSelectionAppBar,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clearTaskRuleSelection();
      },
      child: Scaffold(
      appBar: AnimatedAppBarSwitcher(
        child: showTaskSelectionAppBar
            ? AppBar(
                key: const ValueKey('task-selection-app-bar'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearTaskRuleSelection,
                ),
                title: Text('${_selectedTaskRules.length} selected'),
                actions: [
                  IconButton(
                    onPressed: _isDeletingTaskRules || _isCompletingTaskRules ? null : _deleteSelectedTaskRules,
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
          setState(() {
            _currentPageIndex = index;
            if (index != pageIndex) _selectedTaskRules.clear();
          });
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
            GarageList(controller: _garageListController),
            SetupList(controller: _setupListController),
            if (appSettings.enablePerson) const PersonList(),
            if (appSettings.enableRating) const RatingList(),
            if (appSettings.enableTask)
              TaskList(
                controller: _taskListController,
                selectedTaskRules: _selectedTaskRules,
                onTaskRuleSelectionChanged: _isCompletingTaskRules ? null : _toggleTaskRuleSelection,
                onSelectedTaskRulesCompleted: _isCompletingTaskRules ? null : _completeSelectedTaskRules,
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
