import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/component_stats.dart';
import '../models/installation.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../services/setup_resolution_service.dart';
import '../utils/file_export.dart';

class AppRepository extends ChangeNotifier {
  final AppDatabase database;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  
  /// Track if the repository has been disposed.
  /// This is used as a safety guard for asynchronous operations that might
  /// complete after the repository is closed (common in tests), preventing
  /// 'notifyListeners() called after dispose()' crashes.
  bool _isDisposed = false;
  bool _pendingDataChange = false;

  // ---------------------------------------------------------------------------
  // RAW STATE FROM DB (Read-Only Cache for immediate access)
  // ---------------------------------------------------------------------------
  Map<String, Person> _persons = {};
  Map<String, Bike> _bikes = {};
  Map<String, Setup> _setups = {};
  Map<String, Component> _components = {};
  Map<String, Rating> _ratings = {};
  Map<String, TaskRule> _taskRules = {};
  Map<String, TaskEntry> _taskEntries = {};
  Map<int, StravaAthlete> _stravaAthletes = {};
  Map<int, StravaActivity> _stravaActivities = {};
  Map<String, StravaGear> _stravaGears = {};
  Map<String, ComponentStats> _componentStats = {};
  Map<String, ComponentStats> _bikeStats = {};
  Map<String, dynamic> _currentAdjustmentValues = {};

  int _stravaOffset = 0;
  int _stravaLimit = 50;
  bool _hasMoreStrava = true;
  bool _isLoadingMoreStrava = false;
  bool _stravaSortAscending = false;
  int _stravaOperationVersion = 0;

  bool get hasMoreStrava => _hasMoreStrava;
  bool get isLoadingMoreStrava => _isLoadingMoreStrava;
  bool get stravaSortAscending => _stravaSortAscending;

  Stream<List<StravaActivity>> get stravaActivitiesWithPosition => database.stravaDao.watchActivitiesWithPosition().map((list) => list.map((a) => a.toModel()).toList());

  /// Debug helper to override the pagination chunk size in tests.
  void debugSetStravaLimit(int limit) {
    _stravaLimit = limit;
  }

  Future<List<StravaActivity>> get latestStravaActivities async {
    final list = await database.stravaDao.getActivitiesPaginated(limit: 3, offset: 0, mode: drift.OrderingMode.desc);
    return list.map((a) => a.toModel()).toList();
  }

  Future<List<StravaActivity>> getFilteredStravaActivitiesWithPosition() async {
    final allWithPos = await database.stravaDao.watchActivitiesWithPosition().first;
    final activities = allWithPos.map((a) => a.toModel()).toList();
    
    if (_selectedBike == null) return activities;
    
    final selectedStravaGear = bikes[_selectedBike]?.stravaGear;
    if (selectedStravaGear == null) {
      return activities.where((a) {
        final stravaGear = a.gearId;
        return stravaGear == null || !bikes.values.any((b) => b.stravaGear == stravaGear);
      }).toList();
    }

    return activities.where((a) => a.gearId == selectedStravaGear).toList();
  }

  Future<List<StravaActivity>> searchStravaActivities(String query) async {
    final results = await database.stravaDao.searchActivitiesByName(query);
    final activities = results.map((a) => a.toModel()).toList();

    if (_selectedBike == null) return activities;

    final selectedStravaGear = bikes[_selectedBike]?.stravaGear;
    if (selectedStravaGear == null) {
      return activities.where((a) {
        final g = a.gearId;
        return g == null || !bikes.values.any((b) => b.stravaGear == g);
      }).toList();
    }

    return activities.where((a) => a.gearId == selectedStravaGear).toList();
  }

  Future<StravaActivity?> getStravaActivity(int id) async {
    if (_stravaActivities.containsKey(id)) return _stravaActivities[id];
    final dbActivity = await database.stravaDao.getActivityById(id);
    return dbActivity?.toModel();
  }

  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;
  Map<String, TaskRule> get taskRules => _taskRules;
  Map<String, TaskEntry> get taskEntries => _taskEntries;
  Map<int, StravaAthlete> get stravaAthletes => _stravaAthletes;
  Map<int, StravaActivity> get stravaActivities => _stravaActivities;
  Map<String, StravaGear> get stravaGears => _stravaGears;
  Map<String, ComponentStats> get componentStats => _componentStats;
  Map<String, ComponentStats> get bikeStats => _bikeStats;
  Map<String, dynamic> get currentAdjustmentValues => _currentAdjustmentValues;

  DateTime get lastModified {
    final allDates = [
      ..._persons.values.map((p) => p.lastModified),
      ..._bikes.values.map((b) => b.lastModified),
      ..._setups.values.map((s) => s.lastModified),
      ..._components.values.map((c) => c.lastModified),
      ..._ratings.values.map((r) => r.lastModified),
      ..._taskRules.values.map((tr) => tr.lastModified),
      ..._taskEntries.values.map((te) => te.lastModified),
    ].whereType<DateTime>();

    if (allDates.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return allDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ---------------------------------------------------------------------------

  // FILTERING STATE
  // ---------------------------------------------------------------------------
  String? _selectedBike;
  final Set<String> _selectedSetupTags = {};
  final Set<TaskPriority> _selectedTaskPriorities = TaskPriority.values.toSet();
  final Set<String> _selectedTaskRuleTags = {};
  Set<String> _setupTags = {};
  Set<String> _taskRuleTags = {};

  String? get selectedBike => _selectedBike;
  Set<String> get selectedSetupTags => _selectedSetupTags;
  Set<TaskPriority> get selectedTaskPriorities => _selectedTaskPriorities;
  Set<String> get selectedTaskRuleTags => _selectedTaskRuleTags;
  Set<String> get setupTags => _setupTags;
  Set<String> get taskRuleTags => _taskRuleTags;

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  Map<String, Component> _filteredComponents = {};
  Map<String, Setup> _filteredSetups = {};
  Map<String, TaskRule> _filteredTaskRules = {};
  Map<String, TaskEntry> _filteredTaskEntries = {};
  Map<int, StravaActivity> _filteredStravaActivities = {};
  Map<String, TaskRule> _filteredOpenTaskRules = {};
  List<ComponentInstallation> _filteredInstallations = [];

  List<TaskRuleWithStatus> get openTaskRules {
    final statusRules = _filteredTaskRules.values.map((rule) => TaskRuleWithStatus(rule: rule, status: getTaskRuleStatus(rule)));
    final toDo = statusRules.where((tr) => tr.status.type != TaskStatusType.completed).toList();
    
    // Sort open Tasks: Status (Overdue > Due > Upcoming), then by progress, then by Priority (Critical > High > Medium > Low)
    toDo.sort((a, b) {
      if (a.status.type.index != b.status.type.index) {
        return b.status.type.index.compareTo(a.status.type.index);
      }
      final progressComparison = b.status.progress.compareTo(a.status.progress);
      if (progressComparison != 0) {
        return progressComparison;
      }
      return b.rule.priority.index.compareTo(a.rule.priority.index);
    });
    return toDo;
  }
  
  TaskStatusType get openTaskRulesStatusType {
    if (_filteredTaskRules.isEmpty) return TaskStatusType.completed;

    bool hasDue = false;
    bool hasUpcoming = false;

    for (final rule in _filteredTaskRules.values) {
      final status = getTaskRuleStatus(rule);
      switch (status.type) {
        case TaskStatusType.overdue:
          return TaskStatusType.overdue;
        case TaskStatusType.due:
          hasDue = true;
        case TaskStatusType.upcoming:
          hasUpcoming = true;
        case TaskStatusType.completed:
          break;
      }
    }

    if (hasDue) return TaskStatusType.due;
    if (hasUpcoming) return TaskStatusType.upcoming;
    return TaskStatusType.completed;
  }

  List<TaskRuleWithStatus> get completedTaskRules {
    final statusRules = _filteredTaskRules.values.map((rule) => TaskRuleWithStatus(rule: rule, status: getTaskRuleStatus(rule)));
    final completed = statusRules.where((tr) => tr.status.type == TaskStatusType.completed).toList();
    completed.sort((a, b) => b.rule.lastModified.compareTo(a.rule.lastModified));
    return completed;
  }

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  Map<String, Component> get filteredComponents => _filteredComponents;
  Map<String, Setup> get filteredSetups => _filteredSetups;
  Map<String, TaskRule> get filteredTaskRules => _filteredTaskRules;
  Map<String, TaskRule> get filteredOpenTaskRules => _filteredOpenTaskRules;
  int get filteredOpenTaskRulesCount => _filteredOpenTaskRules.length;
  Map<String, TaskEntry> get filteredTaskEntries => _filteredTaskEntries;
  Map<int, StravaActivity> get filteredStravaActivities => _filteredStravaActivities;
  List<ComponentInstallation> get filteredInstallations => _filteredInstallations;

  // ---------------------------------------------------------------------------
  // DELETED ITEMS (for TrashPage)
  // ---------------------------------------------------------------------------
  List<Person> _deletedPersons = [];
  List<Bike> _deletedBikes = [];
  List<Component> _deletedComponents = [];
  List<Setup> _deletedSetups = [];
  List<Rating> _deletedRatings = [];
  List<TaskRule> _deletedTaskRules = [];
  List<TaskEntry> _deletedTaskEntries = [];

  List<Person> get deletedPersons => _deletedPersons;
  List<Bike> get deletedBikes => _deletedBikes;
  List<Component> get deletedComponents => _deletedComponents;
  List<Setup> get deletedSetups => _deletedSetups;
  List<Rating> get deletedRatings => _deletedRatings;
  List<TaskRule> get deletedTaskRules => _deletedTaskRules;
  List<TaskEntry> get deletedTaskEntries => _deletedTaskEntries;

  // ---------------------------------------------------------------------------
  // INITIALIZATION AND STREAMS
  // ---------------------------------------------------------------------------

  AppRepository(this.database) {
    _initStreams();
  }

  Future<void> initialize() async {
    FileExport.deleteOldBackups();
    unawaited(initialStravaLoad());
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  void _initStreams() {
    _subscriptions.add(database.bikesDao.watchAllBikes().listen((list) {
      _bikes = {for (var b in list) b.id: b.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.componentsDao.watchAllComponentsWithData().listen((list) {
      _components = {for (var c in list) c.component.id: c.component.toModel(
        adjustments: c.adjustments.map((a) => a.toModel()).toList(),
        installations: c.installations.map((i) => i.toModel()).toList(),
      )};
      _dataChanged();
    }));

    _subscriptions.add(database.personsDao.watchAllPersonsWithData().listen((list) {
      _persons = {for (var p in list) p.person.id: p.person.toModel(
        adjustments: p.adjustments.map((a) => a.toModel()).toList(),
      )};
      _dataChanged();
    }));

    _subscriptions.add(database.ratingsDao.watchAllRatingsWithData().listen((list) {
      _ratings = {for (var r in list) r.rating.id: r.rating.toModel(
        adjustments: r.adjustments.map((a) => a.toModel()).toList(),
      )};
      _dataChanged();
    }));

    _subscriptions.add(database.taskDao.watchAllRules().listen((list) {
      _taskRules = {for (var r in list) r.id: r.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.taskDao.watchAllEntries().listen((list) {
      _taskEntries = {for (var e in list) e.id: e.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchAllAthletes().listen((list) {
      _stravaAthletes = {for (var a in list) a.id: a.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchAllGears().listen((list) {
      _stravaGears = {for (var g in list) g.id: g.toModel()};
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchComponentStats().listen((map) {
      _componentStats = map;
      _dataChanged();
    }));

    _subscriptions.add(database.stravaDao.watchBikeStats().listen((map) {
      _bikeStats = map;
      _dataChanged();
    }));
    
    _subscriptions.add(database.setupsDao.watchAllSetupsWithValues().listen((list) {
      _setups = {for (var s in list) s.setup.id: s.setup.toModel(values: s.values)};
      _dataChanged();
    }));

    // Deleted item streams
    _subscriptions.add(database.bikesDao.watchDeletedBikes().listen((list) {
      _deletedBikes = list.map((b) => b.toModel()).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.componentsDao.watchDeletedComponents().listen((list) {
      _deletedComponents = list.map((c) => c.toModel(adjustments: [], installations: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.setupsDao.watchDeletedSetups().listen((list) {
      _deletedSetups = list.map((s) => s.toModel(values: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.personsDao.watchDeletedPersons().listen((list) {
      _deletedPersons = list.map((p) => p.toModel(adjustments: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.ratingsDao.watchDeletedRatings().listen((list) {
      _deletedRatings = list.map((r) => r.toModel(adjustments: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.taskDao.watchDeletedRules().listen((list) {
      _deletedTaskRules = list.map((tr) => tr.toModel()).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.taskDao.watchDeletedEntries().listen((list) {
      _deletedTaskEntries = list.map((te) => te.toModel()).toList();
      _notifyIfActive();
    }));
  }

  void _notifyIfActive() {
    if (_isDisposed || !hasListeners) return;
    notifyListeners();
  }

  void _dataChanged() {
    if (_isDisposed) return;
    if (_pendingDataChange) return;
    _pendingDataChange = true;
    unawaited(Future.microtask(() {
      if (_isDisposed) return;
      _pendingDataChange = false;
      _resolveData();
      _filter();
      notifyListeners();
    }));
  }

  @override
  void notifyListeners() {
    // Safety guard to avoid 'notifyListeners() called after dispose()' crashes
    // during tests or fast navigational changes.
    if (_isDisposed) return;
    super.notifyListeners();
  }

  void _resolveData() {
    final result = SetupResolutionService.resolveSetups(
      setups: _setups,
      bikes: _bikes,
      persons: _persons,
      components: _components,
      ratings: _ratings,
    );
    _setups = result.setups;
    _currentAdjustmentValues = result.globalState;

    // Apply component stats
    _components = {
      for (var entry in _components.entries)
        entry.key: entry.value.copyWith(
          totalDistance: _componentStats[entry.key]?.distance ?? entry.value.initialDistance,
          totalElevationGain: _componentStats[entry.key]?.elevationGain ?? entry.value.initialElevationGain,
          totalMovingTime: _componentStats[entry.key]?.movingTime ?? entry.value.initialMovingTime,
          totalElapsedTime: _componentStats[entry.key]?.elapsedTime ?? entry.value.initialElapsedTime,
          totalActivityCount: _componentStats[entry.key]?.activityCount ?? entry.value.initialActivityCount,
        )
    };

    _setupTags = SetupResolutionService.extractAllTags(_setups.values);
    _taskRuleTags = _taskRules.values.map((tr) => tr.tags).expand((tags) => tags).toSet();
  }

  void filter() {
    _filter();
    notifyListeners();
  }

  void _filter() {
    if (selectedBike != null && !bikes.containsKey(_selectedBike!)) {
      _selectedBike = null;
    }
    _selectedSetupTags.removeWhere((tag) => !setupTags.contains(tag));
    _selectedTaskRuleTags.removeWhere((tag) => !taskRuleTags.contains(tag));

    _filterBikes();
    _filterComponents();
    _filterSetups();
    _filterPersons();
    _filterRatings();
    _filterTaskRules();  // after _filterComponents()
    _filterTaskEntries();  // after _filterTaskRules()
    _filterStravaActivities();
    _filterInstallations();
  }

  void _filterBikes() {
    _filteredBikes = selectedBike == null 
        ? bikes
        : Map.fromEntries(bikes.entries.where((entry) => entry.key == selectedBike));
  }

  void _filterComponents() {
    _filteredComponents = selectedBike == null
        ? components
        : Map.fromEntries(components.entries.where((entry) => entry.value.bike == selectedBike));
  }

  void _filterSetups() {
    _filteredSetups = Map.fromEntries(setups.entries.where((entry) => 
      (selectedBike == null ? true : entry.value.bike == selectedBike) && 
      (selectedSetupTags.isEmpty ? true : entry.value.tags.containsAll(selectedSetupTags))
    ));
  }

  void _filterPersons() {
    _filteredPersons = _selectedBike == null 
        ? persons
        : Map.fromEntries(persons.entries.where((entry) => entry.value.id == bikes[_selectedBike]?.person));
  }

  void _filterRatings() {
    _filteredRatings = Map.fromEntries(ratings.entries.where((entry) {
      final rating = entry.value;
      switch (rating.filterType) {
        case FilterType.global: return true;
        case FilterType.person: return true;
        case FilterType.bike: return _selectedBike == null ? true : rating.filter == _selectedBike;
        case FilterType.component: return _selectedBike == null ? true : filteredComponents.values.any((c) => c.id == rating.filter);
        case FilterType.componentType: return _selectedBike == null ? true : filteredComponents.values.any((c) => c.componentType.toString() == rating.filter);
      }
    }));
  }

  void _filterTaskRules() {
    _filteredTaskRules = Map.fromEntries(
      taskRules.entries.where((entry) {
        final rule = entry.value;
        if (!_selectedTaskPriorities.contains(rule.priority)) return false;

        if (selectedTaskRuleTags.isNotEmpty && !entry.value.tags.containsAll(selectedTaskRuleTags)) return false;

        // 1. Global Tasks (no component, no bike)
        if (rule.componentId == null && rule.bikeId == null) return true;
        
        // 2. Bike-linked Tasks
        if (rule.bikeId != null) {
          return _selectedBike == null || rule.bikeId == _selectedBike;
        }
        
        // 3. Component-linked Tasks
        if (rule.componentId != null) {
          return _filteredComponents.containsKey(rule.componentId);
        }
        
        return false;
      }),
    );

    _filteredOpenTaskRules = Map.fromEntries(
      _filteredTaskRules.entries.where(
        (entry) => !taskEntries.values.any((te) => te.taskRule == entry.key),
      ),
    );
  }

  void _filterTaskEntries() {
    _filteredTaskEntries = Map.fromEntries(
      taskEntries.entries.where(
        (entry) => _filteredTaskRules.containsKey(entry.value.taskRule),
      ),
    );
  }

  void _filterStravaActivities() {
    if (_selectedBike == null) {
      _filteredStravaActivities = stravaActivities;
      return;
    }
    
    final selectedStravaGear = bikes[_selectedBike]?.stravaGear;
    if (selectedStravaGear == null) {
      _filteredStravaActivities = Map.fromEntries(stravaActivities.entries.where((entry) {
        final stravaGear = entry.value.gearId;
        return stravaGear == null || !bikes.values.any((b) => b.stravaGear == stravaGear);
      }));
      return;
    }

    _filteredStravaActivities = Map.fromEntries(stravaActivities.entries.where((entry) {
      return entry.value.gearId == selectedStravaGear;
    }));
  }

  void _filterInstallations() {
    _filteredInstallations = [];
    for (final component in components.values) {
      final sorted = List<Installation>.from(component.installations)
        ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
      
      for (int i = 0; i < sorted.length; i++) {
        final installation = sorted[i];
        if (installation.dateTimeUTC.millisecondsSinceEpoch == 0) continue;
        
        final previousInstallation = i > 0 ? sorted[i-1] : null;
        final originParent = previousInstallation?.parent;
        final isInitial = i == 0;
        
        final ci = ComponentInstallation(
          component: component,
          installation: installation,
          originParent: originParent,
          isInitial: isInitial,
        );
        
        if (selectedBike == null || installation.parent == selectedBike || originParent == selectedBike) {
          _filteredInstallations.add(ci);
        }
      }
    }
  }

  Future<void> initialStravaLoad() async {
    _stravaOffset = 0;
    _hasMoreStrava = true;
    _isLoadingMoreStrava = true;
    notifyListeners();

    final list = await database.stravaDao.getActivitiesPaginated(
      limit: _stravaLimit, 
      offset: 0,
      mode: _stravaSortAscending ? drift.OrderingMode.asc : drift.OrderingMode.desc,
    );
    if (_isDisposed) return;
    _stravaActivities = {for (var a in list) a.id: a.toModel()};
    _stravaOffset = list.length;
    if (list.length < _stravaLimit) _hasMoreStrava = false;
    _isLoadingMoreStrava = false;
    _dataChanged();
  }

  Future<void> setStravaSortOrder(bool ascending) async {
    if (_stravaSortAscending == ascending) return;
    _stravaSortAscending = ascending;
    // Reset and reload
    _stravaActivities = {};
    _stravaOffset = 0;
    _hasMoreStrava = true;
    await initialStravaLoad();
  }

  Future<void> loadMoreStravaActivities() async {
    if (_isLoadingMoreStrava || !_hasMoreStrava) return;
    _isLoadingMoreStrava = true;
    notifyListeners();

    final list = await database.stravaDao.getActivitiesPaginated(
      limit: _stravaLimit, 
      offset: _stravaOffset,
      mode: _stravaSortAscending ? drift.OrderingMode.asc : drift.OrderingMode.desc,
    );
    if (_isDisposed) return;
    _stravaActivities.addAll({for (var a in list) a.id: a.toModel()});
    _stravaOffset += list.length;
    if (list.length < _stravaLimit) _hasMoreStrava = false;
    _isLoadingMoreStrava = false;
    _dataChanged();
  }

  void onBikeTap(String? newBike) {
    if (newBike == null || selectedBike == newBike) {
      _selectedBike = null;
    } else {
      _selectedBike = newBike;
    }
    _filter();
    notifyListeners();
  }

  void selectSetupTag(String newTag) {
    if (!setupTags.contains(newTag)) return;
    _selectedSetupTags.add(newTag);
    _filterSetups();
    notifyListeners();
  }

  void deselectSetupTag(String tag) {
    _selectedSetupTags.remove(tag);
    _filterSetups();
    notifyListeners();
  }

  void deselectAllSetupTags() {
    _selectedSetupTags.clear();
    _filterSetups();
    notifyListeners();
  }

    void selectTaskRuleTag(String newTag) {
    if (!taskRuleTags.contains(newTag)) return;
    _selectedTaskRuleTags.add(newTag);
    _filterTaskRules();
    notifyListeners();
  }

  void deselectTaskRuleTag(String tag) {
    _selectedTaskRuleTags.remove(tag);
    _filterTaskRules();
    notifyListeners();
  }

  void deselectAllTaskRuleTags() {
    _selectedTaskRuleTags.clear();
    _filterTaskRules();
    notifyListeners();
  }

  void selectTaskPriority(TaskPriority taskPriority) {
    _selectedTaskPriorities.add(taskPriority);
    _filterTaskRules();
    _filterTaskEntries();
    notifyListeners();
  }

  void deselectTaskPriority(TaskPriority taskPriority) {
    _selectedTaskPriorities.remove(taskPriority);
    _filterTaskRules();
    _filterTaskEntries();
    notifyListeners();
  }

  void selectAllTaskPriorities() {
    _selectedTaskPriorities.addAll(TaskPriority.values.toSet());
    _filterTaskRules();
    _filterTaskEntries();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // WRITE OPERATIONS
  // ---------------------------------------------------------------------------

  Future<SelectedData?> loadLegacyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString("data") ?? "{}";
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return SelectedData.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  Future<ComponentStats> getStatsAt({String? componentId, String? bikeId, required DateTime date}) async {
    if (componentId != null) {
      return database.stravaDao.getComponentStatsAt(componentId, date);
    } else if (bikeId != null) {
      return database.stravaDao.getBikeStatsAt(bikeId, date);
    }
    return ComponentStats.zero();
  }

  Future<void>  refreshTaskEntrySnapshots() async {
    final entries = _taskEntries.values.toList();
    for (final entry in entries) {
      final newSnapshot = await getStatsAt(
        componentId: entry.componentId,
        bikeId: entry.bikeId,
        date: entry.dateTimeUTC,
      );
      
      if (newSnapshot != entry.snapshot) {
        await database.taskDao.upsertEntry(entry.copyWith(snapshot: newSnapshot).toCompanion());
      }
    }
  }

  TaskStatus getTaskRuleStatus(TaskRule rule) {
    final entries = _taskEntries.values
        .where((te) => te.taskRule == rule.id)
        .toList()
      ..sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC));
    final lastEntry = entries.isNotEmpty ? entries.first : null;

    DateTime? installationDate;
    if (rule.componentId != null) {
      final component = _components[rule.componentId];
      final bike = component?.bike != null ? _bikes[component!.bike] : null;
      if (component != null && bike != null) {
        final installation = component.installations.where((i) => i.parent == bike.id).toList()
            ..sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC));
        if (installation.isNotEmpty) {
          installationDate = installation.first.dateTimeUTC;
        }
      }
    }

    final stats = rule.componentId != null
        ? (_componentStats[rule.componentId] ?? ComponentStats.zero())
        : (rule.bikeId != null ? (_bikeStats[rule.bikeId] ?? ComponentStats.zero()) : ComponentStats.zero());

    return rule.calculateStatus(
      currentStats: stats,
      now: DateTime.now().toUtc(),
      lastEntry: lastEntry,
      componentInstallationDate: installationDate,
    );
  }

  Future<void> removeBike(Bike bike) async {
    await database.bikesDao.deleteBike(bike.id);
  }

  Future<void> restoreBike(Bike bike) async {
    final updated = bike.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
    await database.bikesDao.updateBike(updated.toCompanion());
  }

  Future<void> removeComponents(Iterable<Component> components) async {
    for (var component in components) {
      await database.componentsDao.deleteComponent(component.id);
    }
  }

  Future<void> restoreComponents(Iterable<Component> components) async {
    for (var component in components) {
      final updated = component.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.componentsDao.updateComponent(updated.toCompanion());
    }
  }

  Future<void> removeSetups(Iterable<Setup> setups) async {
    for (var setup in setups) {
      await database.setupsDao.deleteSetup(setup.id);
    }
  }

  Future<void> restoreSetups(Iterable<Setup> setups) async {
    for (var setup in setups) {
      final updated = setup.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.setupsDao.updateSetup(updated.toCompanion());
    }
  }

  Future<void> removePerson(Person person) async {
    await database.personsDao.deletePerson(person.id);
  }

  Future<void> restorePerson(Person person) async {
    final updated = person.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
    await database.personsDao.updatePerson(updated.toCompanion());
  }

  Future<void> removeRatings(Iterable<Rating> ratings) async {
    for (var rating in ratings) {
      await database.ratingsDao.deleteRating(rating.id);
    }
  }

  Future<void> restoreRatings(Iterable<Rating> ratings) async {
    for (var rating in ratings) {
      final updated = rating.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.ratingsDao.updateRating(updated.toCompanion());
    }
  }

  Future<void> removeTaskRules(Iterable<TaskRule> rules) async {
    for (var rule in rules) {
      await database.taskDao.deleteRule(rule.id);
    }
  }

  Future<void> restoreTaskRules(Iterable<TaskRule> rules) async {
    for (var rule in rules) {
      final updated = rule.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.taskDao.updateRule(updated.toCompanion());
    }
  }

  Future<void> removeTaskEntries(Iterable<TaskEntry> entries) async {
    for (var entry in entries) {
      await database.taskDao.deleteEntry(entry.id);
    }
  }

  Future<void> restoreTaskEntries(Iterable<TaskEntry> entries) async {
    for (var entry in entries) {
      final updated = entry.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.taskDao.updateEntry(updated.toCompanion());
    }
  }

  Future<void> addBike(Bike bike) async {
    final updated = bike.copyWith(lastModified: DateTime.now().toUtc());
    await database.bikesDao.insertBike(updated.toCompanion());
  }

  Future<void> addPerson(Person person) async {
    final updated = person.copyWith(lastModified: DateTime.now().toUtc());
    await database.personsDao.insertPersonWithData(
      person: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addRating(Rating rating) async {
    final updated = rating.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingsDao.insertRatingWithData(
      rating: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(ratingId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addTaskRule(TaskRule rule) async {
    final updated = rule.copyWith(lastModified: DateTime.now().toUtc());
    await database.taskDao.insertRule(updated.toCompanion());
  }

  Future<void> editTaskRule(TaskRule rule) async {
    final updated = rule.copyWith(lastModified: DateTime.now().toUtc());
    await database.taskDao.updateRule(updated.toCompanion());
  }

  Future<void> addTaskEntry(TaskEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.taskDao.insertEntry(updated.toCompanion());
  }

  Future<void> editTaskEntry(TaskEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.taskDao.updateEntry(updated.toCompanion());
  }

  Future<void> addComponent(Component component) async {
    final updated = component.copyWith(lastModified: DateTime.now().toUtc());
    await database.componentsDao.insertComponentWithData(
      component: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(componentId: updated.id, orderIndex: entry.key)
      ).toList(),
      installationsList: updated.installations.map((inst) => 
        inst.toCompanion(id: const Uuid().v4(), componentId: updated.id)
      ).toList(),
    );
  }

  Future<void> editPerson(Person person) async {
    final updated = person.copyWith(lastModified: DateTime.now().toUtc());
    await database.personsDao.updatePersonWithData(
      person: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> editBike(Bike bike) async {
    final updated = bike.copyWith(lastModified: DateTime.now().toUtc());
    await database.bikesDao.updateBike(updated.toCompanion());
  }

  Future<void> editComponent(Component component) async {
    final updated = component.copyWith(lastModified: DateTime.now().toUtc());
    await database.componentsDao.updateComponentWithData(
      component: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(componentId: updated.id, orderIndex: entry.key)
      ).toList(),
      installationsList: updated.installations.map((inst) => 
        inst.toCompanion(id: const Uuid().v4(), componentId: updated.id)
      ).toList(),
    );
  }

  Future<void> editRating(Rating rating) async {
    final updated = rating.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingsDao.updateRatingWithData(
      rating: updated.toCompanion(),
      adjustmentsList: updated.adjustments.asMap().entries.map((entry) => 
        entry.value.toCompanion(ratingId: updated.id, orderIndex: entry.key)
      ).toList(),
    );
  }

  Future<void> addSetup(Setup setup) async {
    final updated = setup.copyWith(lastModified: DateTime.now().toUtc());
    await database.setupsDao.insertSetupWithValues(
      setup: updated.toCompanion(), 
      bikeValues: updated.bikeAdjustmentValues, 
      personValues: updated.personAdjustmentValues, 
      ratingValues: updated.ratingAdjustmentValues
    );
  }

  Future<void> editSetup(Setup setup) async {
    final updated = setup.copyWith(lastModified: DateTime.now().toUtc());
    await database.setupsDao.updateSetupWithValues(
      setup: updated.toCompanion(),
      bikeValues: setup.bikeAdjustmentValues, 
      personValues: setup.personAdjustmentValues, 
      ratingValues: setup.ratingAdjustmentValues
    );
  }

  Future<void> reorderRating({required int oldIndex, required int newIndex, required List<Rating> filteredRatingsList}) async {
    final globalList = ratings.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final itemToMove = filteredRatingsList[oldIndex];
    final int globalOldIndex = globalList.indexOf(itemToMove);
    final targetItem = newIndex < filteredRatingsList.length ? filteredRatingsList[newIndex] : null;
    final int globalNewIndex = targetItem == null ? globalList.length : globalList.indexOf(targetItem);

    globalList.removeAt(globalOldIndex);
    globalList.insert(globalNewIndex, itemToMove);

    // Optimistic Update: Manually rearrange state and re-filter immediately to prevent
    // the UI from 'snapping back' while we wait for the database round-trip.
    _ratings = {
      for (int i = 0; i < globalList.length; i++)
        globalList[i].id: globalList[i].copyWith(orderIndex: i)
    };
    _filter();
    notifyListeners();

    await database.ratingsDao.reorder(globalList.map((e) => e.id).toList());
  }

  Future<void> reorderPerson({required int oldIndex, required int newIndex, required List<Person> filteredPersonsList}) async {
    final globalList = persons.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final itemToMove = filteredPersonsList[oldIndex];
    final int globalOldIndex = globalList.indexOf(itemToMove);
    final targetItem = newIndex < filteredPersonsList.length ? filteredPersonsList[newIndex] : null;
    final int globalNewIndex = targetItem == null ? globalList.length : globalList.indexOf(targetItem);

    globalList.removeAt(globalOldIndex);
    globalList.insert(globalNewIndex, itemToMove);

    // Optimistic Update: Manually rearrange state and re-filter immediately to prevent
    // the UI from 'snapping back' while we wait for the database round-trip.
    _persons = {
      for (int i = 0; i < globalList.length; i++)
        globalList[i].id: globalList[i].copyWith(orderIndex: i)
    };
    _filter();
    notifyListeners();

    await database.personsDao.reorder(globalList.map((e) => e.id).toList());
  }

  Future<void> reorderComponent({required int oldIndex, required int newIndex, required List<Component> filteredComponentsList}) async {
    final globalList = components.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final itemToMove = filteredComponentsList[oldIndex];
    final int globalOldIndex = globalList.indexOf(itemToMove);
    final targetItem = newIndex < filteredComponentsList.length ? filteredComponentsList[newIndex] : null;
    final int globalNewIndex = targetItem == null ? globalList.length : globalList.indexOf(targetItem);

    globalList.removeAt(globalOldIndex);
    globalList.insert(globalNewIndex, itemToMove);

    // Optimistic Update: Manually rearrange state and re-filter immediately to prevent 
    // the UI from 'snapping back' while we wait for the database round-trip.
    _components = {
      for (int i = 0; i < globalList.length; i++)
        globalList[i].id: globalList[i].copyWith(orderIndex: i)
    };
    _filter();
    notifyListeners();

    await database.componentsDao.reorder(globalList.map((e) => e.id).toList());
  }

  Future<void> reorderBike({required int oldIndex, required int newIndex, required List<Bike> filteredBikesList}) async {
    final globalList = bikes.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final itemToMove = filteredBikesList[oldIndex];
    final int globalOldIndex = globalList.indexOf(itemToMove);
    final targetItem = newIndex < filteredBikesList.length ? filteredBikesList[newIndex] : null;
    final int globalNewIndex = targetItem == null ? globalList.length : globalList.indexOf(targetItem);

    globalList.removeAt(globalOldIndex);
    globalList.insert(globalNewIndex, itemToMove);

    // Optimistic Update: Manually rearrange state and re-filter immediately to prevent
    // the UI from 'snapping back' while we wait for the database round-trip.
    _bikes = {
      for (int i = 0; i < globalList.length; i++)
        globalList[i].id: globalList[i].copyWith(orderIndex: i)
    };
    _filter();
    notifyListeners();

    await database.bikesDao.reorder(globalList.map((e) => e.id).toList());
  }

  Future<void> setStravaActivities(Iterable<StravaActivity> activities, {List<int>? toDelete}) async {
    final versionAtStart = _stravaOperationVersion;
    
    // Perform bulk operations in a single transaction for performance and to reduce race conditions
    await database.transaction(() async {
      if (toDelete != null && toDelete.isNotEmpty) {
        await database.stravaDao.deleteActivities(toDelete);
      }
      for (var a in activities) {
        // Check if we were cleared while processing
        if (versionAtStart != _stravaOperationVersion) return;
        await database.stravaDao.upsertActivity(a.toCompanion());
      }
    });

    if (versionAtStart != _stravaOperationVersion) {
      return;
    }

    await refreshTaskEntrySnapshots();

    debugPrint("AppRepository finished syncing activities with database (v$versionAtStart).");
    // Refresh the first page if we are at the top, to show potentially new activities
    if (_stravaOffset <= _stravaLimit) {
      initialStravaLoad();
    } else {
       _dataChanged();
    }
  }

  Future<void> setStravaAthletes(Iterable<StravaAthlete> athletes) async {
    for (var a in athletes) {
      await database.stravaDao.upsertAthlete(a.toCompanion());
    }
  }

  Future<void> setStravaGears(Iterable<StravaGear> gears) async {
    await database.stravaDao.syncGears(gears.map((g) => g.toCompanion()));
  }
  
  Future<void> clearStravaData() async {
    _stravaOperationVersion++; 
    
    await database.delete(database.stravaActivities).go();
    await database.delete(database.stravaAthletes).go();
    await database.delete(database.stravaGears).go();
    _stravaActivities = {};
    _stravaAthletes = {};
    _stravaGears = {};
    _stravaOffset = 0;
    _hasMoreStrava = true;
    _dataChanged();
  }
}

class ComponentInstallation {
  final Component component;
  final Installation installation;
  final String? originParent;
  final bool isInitial;

  ComponentInstallation({
    required this.component,
    required this.installation,
    this.originParent,
    this.isInitial = false,
  });
}
