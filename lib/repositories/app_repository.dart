import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/component_stats.dart';
import '../models/installation.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/rating_association.dart';
import '../models/rating_entry.dart';
import '../models/rating_metric.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../services/backup_service.dart';
import '../services/rating_score_service.dart';
import '../services/setup_resolution_service.dart';
import '../utils/unit_conversion.dart';

class AppRepository extends ChangeNotifier {
  final AppDatabase database;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  
  /// Track if the repository has been disposed.
  /// This is used as a safety guard for asynchronous operations that might
  /// complete after the repository is closed (common in tests), preventing
  /// 'notifyListeners() called after dispose()' crashes.
  bool _isDisposed = false;
  bool _pendingDataChange = false;

  /// Streams whose first emission must arrive before the app is considered
  /// ready. Deep-link handlers (e.g. "Add Setup") read these caches
  /// synchronously, so the UI must not mount until they are populated.
  static const _requiredInitialStreams = {
    'bikes', 'components', 'persons', 'ratings', 'ratingEntries',
    'taskRules', 'taskEntries', 'setups',
  };
  final Set<String> _firedInitialStreams = <String>{};
  final Completer<void> _initialDataCompleter = Completer<void>();

  /// Completes once every stream in [_requiredInitialStreams] has delivered
  /// its first event, guaranteeing the in-memory caches reflect the DB.
  Future<void> get initialDataLoaded => _initialDataCompleter.future;

  void _markInitialStreamFired(String name) {
    if (_initialDataCompleter.isCompleted) return;
    _firedInitialStreams.add(name);
    if (_firedInitialStreams.containsAll(_requiredInitialStreams)) {
      _initialDataCompleter.complete();
    }
  }

  // ---------------------------------------------------------------------------
  // RAW STATE FROM DB (Read-Only Cache for immediate access)
  // ---------------------------------------------------------------------------
  Map<String, Person> _persons = {};
  Map<String, Bike> _bikes = {};
  Map<String, Setup> _setups = {};
  Map<String, Component> _components = {};
  Map<String, Rating> _ratings = {};
  Map<String, RatingEntry> _ratingEntries = {};
  Map<String, TaskRule> _taskRules = {};
  Map<String, TaskEntry> _taskEntries = {};
  Map<int, StravaAthlete> _stravaAthletes = {};
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
  // Identifies the gear-filter context the current loaded window was paged for.
  // Strava is paginated per active filter (see [getActivitiesPaginated]); when
  // this changes we re-page from the top so the bike's activities never get
  // dropped behind a global pagination boundary.
  String? _lastStravaFilterSignature;

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
    if (_filteredStravaActivities.containsKey(id)) return _filteredStravaActivities[id];
    final dbActivity = await database.stravaDao.getActivityById(id);
    return dbActivity?.toModel();
  }

  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, Rating> get ratings => _ratings;
  Map<String, RatingEntry> get ratingEntries => _ratingEntries;
  Map<String, TaskRule> get taskRules => _taskRules;
  Map<String, TaskEntry> get taskEntries => _taskEntries;
  Map<int, StravaAthlete> get stravaAthletes => _stravaAthletes;
  // Strava is paginated per active filter, so the loaded window is the filtered
  // set; [stravaActivities] and [filteredStravaActivities] return the same map.
  Map<int, StravaActivity> get stravaActivities => _filteredStravaActivities;
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
  Map<String, RatingEntry> _filteredRatingEntries = {};
  Map<String, TaskRule> _filteredTaskRules = {};
  Map<String, TaskEntry> _filteredTaskEntries = {};
  Map<int, StravaActivity> _filteredStravaActivities = {};
  Map<String, TaskRule> _filteredOpenTaskRules = {};
  List<ComponentInstallation> _filteredInstallations = [];

  List<TaskRuleWithStatus> _openTaskRulesWithStatus(Iterable<TaskRule> rules) {
    final statusRules = rules.map((rule) => TaskRuleWithStatus(rule: rule, status: getTaskRuleStatus(rule)));
    final toDo = statusRules.where((tr) => tr.status.type != TaskStatusType.completed).toList();

    // Sort open Tasks: Status (Overdue > Due > Upcoming), then by Priority (Critical > High > Medium > Low), then by progress
    toDo.sort((a, b) {
      if (a.status.type.index != b.status.type.index) {
        return b.status.type.index.compareTo(a.status.type.index);
      }
      final priorityComparison = b.rule.priority.index.compareTo(a.rule.priority.index);
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      return b.status.progress.compareTo(a.status.progress);
    });
    return toDo;
  }

  List<TaskRuleWithStatus> get openTaskRules => _openTaskRulesWithStatus(_filteredTaskRules.values);

  /// Open (non-completed) task rules for a bike, including rules attached to its components.
  List<TaskRuleWithStatus> openTaskRulesForBike(String bikeId) {
    final rules = _taskRules.values.where((rule) {
      if (rule.bikeId == bikeId) return true;
      if (rule.componentId != null) return _components[rule.componentId]?.bike == bikeId;
      return false;
    });
    return _openTaskRulesWithStatus(rules);
  }

  /// Open (non-completed) task rules for a single component.
  List<TaskRuleWithStatus> openTaskRulesForComponent(String componentId) {
    return _openTaskRulesWithStatus(_taskRules.values.where((rule) => rule.componentId == componentId));
  }

  /// Aggregates the worst status across [rules]: any overdue wins, else any due, else any upcoming, else completed.
  TaskStatusType getAggregatedTaskStatus(Iterable<TaskRule> rules) {
    if (rules.isEmpty) return TaskStatusType.completed;

    bool hasDue = false;
    bool hasUpcoming = false;

    for (final rule in rules) {
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

  TaskStatusType get openTaskRulesStatusType => getAggregatedTaskStatus(_filteredTaskRules.values);

  /// Worst status among a component's open task rules, or null if it has none.
  TaskStatusType? componentTaskIndicatorStatus(String componentId) {
    final openRules = openTaskRulesForComponent(componentId);
    if (openRules.isEmpty) return null;
    return getAggregatedTaskStatus(openRules.map((t) => t.rule));
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
  Map<String, Component> get archivedComponents => {
        for (final entry in _components.entries)
          if (entry.value.isArchived) entry.key: entry.value
      };
  Map<String, Setup> get filteredSetups => _filteredSetups;
  Map<String, RatingEntry> get filteredRatingEntries => _filteredRatingEntries;
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
  List<RatingEntry> _deletedRatingEntries = [];
  List<TaskRule> _deletedTaskRules = [];
  List<TaskEntry> _deletedTaskEntries = [];

  List<Person> get deletedPersons => _deletedPersons;
  List<Bike> get deletedBikes => _deletedBikes;
  List<Component> get deletedComponents => _deletedComponents;
  List<Setup> get deletedSetups => _deletedSetups;
  List<Rating> get deletedRatings => _deletedRatings;
  List<RatingEntry> get deletedRatingEntries => _deletedRatingEntries;
  List<TaskRule> get deletedTaskRules => _deletedTaskRules;
  List<TaskEntry> get deletedTaskEntries => _deletedTaskEntries;

  // ---------------------------------------------------------------------------
  // INITIALIZATION AND STREAMS
  // ---------------------------------------------------------------------------

  AppRepository(this.database) {
    // Seed the baseline so the first (no-bike) stream emissions don't spuriously
    // re-trigger an initial Strava load before/alongside initialize().
    _lastStravaFilterSignature = _stravaFilterSignature();
    _initStreams();
  }

  Future<void> initialize() async {
    BackupService.deleteOldBackups();
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
      _markInitialStreamFired('bikes');
      _dataChanged();
    }));

    _subscriptions.add(database.componentsDao.watchAllComponentsWithData().listen((list) {
      _components = {for (var c in list) c.component.id: c.component.toModel(
        adjustments: c.adjustments.map((a) => a.toModel()).toList(),
        installations: c.installations.map((i) => i.toModel()).toList(),
      )};
      _markInitialStreamFired('components');
      _dataChanged();
    }));

    _subscriptions.add(database.personsDao.watchAllPersonsWithData().listen((list) {
      _persons = {for (var p in list) p.person.id: p.person.toModel(
        adjustments: p.adjustments.map((a) => a.toModel()).toList(),
      )};
      _markInitialStreamFired('persons');
      _dataChanged();
    }));

    _subscriptions.add(database.ratingsDao.watchAllRatingsWithData().listen((list) {
      _ratings = {for (var r in list) r.rating.id: r.rating.toModel(
        metrics: r.metrics.map((m) => m.toModel()).toList(),
      )};
      _markInitialStreamFired('ratings');
      _dataChanged();
    }));

    _subscriptions.add(database.taskDao.watchAllRules().listen((list) {
      _taskRules = {for (var r in list) r.id: r.toModel()};
      _markInitialStreamFired('taskRules');
      _dataChanged();
    }));

    _subscriptions.add(database.taskDao.watchAllEntries().listen((list) {
      _taskEntries = {for (var e in list) e.id: e.toModel()};
      _markInitialStreamFired('taskEntries');
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
      _markInitialStreamFired('setups');
      _dataChanged();
    }));

    _subscriptions.add(database.ratingEntriesDao.watchAllRatingEntriesWithValues().listen((list) {
      _ratingEntries = {for (var e in list) e.entry.id: e.entry.toModel(values: e.values)};
      _markInitialStreamFired('ratingEntries');
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
      _deletedRatings = list.map((r) => r.toModel(metrics: [])).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.ratingEntriesDao.watchDeletedRatingEntries().listen((list) {
      _deletedRatingEntries = list.map((e) => e.toModel()).toList();
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
    // Drop the lazily built rating/score lookup caches
    _setupsByBikeSorted = null;
    _ratingEntriesBySetup = null;
    _applicableMetricsByBike = null;
    _setupScoreCache.clear();

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
    _filterRatingEntries();
    _filterPersons();
    _filterRatings();
    _filterTaskRules();  // after _filterComponents()
    _filterTaskEntries();  // after _filterTaskRules()
    _maybeReloadStravaForFilter();  // re-pages Strava if the gear filter changed
    _filterInstallations();
  }

  void _filterBikes() {
    _filteredBikes = selectedBike == null 
        ? bikes
        : Map.fromEntries(bikes.entries.where((entry) => entry.key == selectedBike));
  }

  void _filterComponents() {
    _filteredComponents = Map.fromEntries(components.entries.where((entry) {
      if (entry.value.isArchived) return false;
      return selectedBike == null || entry.value.bike == selectedBike;
    }));
  }

  void _filterSetups() {
    _filteredSetups = Map.fromEntries(setups.entries.where((entry) =>
      (selectedBike == null ? true : entry.value.bike == selectedBike) &&
      (selectedSetupTags.isEmpty ? true : entry.value.tags.containsAll(selectedSetupTags))
    ));
  }

  void _filterRatingEntries() {
    _filteredRatingEntries = selectedBike == null
        ? Map.fromEntries(ratingEntries.entries)
        : Map.fromEntries(ratingEntries.entries.where((entry) => entry.value.bike == selectedBike));
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
          // Hide rules linked to archived (retired/sold) components.
          if (_components[rule.componentId]?.isArchived ?? false) return false;
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

  /// The gear filter (matching [StravaDao.getActivitiesPaginated]) for the
  /// currently selected bike:
  /// - no bike selected -> all activities
  /// - bike linked to a gear -> only that gear
  /// - unlinked bike -> activities whose gear belongs to no bike
  ({String? gearId, bool unassignedOnly, List<String> assignedGears}) _currentStravaFilter() {
    if (_selectedBike == null) {
      return (gearId: null, unassignedOnly: false, assignedGears: const <String>[]);
    }
    final gear = bikes[_selectedBike]?.stravaGear;
    if (gear != null) {
      return (gearId: gear, unassignedOnly: false, assignedGears: const <String>[]);
    }
    final assigned = bikes.values.map((b) => b.stravaGear).whereType<String>().toList();
    return (gearId: null, unassignedOnly: true, assignedGears: assigned);
  }

  /// A stable identity for the active gear-filter context. When this changes,
  /// the loaded Strava window must be re-paged from the top.
  String _stravaFilterSignature() {
    final mode = _stravaSortAscending ? 'asc' : 'desc';
    if (_selectedBike == null) return '$mode|all';
    final gear = bikes[_selectedBike]?.stravaGear;
    if (gear != null) return '$mode|gear:$gear';
    final assigned = bikes.values.map((b) => b.stravaGear).whereType<String>().toList()..sort();
    return '$mode|unassigned:${assigned.join(",")}';
  }

  /// Re-pages Strava from the top when the gear-filter context changes (bike
  /// selection, the selected bike's gear, the assigned-gear pool, or sort).
  void _maybeReloadStravaForFilter() {
    if (_stravaFilterSignature() == _lastStravaFilterSignature) return;
    unawaited(initialStravaLoad());
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
          originParentType: previousInstallation?.parentType,
          isInitial: isInitial,
        );
        
        if (selectedBike == null || installation.parent == selectedBike || originParent == selectedBike) {
          _filteredInstallations.add(ci);
        }
      }
    }
  }

  Future<void> initialStravaLoad() async {
    final sig = _stravaFilterSignature();
    _lastStravaFilterSignature = sig;
    final filter = _currentStravaFilter();
    _stravaOffset = 0;
    _hasMoreStrava = true;
    _isLoadingMoreStrava = true;
    notifyListeners();

    final list = await database.stravaDao.getActivitiesPaginated(
      limit: _stravaLimit,
      offset: 0,
      mode: _stravaSortAscending ? drift.OrderingMode.asc : drift.OrderingMode.desc,
      gearId: filter.gearId,
      unassignedOnly: filter.unassignedOnly,
      assignedGears: filter.assignedGears,
    );
    if (_isDisposed) return;
    // A newer filter took over while we were querying; drop these stale results.
    if (sig != _lastStravaFilterSignature) return;
    _filteredStravaActivities = {for (var a in list) a.id: a.toModel()};
    _stravaOffset = list.length;
    if (list.length < _stravaLimit) _hasMoreStrava = false;
    _isLoadingMoreStrava = false;
    _dataChanged();
  }

  /// Re-derives the in-memory window from the database (the single source of
  /// truth) after an out-of-band write such as a webhook sync, without
  /// collapsing the user's scroll position. Unlike [initialStravaLoad] this
  /// re-pages the whole currently-loaded window (page 1 .. current offset), so
  /// activities the user already scrolled in are kept and any new/changed/
  /// deleted rows are reflected. It runs silently (no loading spinner).
  Future<void> reloadStravaWindow() async {
    final sig = _stravaFilterSignature();
    _lastStravaFilterSignature = sig;
    final filter = _currentStravaFilter();
    // Reload at least the first page; if the user paged further, reload the
    // whole loaded window so scrolled-in activities aren't dropped.
    final reloadLimit = _stravaOffset > _stravaLimit ? _stravaOffset : _stravaLimit;

    final list = await database.stravaDao.getActivitiesPaginated(
      limit: reloadLimit,
      offset: 0,
      mode: _stravaSortAscending ? drift.OrderingMode.asc : drift.OrderingMode.desc,
      gearId: filter.gearId,
      unassignedOnly: filter.unassignedOnly,
      assignedGears: filter.assignedGears,
    );
    if (_isDisposed) return;
    // A newer filter took over while we were querying; drop these stale results.
    if (sig != _lastStravaFilterSignature) return;
    _filteredStravaActivities = {for (var a in list) a.id: a.toModel()};
    _stravaOffset = list.length;
    // Only ever narrows: a short page means the window shrank (deletions);
    // a full page leaves [_hasMoreStrava] as-is so paging keeps working.
    if (list.length < reloadLimit) _hasMoreStrava = false;
    _dataChanged();
  }

  Future<void> setStravaSortOrder(bool ascending) async {
    if (_stravaSortAscending == ascending) return;
    _stravaSortAscending = ascending;
    // initialStravaLoad resets the offset and re-pages for the new ordering.
    await initialStravaLoad();
  }

  Future<void> loadMoreStravaActivities() async {
    if (_isLoadingMoreStrava || !_hasMoreStrava) return;
    _isLoadingMoreStrava = true;
    notifyListeners();

    final sig = _lastStravaFilterSignature;
    final filter = _currentStravaFilter();
    final list = await database.stravaDao.getActivitiesPaginated(
      limit: _stravaLimit,
      offset: _stravaOffset,
      mode: _stravaSortAscending ? drift.OrderingMode.asc : drift.OrderingMode.desc,
      gearId: filter.gearId,
      unassignedOnly: filter.unassignedOnly,
      assignedGears: filter.assignedGears,
    );
    if (_isDisposed) return;
    // The filter changed mid-load; these belong to a stale window.
    if (sig != _lastStravaFilterSignature) return;
    _filteredStravaActivities.addAll({for (var a in list) a.id: a.toModel()});
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

  /// Reads from the DB, not the in-memory `_taskEntries` cache: (1) the cache
  /// lags bulk writes (Strava sync, import) until the watch-stream propagates,
  /// and (2) it omits trashed entries, which must be healed too since restore
  /// does not recompute the snapshot.
  Future<void> refreshTaskEntrySnapshots() async {
    final entries = (await database.taskDao.getAllEntriesBypass())
        .map((e) => e.toModel())
        .toList();
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

  Future<void> addRatingEntry(RatingEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingEntriesDao.insertRatingEntryWithValues(
      entry: updated.toCompanion(),
      values: updated.metricValues,
    );
  }

  Future<void> editRatingEntry(RatingEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingEntriesDao.updateRatingEntryWithValues(
      entry: updated.toCompanion(),
      values: updated.metricValues,
    );
  }

  Future<void> removeRatingEntries(Iterable<RatingEntry> entries) async {
    for (final entry in entries) {
      await database.ratingEntriesDao.deleteRatingEntry(entry.id);
    }
  }

  Future<void> restoreRatingEntries(Iterable<RatingEntry> entries) async {
    for (final entry in entries) {
      final updated = entry.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
      await database.ratingEntriesDao.updateRatingEntry(updated.toCompanion());
    }
  }
  
  // Lazily built lookup caches for rating/score resolution.
  Map<String, List<Setup>>? _setupsByBikeSorted;
  Map<String, List<RatingEntry>>? _ratingEntriesBySetup;
  Map<String, List<RatingMetric>>? _applicableMetricsByBike;
  final Map<String, double?> _setupScoreCache = {};

  Map<String, List<Setup>> get _setupsByBike {
    final cached = _setupsByBikeSorted;
    if (cached != null) return cached;
    final map = <String, List<Setup>>{};
    for (final setup in _setups.values) {
      (map[setup.bike] ??= []).add(setup);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.datetime.compareTo(b.datetime));
    }
    return _setupsByBikeSorted = map;
  }

  Map<String, List<RatingEntry>> get _entriesBySetup {
    final cached = _ratingEntriesBySetup;
    if (cached != null) return cached;
    final map = <String, List<RatingEntry>>{};
    for (final ratingEntry in _ratingEntries.values) {
      final setupId = resolveSetupId(bikeId: ratingEntry.bike, atUtc: ratingEntry.dateTimeUTC);
      if (setupId != null) (map[setupId] ??= []).add(ratingEntry);
    }
    return _ratingEntriesBySetup = map;
  }

  String? resolveSetupId({required String bikeId, required DateTime atUtc}) {
    final sorted = _setupsByBike[bikeId];
    if (sorted == null) return null;
    // Binary search for the latest setup with datetime <= atUtc.
    Setup? best;
    int lo = 0, hi = sorted.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid].datetime.isAfter(atUtc)) {
        hi = mid - 1;
      } else {
        best = sorted[mid];
        lo = mid + 1;
      }
    }
    return best?.id;
  }

  String? resolvedSetupIdFor(RatingEntry entry) =>
      resolveSetupId(bikeId: entry.bike, atUtc: entry.dateTimeUTC);

  List<RatingMetric> _applicableMetricsForBike(String bikeId) =>
      (_applicableMetricsByBike ??= {}).putIfAbsent(
        bikeId,
        () => _computeApplicableMetricsForBike(bikeId),
      );

  List<RatingMetric> _computeApplicableMetricsForBike(String bikeId) {
    final bikePerson = _bikes[bikeId]?.person;
    final bikeComponents = _components.values.where((c) => c.bike == bikeId);
    final componentIds = bikeComponents.map((c) => c.id).toSet();
    final componentTypes = bikeComponents.map((c) => c.componentType.toString()).toSet();

    final metrics = <RatingMetric>[];
    for (final rating in _ratings.values) {
      final applies = switch (rating.filterType) {
        FilterType.global => true,
        FilterType.bike => rating.filter == bikeId,
        FilterType.person => rating.filter != null && rating.filter == bikePerson,
        FilterType.component => componentIds.contains(rating.filter),
        FilterType.componentType => componentTypes.contains(rating.filter),
      };
      if (applies) metrics.addAll(rating.metrics);
    }
    return metrics;
  }

  EntryScore? entryScore(RatingEntry entry) =>
      RatingScoreService.scoreEntry(_applicableMetricsForBike(entry.bike), entry.metricValues);

  EntryScoreBreakdown entryBreakdown(RatingEntry entry) =>
      RatingScoreService.breakdown(_applicableMetricsForBike(entry.bike), entry.metricValues);

  List<RatingEntry> ratingEntriesForSetup(String setupId) =>
      _entriesBySetup[setupId] ?? const [];

  double? scoreForSetup(String setupId) {
    if (_setupScoreCache.containsKey(setupId)) return _setupScoreCache[setupId];
    final entries = ratingEntriesForSetup(setupId);
    final score = entries.isEmpty
        ? null
        : RatingScoreService.setupScore(
            entries.map((e) => (metrics: _applicableMetricsForBike(e.bike), values: e.metricValues)),
          );
    _setupScoreCache[setupId] = score;
    return score;
  }

  Map<String, double> metricScoresForSetup(String setupId) {
    final entries = ratingEntriesForSetup(setupId);
    if (entries.isEmpty) return const {};
    return RatingScoreService.setupMetricScores(
      entries.map((e) => (metrics: _applicableMetricsForBike(e.bike), values: e.metricValues)),
    );
  }

  Map<String, RatingMetric> get allRatingMetricsById => {
        for (final rating in _ratings.values)
          for (final metric in rating.metrics) metric.id: metric,
      };

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
      metricsList: updated.metrics.asMap().entries.map((entry) =>
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
    await _consumeTaskRuleDelay(entry.taskRule);
  }

  /// Note this is not undone when the entry is deleted again.
  Future<void> _consumeTaskRuleDelay(String taskRuleId) async {
    final rule = _taskRules[taskRuleId];
    if (rule == null || rule.delay == null) return;
    await editTaskRule(rule.copyWith(delay: null));
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
        // A brand-new component: every installation is a new row, so assign
        // fresh stable ids (avoids PK collisions when duplicating components).
        inst.copyWith(id: const Uuid().v4(), componentId: updated.id).toCompanion()
      ).toList(),
    );
  }

  Future<void> editPerson(Person person, {List<ValueUnitConversion> conversions = const []}) async {
    final updated = person.copyWith(lastModified: DateTime.now().toUtc());
    await database.transaction(() async {
      await database.personsDao.updatePersonWithData(
        person: updated.toCompanion(),
        adjustmentsList: updated.adjustments.asMap().entries.map((entry) =>
          entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
        ).toList(),
      );
      for (final c in conversions) {
        await database.setupsDao.convertAdjustmentValues(
          c.adjustmentId,
          (v) => convertUnit(v, c.from, c.to),
        );
      }
    });
  }

  Future<void> editBike(Bike bike) async {
    final gearChanged = _bikes[bike.id]?.stravaGear != bike.stravaGear;
    
    final updated = bike.copyWith(lastModified: DateTime.now().toUtc());
    await database.bikesDao.updateBike(updated.toCompanion());
    
    if (gearChanged) await refreshTaskEntrySnapshots();
  }

  Future<void> editComponent(Component component, {List<ValueUnitConversion> conversions = const []}) async {
    // Installation history (which bike, when) and the component's initial stats
    // both feed into its computed stats, and therefore into the snapshots of any
    // task entries linked to it. Live component stats recompute via SQL joins,
    // but persisted task-entry snapshots must be recomputed explicitly.
    final old = _components[component.id];
    final statsInputsChanged = old == null ||
        !listEquals(old.installations, component.installations) ||
        old.initialDistance != component.initialDistance ||
        old.initialElevationGain != component.initialElevationGain ||
        old.initialMovingTime != component.initialMovingTime ||
        old.initialElapsedTime != component.initialElapsedTime ||
        old.initialActivityCount != component.initialActivityCount;

    final updated = component.copyWith(lastModified: DateTime.now().toUtc());
    await database.transaction(() async {
      await database.componentsDao.updateComponentWithData(
        component: updated.toCompanion(),
        adjustmentsList: updated.adjustments.asMap().entries.map((entry) =>
          entry.value.toCompanion(componentId: updated.id, orderIndex: entry.key)
        ).toList(),
        installationsList: updated.installations.map((inst) =>
          // Preserve the stable installation ids across edits; only normalise the
          // owning componentId.
          inst.copyWith(componentId: updated.id).toCompanion()
        ).toList(),
      );
      for (final c in conversions) {
        await database.setupsDao.convertAdjustmentValues(
          c.adjustmentId,
          (v) => convertUnit(v, c.from, c.to),
        );
      }
    });

    if (statsInputsChanged) await refreshTaskEntrySnapshots();
  }

  Future<void> archiveComponent(Component component, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    final event = Archival(
      componentId: component.id,
      dateTimeUTC: when.toUtc(),
      dateTimeLocal: when,
    );
    await editComponent(
      component.copyWith(installations: [...component.installations, event]),
    );
  }

  Future<void> unarchiveComponent(Component component) async {
    final updated = List<Installation>.from(component.installations);
    final idx = updated.lastIndexWhere((i) => i is Archival);
    if (idx == -1) return;
    updated.removeAt(idx);
    await editComponent(component.copyWith(installations: updated));
  }

  Future<void> editRating(Rating rating, {List<ValueUnitConversion> conversions = const []}) async {
    final updated = rating.copyWith(lastModified: DateTime.now().toUtc());
    await database.transaction(() async {
      await database.ratingsDao.updateRatingWithData(
        rating: updated.toCompanion(),
        metricsList: updated.metrics.asMap().entries.map((entry) =>
          entry.value.toCompanion(ratingId: updated.id, orderIndex: entry.key)
        ).toList(),
      );
      for (final c in conversions) {
        await database.ratingEntriesDao.convertMetricValues(
          c.adjustmentId,
          (v) => convertUnit(v, c.from, c.to),
        );
      }
    });
  }

  Future<void> addSetup(Setup setup) async {
    final updated = setup.copyWith(lastModified: DateTime.now().toUtc());
    await database.setupsDao.insertSetupWithValues(
      setup: updated.toCompanion(),
      bikeValues: updated.bikeAdjustmentValues,
      personValues: updated.personAdjustmentValues,
    );
  }

  Future<void> editSetup(Setup setup) async {
    final updated = setup.copyWith(lastModified: DateTime.now().toUtc());
    await database.setupsDao.updateSetupWithValues(
      setup: updated.toCompanion(),
      bikeValues: setup.bikeAdjustmentValues,
      personValues: setup.personAdjustmentValues,
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

    // Re-derive the in-memory window from the database so new, changed, or
    // deleted activities show everywhere (list, calendar) and not only in views
    // that query the DB directly. Reloads the full loaded window to keep scroll.
    await reloadStravaWindow();
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
    _filteredStravaActivities = {};
    _stravaAthletes = {};
    _stravaGears = {};
    _stravaOffset = 0;
    _hasMoreStrava = true;

    // Wiping all activities (disconnect/unlink) means task-entry snapshots must
    // fall back to each component/bike's initial-only stats; otherwise they keep
    // showing distances from activities that no longer exist.
    await refreshTaskEntrySnapshots();
    _dataChanged();
  }
}

class ComponentInstallation {
  final Component component;
  final Installation installation;
  final String? originParent;
  final InstallationParentType? originParentType;
  final bool isInitial;

  ComponentInstallation({
    required this.component,
    required this.installation,
    this.originParent,
    this.originParentType,
    this.isInitial = false,
  });

  String get label {
    final verb = isInitial
        ? 'Added'
        : switch (installation.parentType) {
            InstallationParentType.bike => 'Installed',
            InstallationParentType.none => 'Uninstalled',
            InstallationParentType.archived => 'Archived',
          };
    return "$verb ${component.name}";
  }

  String get shortLabel {
    final symbol = isInitial
        ? '+'
        : switch (installation.parentType) {
            InstallationParentType.bike => '>',
            InstallationParentType.none => '<',
            InstallationParentType.archived => 'x',
          };
    return "$symbol ${component.name}";
  }
}
