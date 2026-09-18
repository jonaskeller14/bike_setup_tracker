import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/activity_rate_window.dart';
import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/component_installation.dart';
import '../models/component_stats.dart';
import '../models/installation.dart';
import '../models/person.dart';
import '../models/rating/rating.dart';
import '../models/rating/rating_association.dart';
import '../models/rating/rating_entry.dart';
import '../models/rating/rating_metric.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/strava/strava_scope.dart';
import '../models/task/task_association.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../services/backup_service.dart';
import '../services/component_hierarchy_resolver.dart';
import '../services/rating_score_service.dart';
import '../services/setup_resolution_service.dart';
import '../services/task_forecast_service.dart';
import '../services/task_status_service.dart';
import '../utils/unit_conversion.dart';
import 'strava_paging_controller.dart';

class AppRepository extends ChangeNotifier {

  // ---------------------------------------------------------------------------
  // CORE STATE & LIFECYCLE
  // ---------------------------------------------------------------------------

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
    'bikes',
    'components',
    'persons',
    'ratings',
    'ratingEntries',
    'taskRules',
    'taskEntries',
    'setups',
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

  AppRepository(this.database) {
    _strava = StravaPagingController(
      database: database,
      scope: _currentStravaScope,
      onLoadingChanged: notifyListeners,
      onWindowChanged: _dataChanged,
    );
    _initStreams();
  }

  Future<void> initialize() async {
    unawaited(BackupService.deleteOldBackups());
    unawaited(initialStravaLoad());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _strava.dispose();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  /// Disposes and waits for every stream subscription to actually cancel.
  @visibleForTesting
  Future<void> disposeAndAwaitCancellation() async {
    _isDisposed = true;
    _strava.dispose();
    final cancellations = _subscriptions.map((s) => s.cancel()).toList(growable: false);
    super.dispose();
    await Future.wait(cancellations);
  }

  // ---------------------------------------------------------------------------
  // RAW STATE FROM DB (read-only cache for immediate access)
  // ---------------------------------------------------------------------------

  Map<String, Person> _persons = {};
  Map<String, Bike> _bikes = {};
  Map<String, Setup> _setups = {};
  Map<String, Component> _components = {};
  ComponentHierarchyResolver? _componentHierarchyCache;
  Map<String, Rating> _ratings = {};
  Map<String, RatingEntry> _ratingEntries = {};
  Map<String, TaskRule> _taskRules = {};
  Map<String, TaskEntry> _taskEntries = {};
  Map<int, StravaAthlete> _stravaAthletes = {};
  Map<String, StravaGear> _stravaGears = {};
  Map<String, ComponentStats> _componentStats = {};
  Map<String, ComponentStats> _bikeStats = {};
  Map<String, ActivityRateWindow> _bikeActivityRates = {};
  Map<String, dynamic> _currentAdjustmentValues = {};

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
  Map<int, StravaActivity> get stravaActivities => _strava.activities;
  Map<String, StravaGear> get stravaGears => _stravaGears;
  Map<String, ComponentStats> get componentStats => _componentStats;
  Map<String, ComponentStats> get bikeStats => _bikeStats;
  Map<String, ActivityRateWindow> get bikeActivityRates => _bikeActivityRates;
  Map<String, dynamic> get currentAdjustmentValues => _currentAdjustmentValues;

  ComponentHierarchyResolver get componentHierarchy =>
      _componentHierarchyCache ??= ComponentHierarchyResolver(
          _components,
          deletedComponentIds: _deletedComponents.map((component) => component.id).toSet(),
        );

  Set<String> affectedDescendantIds(String componentId, {DateTime? atUTC}) =>
      componentHierarchy.descendantsOf(componentId, atUTC: atUTC);

  List<Component> affectedDescendants(String componentId, {DateTime? atUTC}) =>
      affectedDescendantIds(componentId, atUTC: atUTC)
          .map<Component?>((id) => _components[id])
          .whereType<Component>()
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

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
  // DB STREAMS & CHANGE PROPAGATION
  // ---------------------------------------------------------------------------

  void _initStreams() {
    _subscriptions.add(database.bikesDao.watchAllBikes().listen((list) {
      _bikes = {for (var b in list) b.id: b.toModel()};
      _markInitialStreamFired('bikes');
      _dataChanged();
    }));

    _subscriptions.add(database.componentsDao.watchAllComponentsWithData().listen((list) {
      _componentHierarchyCache = null;
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

    _subscriptions.add(database.stravaDao
        .watchBikeActivityRates(
          sampleSize: TaskForecastService.sampleSize,
          maxLookback: TaskForecastService.maxLookback,
        )
        .listen((map) {
      _bikeActivityRates = map;
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
      _componentHierarchyCache = null;
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
    _taskForecastCache.clear();
    _latestTaskEntryByRuleCache = null;
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
    _componentHierarchyCache = null;
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
          totalStats: _componentStats[entry.key] ?? entry.value.initialStats,
        )
    };

    _setupTags = SetupResolutionService.extractAllTags(_setups.values);
    _taskRuleTags = _taskRules.values.map((tr) => tr.tags).expand((tags) => tags).toSet();
  }

  // ---------------------------------------------------------------------------
  // FILTERING STATE
  // ---------------------------------------------------------------------------

  String? _selectedBike;
  final Set<String> _selectedSetupTags = {};
  bool _showBookmarkedSetupsOnly = false;
  final Set<TaskPriority> _selectedTaskPriorities = TaskPriority.values.toSet();
  final Set<String> _selectedTaskRuleTags = {};
  Set<String> _setupTags = {};
  Set<String> _taskRuleTags = {};

  String? get selectedBike => _selectedBike;
  Set<String> get selectedSetupTags => _selectedSetupTags;
  bool get showBookmarkedSetupsOnly => _showBookmarkedSetupsOnly;
  Set<TaskPriority> get selectedTaskPriorities => _selectedTaskPriorities;
  Set<String> get selectedTaskRuleTags => _selectedTaskRuleTags;
  Set<String> get setupTags => _setupTags;
  Set<String> get taskRuleTags => _taskRuleTags;
  bool get hasActiveTaskPriorityFilter => !setEquals(_selectedTaskPriorities, TaskPriority.values.toSet());
  bool get hasActiveTaskRuleTagFilter => _selectedTaskRuleTags.isNotEmpty;
  bool get hasActiveTaskRuleNarrowing => hasActiveTaskPriorityFilter || hasActiveTaskRuleTagFilter;

  Map<String, Bike> _filteredBikes = {};
  Map<String, Person> _filteredPersons = {};
  Map<String, Rating> _filteredRatings = {};
  Map<String, Component> _filteredComponents = {};
  Map<String, Setup> _filteredSetups = {};
  Map<String, RatingEntry> _filteredRatingEntries = {};
  Map<String, TaskRule> _filteredTaskRules = {};
  Map<String, TaskEntry> _filteredTaskEntries = {};
  Map<String, TaskRule> _filteredOpenTaskRules = {};
  List<ResolvedComponentInstallation> _filteredInstallations = [];

  Map<String, Bike> get filteredBikes => _filteredBikes;
  Map<String, Person> get filteredPersons => _filteredPersons;
  Map<String, Rating> get filteredRatings => _filteredRatings;
  Map<String, Component> get filteredComponents => _filteredComponents;
  Map<String, Component> get archivedComponents => {
        for (final entry in _components.entries)
          if (componentHierarchy.isEffectivelyArchived(entry.key)) entry.key: entry.value
      };
  Map<String, Setup> get filteredSetups => _filteredSetups;
  Map<String, RatingEntry> get filteredRatingEntries => _filteredRatingEntries;
  Map<String, TaskRule> get filteredTaskRules => _filteredTaskRules;
  Map<String, TaskRule> get filteredOpenTaskRules => _filteredOpenTaskRules;
  int get filteredOpenTaskRulesCount => _filteredOpenTaskRules.length;
  Map<String, TaskEntry> get filteredTaskEntries => _filteredTaskEntries;
  Map<int, StravaActivity> get filteredStravaActivities => _strava.activities;
  List<ResolvedComponentInstallation> get filteredInstallations => _filteredInstallations;

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
    _strava.reloadIfScopeChanged();  // re-pages Strava if the bike scope changed
    _filterInstallations();
  }

  void _filterBikes() {
    _filteredBikes = selectedBike == null
        ? bikes
        : Map.fromEntries(bikes.entries.where((entry) => entry.key == selectedBike));
  }

  void _filterComponents() {
    final hierarchy = componentHierarchy;
    _filteredComponents = Map.fromEntries(components.entries.where((entry) {
      final placement = hierarchy.resolveCurrent(entry.key);
      if (placement.isArchived || placement.isDeleted) return false;
      return selectedBike == null || placement.bikeId == selectedBike;
    }));
  }

  void _filterSetups() {
    _filteredSetups = Map.fromEntries(setups.entries.where((entry) =>
      (selectedBike == null ? true : entry.value.bike == selectedBike) &&
      (selectedSetupTags.isEmpty ? true : entry.value.tags.containsAll(selectedSetupTags)) &&
      (_showBookmarkedSetupsOnly ? entry.value.isBookmarked : true)
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
      switch (rating.association) {
        case GlobalRatingAssociation(): return true;
        case PersonRatingAssociation(): return true;
        case BikeRatingAssociation(:final bikeId): return _selectedBike == null ? true : bikeId == _selectedBike;
        case ComponentRatingAssociation(:final componentId): return _selectedBike == null ? true : filteredComponents.values.any((c) => c.id == componentId);
        case ComponentTypeRatingAssociation(:final componentTypeStr): return _selectedBike == null ? true : filteredComponents.values.any((c) => c.componentType.toString() == componentTypeStr);
      }
    }));
  }

  void _filterTaskRules() {
    _filteredTaskRules = Map.fromEntries(
      taskRules.entries.where((entry) {
        final rule = entry.value;
        if (!_selectedTaskPriorities.contains(rule.priority)) return false;

        if (selectedTaskRuleTags.isNotEmpty && !entry.value.tags.containsAll(selectedTaskRuleTags)) return false;
        return _isTaskRuleInCurrentScope(rule);
      }),
    );

    _filteredOpenTaskRules = Map.fromEntries(
      _filteredTaskRules.entries.where(
        (entry) => !taskEntries.values.any((te) => te.taskRule == entry.key),
      ),
    );
  }

  bool _isTaskRuleInCurrentScope(TaskRule rule) {
    switch (rule.association) {
      case GeneralTaskAssociation():
        return true;
      case BikeTaskAssociation(:final id):
        return _selectedBike == null || id == _selectedBike;
      case ComponentTaskAssociation(:final id):
        if (!_components.containsKey(id)) return false;
        final placement = componentHierarchy.resolveCurrent(id);
        if (placement.isArchived || placement.isDeleted) return false;
        return _selectedBike == null || placement.bikeId == _selectedBike;
    }
  }

  void _filterTaskEntries() {
    _filteredTaskEntries = Map.fromEntries(
      taskEntries.entries.where(
        (entry) => _filteredTaskRules.containsKey(entry.value.taskRule),
      ),
    );
  }

  void _filterInstallations() {
    _filteredInstallations = [];
    final hierarchy = componentHierarchy;
    for (final component in components.values) {
      final sorted = List<Installation>.from(component.installations)
        ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

      for (int i = 0; i < sorted.length; i++) {
        final installation = sorted[i];
        if (installation.dateTimeUTC.millisecondsSinceEpoch == 0) continue;

        final previousInstallation = i > 0 ? sorted[i-1] : null;
        final originParent = previousInstallation?.parent;
        final isInitial = i == 0;

        final ci = ResolvedComponentInstallation(
          component: component,
          installation: installation,
          originParent: originParent,
          originParentType: previousInstallation?.parentType,
          isInitial: isInitial,
        );

        final targetBike = hierarchy.bikeAt(component.id, installation.dateTimeUTC);
        final originTime = installation.dateTimeUTC.subtract(const Duration(microseconds: 1));
        final originBike = hierarchy.bikeAt(component.id, originTime);
        if (selectedBike == null || targetBike == selectedBike || originBike == selectedBike) {
          _filteredInstallations.add(ci);
        }
      }
    }
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

  void setShowBookmarkedSetupsOnly(bool newValue) {
    if (_showBookmarkedSetupsOnly == newValue) return;
    _showBookmarkedSetupsOnly = newValue;
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
  // TASKS: SNAPSHOTS, STATUS & DERIVED LISTS
  // ---------------------------------------------------------------------------

  /// Day-quantised memo behind [getTaskRuleForecast].
  final Map<String, TaskForecast?> _taskForecastCache = {};
  DateTime? _taskForecastDay;

  /// Lazily built index behind [_taskRuleInputs], dropped on every data change.
  Map<String, TaskEntry>? _latestTaskEntryByRuleCache;

  /// The newest entry per rule. [getTaskRuleStatus] runs inside list-card
  /// `build()`s, so rescanning every entry per rule made rendering a task or
  /// garage list O(rules x entries); this makes each lookup a map read.
  Map<String, TaskEntry> get _latestTaskEntryByRule {
    final cached = _latestTaskEntryByRuleCache;
    if (cached != null) return cached;
    final map = <String, TaskEntry>{};
    for (final entry in _taskEntries.values) {
      final newest = map[entry.taskRule];
      if (newest == null || entry.dateTimeUTC.isAfter(newest.dateTimeUTC)) {
        map[entry.taskRule] = entry;
      }
    }
    return _latestTaskEntryByRuleCache = map;
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
  Future<void> refreshTaskEntrySnapshots({Set<String>? componentIds}) async {
    final dbEntries = componentIds == null
        ? await database.taskDao.getAllEntriesBypass()
        : await database.taskDao.getEntriesForComponentIdsBypass(componentIds);
    final entries = dbEntries
        .map((e) => e.toModel())
        .toList();

    // Issued together rather than one await at a time: each stats query is a
    // round-trip to the database isolate, and awaiting them serially stalls on
    // that latency once per entry.
    final snapshots = await Future.wait(entries.map((entry) => getStatsAt(
      componentId: entry.association.componentId,
      bikeId: entry.association.bikeId,
      date: entry.dateTimeUTC,
    )));

    final changed = [
      for (var i = 0; i < entries.length; i++)
        if (snapshots[i] != entries[i].snapshot) entries[i].copyWith(snapshot: snapshots[i]),
    ];
    if (changed.isEmpty) return;

    // One transaction: written individually, every upsert re-emits the task
    // entry stream, which re-resolves all setups on the UI isolate.
    await database.transaction(() async {
      for (final entry in changed) {
        await database.taskDao.upsertEntry(entry.toCompanion());
      }
    });
  }

  /// What a rule is measured against: its most recent entry, when its component
  /// went on its current bike, and the stats the interval counts.
  ({TaskEntry? lastEntry, DateTime? installationDate, ComponentStats stats}) _taskRuleInputs(TaskRule rule) {
    DateTime? installationDate;
    if (rule.association case ComponentTaskAssociation(:final id)) {
      installationDate = componentHierarchy.effectiveBikeSinceAt(
        id,
        DateTime.now().toUtc(),
      );
    }

    final stats = switch (rule.association) {
      ComponentTaskAssociation(:final id) => _componentStats[id] ?? ComponentStats.zero(),
      BikeTaskAssociation(:final id) => _bikeStats[id] ?? ComponentStats.zero(),
      GeneralTaskAssociation() => ComponentStats.zero(),
    };

    return (
      lastEntry: _latestTaskEntryByRule[rule.id],
      installationDate: installationDate,
      stats: stats,
    );
  }

  TaskStatus getTaskRuleStatus(TaskRule rule) {
    final inputs = _taskRuleInputs(rule);

    return TaskStatusService.calculate(
      rule: rule,
      currentStats: inputs.stats,
      now: DateTime.now().toUtc(),
      lastEntry: inputs.lastEntry,
      componentInstallationDate: inputs.installationDate,
    );
  }

  /// Memoised per rule until the data changes or the day rolls over — the only
  /// two things that can move a forecast — so the cards may ask on every build.
  TaskForecast? getTaskRuleForecast(TaskRule rule) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_taskForecastDay != today) {
      _taskForecastCache.clear();
      _taskForecastDay = today;
    }
    if (_taskForecastCache.containsKey(rule.id)) return _taskForecastCache[rule.id];

    final inputs = _taskRuleInputs(rule);

    return _taskForecastCache[rule.id] = TaskForecastService.predict(
      rule: rule,
      currentStats: inputs.stats,
      now: now.toUtc(),
      bikeRates: _bikeActivityRates,
      component: _components[rule.association.componentId],
      lastEntry: inputs.lastEntry,
      componentInstallationDate: inputs.installationDate,
    );
  }

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

  List<TaskRuleWithStatus> get actionableTaskRules {
    final actionable = _filteredTaskRules.values
        .map((rule) => TaskRuleWithStatus(rule: rule, status: getTaskRuleStatus(rule)))
        .where((taskRule) => taskRule.status.isDue)
        .toList();
    actionable.sort((a, b) {
      final statusComparison = b.status.type.index.compareTo(a.status.type.index);
      if (statusComparison != 0) return statusComparison;
      final priorityComparison = b.rule.priority.index.compareTo(a.rule.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      final progressComparison = b.status.progress.compareTo(a.status.progress);
      if (progressComparison != 0) return progressComparison;
      return a.rule.id.compareTo(b.rule.id);
    });
    return actionable;
  }

  List<TaskRuleWithStatus> get upcomingTaskRules {
    final upcoming = _filteredTaskRules.values
        .map((rule) => TaskRuleWithStatus(rule: rule, status: getTaskRuleStatus(rule)))
        .where((taskRule) => taskRule.status.type == TaskStatusType.upcoming)
        .toList();
    upcoming.sort((a, b) {
      final progressComparison = b.status.progress.compareTo(a.status.progress);
      if (progressComparison != 0) return progressComparison;
      final priorityComparison = b.rule.priority.index.compareTo(a.rule.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return a.rule.id.compareTo(b.rule.id);
    });
    return upcoming;
  }

  int get actionableTaskRulesCount => actionableTaskRules.length;

  TaskStatusType? get worstActionableTaskStatus {
    final actionable = actionableTaskRules;
    return actionable.isEmpty ? null : actionable.first.status.type;
  }

  bool get hasScopeActionableTaskRules => _taskRules.values
      .where(_isTaskRuleInCurrentScope)
      .map(getTaskRuleStatus)
      .any((status) => status.isDue);

  bool get hasTaskRulesInCurrentScope =>
      _taskRules.values.any(_isTaskRuleInCurrentScope);

  /// Open (non-completed) task rules for a bike, including rules attached to its components.
  List<TaskRuleWithStatus> openTaskRulesForBike(String bikeId) {
    final rules = _taskRules.values.where((rule) {
      return switch (rule.association) {
        BikeTaskAssociation(:final id) => id == bikeId,
        ComponentTaskAssociation(:final id) => componentHierarchy.currentBike(id) == bikeId,
        GeneralTaskAssociation() => false,
      };
    });
    return _openTaskRulesWithStatus(rules);
  }

  /// Open (non-completed) task rules for a single component.
  List<TaskRuleWithStatus> openTaskRulesForComponent(String componentId) {
    return _openTaskRulesWithStatus(_taskRules.values.where((rule) => rule.association.componentId == componentId));
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
    completed.sort((a, b) {
      final modifiedComparison = b.rule.lastModified.compareTo(a.rule.lastModified);
      return modifiedComparison != 0 ? modifiedComparison : a.rule.id.compareTo(b.rule.id);
    });
    return completed;
  }

  // ---------------------------------------------------------------------------
  // RATINGS: SCORES & LOOKUPS
  // ---------------------------------------------------------------------------

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

  String? resolvedSetupIdFor(RatingEntry entry) => resolveSetupId(bikeId: entry.bike, atUtc: entry.dateTimeUTC);

  List<RatingMetric> _applicableMetricsForBike(String bikeId) => (_applicableMetricsByBike ??= {}).putIfAbsent(
        bikeId,
        () => _computeApplicableMetricsForBike(bikeId),
      );

  List<RatingMetric> _computeApplicableMetricsForBike(String bikeId) {
    final bikePerson = _bikes[bikeId]?.person;
    final hierarchy = componentHierarchy;
    final bikeComponents = _components.values.where(
      (component) => hierarchy.currentBike(component.id) == bikeId,
    );
    final componentIds = bikeComponents.map((c) => c.id).toSet();
    final componentTypes = bikeComponents.map((c) => c.componentType.toString()).toSet();

    final metrics = <RatingMetric>[];
    for (final rating in _ratings.values) {
      final applies = switch (rating.association) {
        GlobalRatingAssociation() => true,
        BikeRatingAssociation(bikeId: final ratingBikeId) => ratingBikeId == bikeId,
        PersonRatingAssociation(:final personId) => personId == bikePerson,
        ComponentRatingAssociation(:final componentId) => componentIds.contains(componentId),
        ComponentTypeRatingAssociation(:final componentTypeStr) => componentTypes.contains(componentTypeStr),
      };
      if (applies) metrics.addAll(rating.metrics);
    }
    return metrics;
  }

  EntryScore? entryScore(RatingEntry entry) =>
      RatingScoreService.scoreEntry(_applicableMetricsForBike(entry.bike), entry.metricValues);

  EntryScoreBreakdown entryBreakdown(RatingEntry entry) =>
      RatingScoreService.breakdown(_applicableMetricsForBike(entry.bike), entry.metricValues);

  List<RatingEntry> ratingEntriesForSetup(String setupId) => _entriesBySetup[setupId] ?? const [];

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

  // ---------------------------------------------------------------------------
  // STRAVA: PAGING, QUERIES & SYNC
  // ---------------------------------------------------------------------------

  late final StravaPagingController _strava;
  int _stravaOperationVersion = 0;

  bool get hasMoreStrava => _strava.hasMore;
  bool get isLoadingMoreStrava => _strava.isLoadingMore;
  bool get stravaSortAscending => _strava.sortAscending;

  Stream<List<StravaActivity>> get stravaActivitiesWithPosition => _strava.activitiesWithPosition;
  Future<List<StravaActivity>> get latestStravaActivities => _strava.latest;
  Future<List<StravaActivity>> getFilteredStravaActivitiesWithPosition() => _strava.filteredActivitiesWithPosition();
  Future<List<StravaActivity>> searchStravaActivities(String query) => _strava.search(query);
  Future<StravaActivity?> getStravaActivity(int id) => _strava.getActivity(id);

  Future<void> initialStravaLoad() => _strava.initialLoad();
  Future<void> reloadStravaWindow() => _strava.reloadWindow();
  Future<void> setStravaSortOrder(bool ascending) => _strava.setSortOrder(ascending);
  Future<void> loadMoreStravaActivities() => _strava.loadMore();

  /// Debug helper to override the pagination chunk size in tests.
  void debugSetStravaLimit(int limit) => _strava.limit = limit;

  StravaScope _currentStravaScope() => StravaScope.forBike(bikes[_selectedBike]);
  bool get selectedBikeHasNoStravaGear => _currentStravaScope() is NoStravaActivities;

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
    if (athletes.isEmpty) return;
    await database.transaction(() async {
      for (var a in athletes) {
        await database.stravaDao.upsertAthlete(a.toCompanion());
      }
    });
  }

  Future<void> setStravaGears(Iterable<StravaGear> gears) async {
    await database.stravaDao.syncGears(gears.map((g) => g.toCompanion()));
  }

  Future<void> clearStravaData() async {
    _stravaOperationVersion++;

    await database.delete(database.stravaActivities).go();
    await database.delete(database.stravaAthletes).go();
    await database.delete(database.stravaGears).go();
    _strava.clear();
    _stravaAthletes = {};
    _stravaGears = {};

    // Wiping all activities (disconnect/unlink) means task-entry snapshots must
    // fall back to each component/bike's initial-only stats; otherwise they keep
    // showing distances from activities that no longer exist.
    await refreshTaskEntrySnapshots();
    _dataChanged();
  }

  // ---------------------------------------------------------------------------
  // TRASH: SOFT DELETE & RESTORE
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

  Future<void> removeBikes(Iterable<Bike> bikes) async {
    if (bikes.isEmpty) return;
    final affected = _componentsEverOnBikes(bikes.map((bike) => bike.id).toSet());
    await database.transaction(() async {
      for (var bike in bikes) {
        await database.bikesDao.deleteBike(bike.id);
      }
    });
    await refreshTaskEntrySnapshots(componentIds: affected);
  }

  /// Components whose stats move when [bikeIds] are deleted or restored: the
  /// ones ever installed on such a bike, plus everything ever nested under them
  /// (a child inherits its parent's bike, so it gains and loses the same credit).
  Set<String> _componentsEverOnBikes(Set<String> bikeIds) {
    final hierarchy = componentHierarchy;
    final affected = <String>{};
    for (final component in _components.values) {
      final wasOnBike = component.installations.any(
        (installation) => installation is BikeInstallation && bikeIds.contains(installation.bikeId),
      );
      if (!wasOnBike) continue;
      affected
        ..add(component.id)
        ..addAll(hierarchy.historicalDescendantsOf(component.id));
    }
    return affected;
  }

  Future<void> restoreBikes(Iterable<Bike> bikes) async {
    if (bikes.isEmpty) return;
    final affected = _componentsEverOnBikes(bikes.map((bike) => bike.id).toSet());
    await database.transaction(() async {
      for (var bike in bikes) {
        final updated = bike.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.bikesDao.updateBike(updated.toCompanion());
      }
    });
    await refreshTaskEntrySnapshots(componentIds: affected);
  }

  Future<void> removeComponents(Iterable<Component> components) async {
    if (components.isEmpty) return;
    await database.transaction(() async {
      for (var component in components) {
        await database.componentsDao.deleteComponent(component.id);
      }
    });
  }

  Future<void> restoreComponents(Iterable<Component> components) async {
    if (components.isEmpty) return;
    await database.transaction(() async {
      for (var component in components) {
        final updated = component.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.componentsDao.updateComponent(updated.toCompanion());
      }
    });
  }

  Future<void> removeSetups(Iterable<Setup> setups) async {
    if (setups.isEmpty) return;
    await database.transaction(() async {
      for (var setup in setups) {
        await database.setupsDao.deleteSetup(setup.id);
      }
    });
  }

  Future<void> restoreSetups(Iterable<Setup> setups) async {
    if (setups.isEmpty) return;
    await database.transaction(() async {
      for (var setup in setups) {
        final updated = setup.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.setupsDao.updateSetup(updated.toCompanion());
      }
    });
  }

  Future<void> removePersons(Iterable<Person> persons) async {
    if (persons.isEmpty) return;
    await database.transaction(() async {
      for (var person in persons) {
        await database.personsDao.deletePerson(person.id);
      }
    });
  }

  Future<void> restorePersons(Iterable<Person> persons) async {
    if (persons.isEmpty) return;
    await database.transaction(() async {
      for (var person in persons) {
        final updated = person.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.personsDao.updatePerson(updated.toCompanion());
      }
    });
  }

  Future<void> removeRatings(Iterable<Rating> ratings) async {
    if (ratings.isEmpty) return;
    await database.transaction(() async {
      for (var rating in ratings) {
        await database.ratingsDao.deleteRating(rating.id);
      }
    });
  }

  Future<void> restoreRatings(Iterable<Rating> ratings) async {
    if (ratings.isEmpty) return;
    await database.transaction(() async {
      for (var rating in ratings) {
        final updated = rating.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.ratingsDao.updateRating(updated.toCompanion());
      }
    });
  }

  Future<void> removeRatingEntries(Iterable<RatingEntry> entries) async {
    if (entries.isEmpty) return;
    await database.transaction(() async {
      for (final entry in entries) {
        await database.ratingEntriesDao.deleteRatingEntry(entry.id);
      }
    });
  }

  Future<void> restoreRatingEntries(Iterable<RatingEntry> entries) async {
    if (entries.isEmpty) return;
    await database.transaction(() async {
      for (final entry in entries) {
        final updated = entry.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.ratingEntriesDao.updateRatingEntry(updated.toCompanion());
      }
    });
  }

  Future<void> removeTaskRules(Iterable<TaskRule> rules) async {
    if (rules.isEmpty) return;
    await database.transaction(() async {
      for (var rule in rules) {
        await database.taskDao.deleteRule(rule.id);
      }
    });
  }

  Future<void> restoreTaskRules(Iterable<TaskRule> rules) async {
    if (rules.isEmpty) return;
    await database.transaction(() async {
      for (var rule in rules) {
        final updated = rule.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.taskDao.updateRule(updated.toCompanion());
      }
    });
  }

  Future<void> removeTaskEntries(Iterable<TaskEntry> entries) async {
    if (entries.isEmpty) return;
    await database.transaction(() async {
      for (var entry in entries) {
        await database.taskDao.deleteEntry(entry.id);
      }
    });
  }

  Future<void> restoreTaskEntries(Iterable<TaskEntry> entries) async {
    if (entries.isEmpty) return;
    await database.transaction(() async {
      for (var entry in entries) {
        final updated = entry.copyWith(isDeleted: false, lastModified: DateTime.now().toUtc());
        await database.taskDao.updateEntry(updated.toCompanion());
      }
    });
  }

  // ---------------------------------------------------------------------------
  // WRITE OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> addRatingEntries(Iterable<RatingEntry> entries) async {
    if (entries.isEmpty) return;
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final entry in entries) {
        final updated = entry.copyWith(lastModified: now);
        await database.ratingEntriesDao.insertRatingEntryWithValues(
          entry: updated.toCompanion(),
          values: updated.metricValues,
        );
      }
    });
  }

  Future<void> editRatingEntry(RatingEntry entry) async {
    final updated = entry.copyWith(lastModified: DateTime.now().toUtc());
    await database.ratingEntriesDao.updateRatingEntryWithValues(
      entry: updated.toCompanion(),
      values: updated.metricValues,
    );
  }

  Future<void> addBikes(Iterable<Bike> bikes) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final bike in bikes) {
        final updated = bike.copyWith(lastModified: now);
        await database.bikesDao.insertBike(updated.toCompanion());
      }
    });
  }

  Future<void> addPersons(Iterable<Person> persons) async {
    if (persons.isEmpty) return;
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final person in persons) {
        final updated = person.copyWith(lastModified: now);
        await database.personsDao.insertPersonWithData(
          person: updated.toCompanion(),
          adjustmentsList: updated.adjustments.asMap().entries.map((entry) =>
            entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
          ).toList(),
        );
      }
    });
  }

  Future<void> addRatings(Iterable<Rating> ratings) async {
    if (ratings.isEmpty) return;
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final rating in ratings) {
        final updated = rating.copyWith(lastModified: now);
        await database.ratingsDao.insertRatingWithData(
          rating: updated.toCompanion(),
          metricsList: updated.metrics.asMap().entries.map((entry) =>
            entry.value.toCompanion(ratingId: updated.id, orderIndex: entry.key)
          ).toList(),
        );
      }
    });
  }

  Future<void> addTaskRules(Iterable<TaskRule> rules) async {
    if (rules.isEmpty) return;
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final rule in rules) {
        await database.taskDao.insertRule(rule.copyWith(lastModified: now).toCompanion());
      }
    });
  }

  Future<void> editTaskRules(Iterable<TaskRule> rules) async {
    final ruleList = rules.toList();
    if (ruleList.isEmpty) return;
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final rule in ruleList) {
        await database.taskDao.updateRule(rule.copyWith(lastModified: now).toCompanion());
      }
    });
  }

  Future<void> addTaskEntries(Iterable<TaskEntry> entries) async {
    final entryList = entries.toList();
    if (entryList.isEmpty) return;
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final entry in entryList) {
        await database.taskDao.insertEntry(entry.copyWith(lastModified: now).toCompanion());
      }
      for (final taskRuleId in entryList.map((entry) => entry.taskRule).toSet()) {
        await _consumeTaskRuleDelay(taskRuleId);
      }
    });
  }

  /// Note this is not undone when the entry is deleted again.
  Future<void> _consumeTaskRuleDelay(String taskRuleId) async {
    final rule = _taskRules[taskRuleId];
    if (rule == null || rule.delay == null) return;
    await editTaskRules([rule.copyWith(delay: null)]);
  }

  Future<void> editTaskEntry(Iterable<TaskEntry> entries) async {
    if (entries.isEmpty) return;
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final entry in entries) {
        await database.taskDao.updateEntry(
          entry.copyWith(lastModified: now).toCompanion(),
        );
      }
    });
  }

  Future<void> addComponents(Iterable<Component> components) async {
    if (components.isEmpty) return;
    final now = DateTime.now().toUtc();
    final updateComponents = components.map((component) => component.copyWith(lastModified: now)).toList();
    ComponentHierarchyResolver({
      ..._components,
      for (final updated in updateComponents) updated.id: updated,
    }).validate();
    await database.transaction(() async {
      for (final updateComponent in updateComponents) {
        await database.componentsDao.insertComponentWithData(
          component: updateComponent.toCompanion(),
          adjustmentsList: updateComponent.adjustments.asMap().entries.map((entry) =>
            entry.value.toCompanion(componentId: updateComponent.id, orderIndex: entry.key)
          ).toList(),
          installationsList: updateComponent.installations.map((inst) =>
            inst.copyWith(id: const Uuid().v4(), componentId: updateComponent.id).toCompanion()
          ).toList(),
        );
      }
    });
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
    final statsInputsChanged = _componentStatsInputsChanged(component);
    final oldDescendants = componentHierarchy.historicalDescendantsOf(component.id);

    final updated = component.copyWith(lastModified: DateTime.now().toUtc());
    final candidateComponents = {..._components, updated.id: updated};
    final candidateHierarchy = ComponentHierarchyResolver(candidateComponents);
    candidateHierarchy.validate();  //FIXME: is error catched here or in parent?
    await database.transaction(() async {
      await _writeComponentWithData(updated);
      for (final c in conversions) {
        await database.setupsDao.convertAdjustmentValues(
          c.adjustmentId,
          (v) => convertUnit(v, c.from, c.to),
        );
      }
    });

    if (statsInputsChanged) {
      await refreshTaskEntrySnapshots(componentIds: {
        component.id,
        ...oldDescendants,
        ...candidateHierarchy.historicalDescendantsOf(component.id),
      });
    }
  }

  Future<void> editComponents(Iterable<Component> components) async {
    final componentList = components.toList();
    final changedComponentIds = componentList
        .where(_componentStatsInputsChanged)
        .map((component) => component.id)
        .toSet();
    final updates = componentList
        .map((c) => c.copyWith(lastModified: DateTime.now().toUtc()))
        .toList();
    final candidateComponents = {..._components};
    for (final updated in updates) {
      candidateComponents[updated.id] = updated;
    }
    final candidateHierarchy = ComponentHierarchyResolver(candidateComponents);
    candidateHierarchy.validate();  //FIXME: is error catched here or in parent?
    final affectedIds = <String>{...changedComponentIds};
    for (final componentId in changedComponentIds) {
      affectedIds
        ..addAll(componentHierarchy.historicalDescendantsOf(componentId))
        ..addAll(candidateHierarchy.historicalDescendantsOf(componentId));
    }

    await database.transaction(() async {
      for (final updated in updates) {
        await _writeComponentWithData(updated);
      }
    });

    if (changedComponentIds.isNotEmpty) {
      await refreshTaskEntrySnapshots(componentIds: affectedIds);
    }
  }

  /// Installation history (which bike, when) and the component's initial stats
  /// both feed into its computed stats, and therefore into the snapshots of any
  /// task entries linked to it. Live component stats recompute via SQL joins,
  /// but persisted task-entry snapshots must be recomputed explicitly.
  bool _componentStatsInputsChanged(Component component) {
    final old = _components[component.id];
    return old == null ||
        !listEquals(old.installations, component.installations) ||
        old.initialStats != component.initialStats;
  }

  Future<void> _writeComponentWithData(Component updated) {
    return database.componentsDao.updateComponentWithData(
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

  Future<void> addSetups(Iterable<Setup> setups) async {
    if (setups.isEmpty) return;
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final setup in setups) {
        final updated = setup.copyWith(lastModified: now);
        await database.setupsDao.insertSetupWithValues(
          setup: updated.toCompanion(),
          bikeValues: updated.bikeAdjustmentValues,
          personValues: updated.personAdjustmentValues,
        );
      }
    });
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
    _componentHierarchyCache = null;
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

  // ---------------------------------------------------------------------------
  // LEGACY IMPORT
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
}
