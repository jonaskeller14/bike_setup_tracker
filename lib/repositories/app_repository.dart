import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/daos/deleted_record_value.dart';
import '../database/mappers.dart';
import '../models/activity_rate_window.dart';
import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../models/component_stats.dart';
import '../models/context/context_position.dart';
import '../models/feedback/custom_issue.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';
import '../models/person.dart';
import '../models/recorded_value.dart';
import '../models/selected_data.dart';
import '../models/setup.dart';
import '../models/setup_history.dart';
import '../models/strava/activity_bounds.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_activity_query.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/task/task_association.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold/task_threshold.dart';
import '../services/backup_service.dart';
import '../services/component_hierarchy_resolver.dart';
import '../services/custom_issue_service.dart';
import '../services/feedback_open_issues_service.dart';
import '../services/feedback_ranking_service.dart';
import '../services/setup_resolution_service.dart';
import '../services/task_forecast_service.dart';
import '../services/task_status_service.dart';
import '../services/trash_cleanup_service.dart';
import '../utils/adjustment_value_type_check.dart';
import 'filter_controller.dart';
import 'filtered_view.dart';
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

  /// Listens to a stream [initialDataLoaded] waits for. A failure before the
  /// initial load completes (e.g. a corrupt row that fails to decode) fails
  /// [initialDataLoaded], so startup shows the error page instead of spinning
  /// forever. Later failures surface as uncaught errors, as before.
  void _listenInitial<T>(Stream<T> stream, void Function(T) onData) {
    void fail(Object error, StackTrace stack) {
      if (_initialDataCompleter.isCompleted) Error.throwWithStackTrace(error, stack);
      _initialDataCompleter.completeError(error, stack);
      // Startup awaits this only after migration; without a listener until
      // then the error would also be reported as uncaught.
      _initialDataCompleter.future.ignore();
    }

    _subscriptions.add(stream.listen(
      (data) {
        try {
          onData(data);
        } catch (e, s) {
          fail(e, s);
        }
      },
      onError: fail,
    ));
  }

  AppRepository(this.database) {
    filters = FilterController(
      onChanged: () {
        _filter();
        notifyListeners();
        onFiltersChanged?.call();
      },
    );
    _view = _buildView();
    _strava = StravaPagingController(
      database: database,
      query: _currentStravaQuery,
      onLoadingChanged: notifyListeners,
      onWindowChanged: _dataChanged,
    );
    _initStreams();
  }

  Future<void> initialize() async {
    unawaited(BackupService.deleteOldBackups());
    unawaited(initialStravaLoad());
    // Awaited, unlike the others: it has to finish before the UI mounts.
    await TrashCleanupService.run(database);
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
  Map<String, TaskRule> _taskRules = {};
  Map<String, TaskEntry> _taskEntries = {};
  Map<String, RideFeedback> _feedbacks = {};
  List<TestSessionDb> _testSessionRows = [];
  Map<String, TestSession> _testSessions = {};
  Map<int, StravaAthlete> _stravaAthletes = {};
  Map<String, StravaGear> _stravaGears = {};
  Map<String, ComponentStats> _componentStats = {};
  Map<String, ComponentStats> _bikeStats = {};
  Map<String, ActivityRateWindow> _bikeActivityRates = {};
  ActivityBounds _activityBounds = ActivityBounds.empty;
  Map<String, AdjustmentValue> _currentAdjustmentValues = {};
  SetupHistory _setupHistory = SetupHistory.empty;

  Map<String, Person> get persons => _persons;
  Map<String, Bike> get bikes => _bikes;
  Map<String, Setup> get setups => _setups;
  Map<String, Component> get components => _components;
  Map<String, TaskRule> get taskRules => _taskRules;
  Map<String, TaskEntry> get taskEntries => _taskEntries;
  Map<String, RideFeedback> get feedbacks => _feedbacks;
  Map<String, TestSession> get testSessions => _testSessions;
  Map<int, StravaAthlete> get stravaAthletes => _stravaAthletes;
  // Strava is paginated per active filter, so the loaded window is the filtered set.
  Map<int, StravaActivity> get stravaActivities => _strava.activities;
  Map<String, StravaGear> get stravaGears => _stravaGears;
  Map<String, ComponentStats> get componentStats => _componentStats;
  Map<String, ComponentStats> get bikeStats => _bikeStats;

  ComponentStats componentStatsOf(String componentId) =>
      _componentStats[componentId] ??
      _components[componentId]?.initialStats ??
      ComponentStats.zero;
  Map<String, ActivityRateWindow> get bikeActivityRates => _bikeActivityRates;
  ActivityBounds get activityBounds => _activityBounds;

  /// The earliest local day the date range can narrow: of setups, task entries,
  /// feedbacks and activities. Installations are left out, as a "since the beginning"
  /// install is dated at the epoch. `null` without any.
  DateTime? get firstEntryDay {
    var first = _activityBounds.firstStartLocal;
    final dates = _setups.values
        .map((s) => s.datetimeLocal)
        .followedBy(_taskEntries.values.map((e) => e.dateTimeLocal))
        .followedBy(_feedbacks.values.map((f) => f.dateTimeLocal));
    for (final date in dates) {
      if (first == null || date.isBefore(first)) first = date;
    }
    return first == null ? null : DateTime(first.year, first.month, first.day);
  }

  Map<String, AdjustmentValue> get currentAdjustmentValues => _currentAdjustmentValues;
  SetupHistory get setupHistory => _setupHistory;

  Map<String, List<AdjustmentValue>> recordedAdjustmentValues(Set<String> adjustmentIds) {
    final values = <String, List<AdjustmentValue>>{};
    for (final setup in _setups.values) {  // live setups only; see recordedValues for deleted ones
      for (final MapEntry(:key, :value) in setup.bikeAdjustmentValues.entries) {
        if (adjustmentIds.contains(key)) (values[key] ??= []).add(value);
      }
    }
    return values;
  }

  /// Every decodable value stored for [adjustmentId] (a component adjustment or
  /// person attribute), newest first. Soft-deleted setups are read from the
  /// database as they are held without values.
  Future<List<RecordedValue>> recordedValues(String adjustmentId) async {
    final type = _findAdjustment(adjustmentId)?.type;
    if (type == null) return const [];

    final recorded = <RecordedValue>[];
    for (final setup in _setups.values) {
      final value = setup.bikeAdjustmentValues[adjustmentId] ?? setup.personAdjustmentValues[adjustmentId];
      if (value == null || value is UnresolvedValue) continue;
      recorded.add(RecordedValue(
        recordId: setup.id,
        label: setup.displayName,
        dateTimeLocal: setup.datetimeLocal,
        value: value,
        isDeleted: false,
      ));
    }

    void addDeleted(String placeholder, List<DeletedRecordValue> rows) {
      for (final row in rows) {
        final value = AdjustmentValue.decode(row.rawValue, type);
        if (value == null || value is UnresolvedValue) continue;
        recorded.add(RecordedValue(
          recordId: row.recordId,
          label: row.name ?? placeholder,
          dateTimeLocal: row.dateTimeLocal,
          value: value,
          isDeleted: true,
        ));
      }
    }
    addDeleted(Setup.namePlaceholder, await database.setupsDao.getDeletedValuesFor(adjustmentId));

    return recorded..sort((a, b) => b.dateTimeLocal.compareTo(a.dateTimeLocal));
  }

  Adjustment? _findAdjustment(String id) {
    for (final component in _components.values) {
      final adjustment = component.adjustments.firstWhereOrNull((a) => a.id == id);
      if (adjustment != null) return adjustment;
    }
    for (final person in _persons.values) {
      final adjustment = person.adjustments.firstWhereOrNull((a) => a.id == id);
      if (adjustment != null) return adjustment;
    }
    return null;
  }

  @visibleForTesting
  set setupHistory(SetupHistory history) => _setupHistory = history;

  bool get hasSetupsWithPosition =>
      _setups.values.any((setup) => !setup.isDeleted && _isMappable(setup.position));

  bool get hasFeedbacksWithPosition =>
      _feedbacks.values.any((feedback) => !feedback.isDeleted && _isMappable(feedback.position));

  static bool _isMappable(ContextPosition? position) =>
      (position?.latitude?.isFinite ?? false) && (position?.longitude?.isFinite ?? false);

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
      ..._taskRules.values.map((tr) => tr.lastModified),
      ..._taskEntries.values.map((te) => te.lastModified),
      ..._feedbacks.values.map((f) => f.lastModified),
      ..._testSessions.values.map((ts) => ts.lastModified),
    ].whereType<DateTime>();

    if (allDates.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return allDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ---------------------------------------------------------------------------
  // DB STREAMS & CHANGE PROPAGATION
  // ---------------------------------------------------------------------------

  void _initStreams() {
    _listenInitial(database.bikesDao.watchAllBikes(), (list) {
      _bikes = {for (var b in list) b.id: b.toModel()};
      _markInitialStreamFired('bikes');
      _dataChanged();
    });

    _listenInitial(database.componentsDao.watchAllComponentsWithData(), (list) {
      _componentHierarchyCache = null;
      _components = {for (var c in list) c.component.id: c.component.toModel(
        adjustments: c.adjustments.map((a) => a.toModel()).toList(),
        installations: c.installations.map((i) => i.toModel()).toList(),
      )};
      _markInitialStreamFired('components');
      _dataChanged();
    });

    _listenInitial(database.personsDao.watchAllPersonsWithData(), (list) {
      _persons = {for (var p in list) p.person.id: p.person.toModel(
        adjustments: p.adjustments.map((a) => a.toModel()).toList(),
      )};
      _markInitialStreamFired('persons');
      _dataChanged();
    });

    _listenInitial(database.taskDao.watchAllRules(), (list) {
      _taskRules = {for (var r in list) r.id: r.toModel()};
      _markInitialStreamFired('taskRules');
      _dataChanged();
    });

    _listenInitial(database.taskDao.watchAllEntries(), (list) {
      _taskEntries = {for (var e in list) e.id: e.toModel()};
      _markInitialStreamFired('taskEntries');
      _dataChanged();
    });

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

    _subscriptions.add(database.stravaDao.watchActivityBounds().listen((bounds) {
      _activityBounds = bounds;
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

    _listenInitial(database.setupsDao.watchAllSetupsWithValues(), (list) {
      _setups = {for (var s in list) s.setup.id: s.setup.toModel(values: s.values)};
      _markInitialStreamFired('setups');
      _dataChanged();
    });

    _subscriptions.add(database.feedbackDao.watchAllFeedbacksWithChildren().listen((list) {
      _feedbacks = {for (var f in list) f.feedback.id: f.toModel()};
      _dataChanged();
    }));

    // Held raw: the locks and proposals decode by adjustment type, and the
    // components that define the types may arrive after the sessions.
    _subscriptions.add(database.feedbackDao.watchAllTestSessions().listen((list) {
      _testSessionRows = list;
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
    _subscriptions.add(database.taskDao.watchDeletedRules().listen((list) {
      _deletedTaskRules = list.map((tr) => tr.toModel()).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.taskDao.watchDeletedEntries().listen((list) {
      _deletedTaskEntries = list.map((te) => te.toModel()).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.feedbackDao.watchDeletedFeedbacksWithChildren().listen((list) {
      _deletedFeedbacks = list.map((f) => f.toModel()).toList();
      _notifyIfActive();
    }));
    _subscriptions.add(database.feedbackDao.watchDeletedTestSessions().listen((list) {
      _deletedTestSessions = list.map((ts) => ts.toModel()).toList();
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
    // Drop the lazily built setup and feedback lookup caches
    _setupsByBikeSorted = null;
    _feedbacksBySetup = null;
    _setupRanks = null;
    _openIssuesBySetup.clear();
    _customIssues = null;
    _feedbackActivityIds = null;

    final result = SetupResolutionService.resolveSetups(
      setups: _setups,
      bikes: _bikes,
      persons: _persons,
      components: _components,
    );
    _setups = result.setups;
    _currentAdjustmentValues = result.globalState;
    _setupHistory = result.history;

    final adjustmentTypes = adjustmentTypesOf(components: _components.values, persons: _persons.values);
    _testSessions = {for (final row in _testSessionRows) row.id: row.toModel(adjustmentTypes: adjustmentTypes)};

    _setupTags = SetupResolutionService.extractAllTags(_setups.values);
    _taskRuleTags = _taskRules.values.map((tr) => tr.tags).expand((tags) => tags).toSet();
  }

  // ---------------------------------------------------------------------------
  // FILTERING STATE
  // ---------------------------------------------------------------------------

  late final FilterController filters;
  void Function()? onFiltersChanged;
  Set<String> _setupTags = {};
  Set<String> _taskRuleTags = {};

  Set<String> get setupTags => _setupTags;
  Set<String> get taskRuleTags => _taskRuleTags;

  Map<String, Component> get archivedComponents => {
        for (final entry in _components.entries)
          if (componentHierarchy.isEffectivelyArchived(entry.key)) entry.key: entry.value
      };

  late FilteredView _view;

  /// The raw data narrowed by [filters].
  FilteredView get view => _view;

  void _filter() {
    filters.normalize(bikeIds: bikes.keys, setupTags: setupTags, taskRuleTags: taskRuleTags);
    _view = _buildView();
    _strava.reloadIfQueryChanged();  // re-pages Strava if the bike scope changed
  }

  FilteredView _buildView() => FilteredView(
        bikes: _bikes,
        components: _components,
        setups: _setups,
        persons: _persons,
        taskRules: _taskRules,
        taskEntries: _taskEntries,
        feedbacks: _feedbacks,
        testSessions: _testSessions,
        hierarchy: componentHierarchy,
        bikeId: filters.bikeId,
        dateRange: filters.dateRange,
        setupFilter: filters.setup,
        taskRuleFilter: filters.taskRule,
      );

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
    return ComponentStats.zero;
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

    // One transaction: written individually, every update re-emits the task
    // entry stream, which re-resolves all setups on the UI isolate. Only the
    // snapshot is written: the rows were read before the stats queries, so a
    // full-row write would revert edits and trashing made in the meantime.
    await database.transaction(() async {
      for (final entry in changed) {
        await database.taskDao.updateEntrySnapshot(entry.id, entry.toCompanion().snapshot.value);
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
      ComponentTaskAssociation(:final id) => componentStatsOf(id),
      BikeTaskAssociation(:final id) => _bikeStats[id] ?? _bikes[id]?.initialStats ?? ComponentStats.zero,
      GeneralTaskAssociation() => ComponentStats.zero,
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

  /// See [TaskStatusService.dueNowDelay].
  TaskThreshold? getTaskRuleDueNowDelay(TaskRule rule) {
    final inputs = _taskRuleInputs(rule);

    return TaskStatusService.dueNowDelay(
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
      componentBikeId: switch (rule.association) {
        ComponentTaskAssociation(:final id) => componentHierarchy.currentBike(id),
        _ => null,
      },
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

  List<TaskRuleWithStatus> get openTaskRules => _openTaskRulesWithStatus(view.taskRules.values);

  List<TaskRuleWithStatus> get actionableTaskRules {
    final actionable = view.taskRules.values
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
    final upcoming = view.taskRules.values
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

  bool get hasScopeActionableTaskRules => view.taskRulesInScope.values
      .map(getTaskRuleStatus)
      .any((status) => status.isDue);

  bool get hasTaskRulesInCurrentScope => view.taskRulesInScope.isNotEmpty;

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

  TaskStatusType get openTaskRulesStatusType => getAggregatedTaskStatus(view.taskRules.values);

  /// Worst status among a component's open task rules, or null if it has none.
  TaskStatusType? componentTaskIndicatorStatus(String componentId) {
    final openRules = openTaskRulesForComponent(componentId);
    if (openRules.isEmpty) return null;
    return getAggregatedTaskStatus(openRules.map((t) => t.rule));
  }

  List<TaskRuleWithStatus> get completedTaskRules {
    final statusRules = view.taskRules.values.map((rule) => TaskRuleWithStatus(rule: rule, status: getTaskRuleStatus(rule)));
    final completed = statusRules.where((tr) => tr.status.type == TaskStatusType.completed).toList();
    completed.sort((a, b) {
      final modifiedComparison = b.rule.lastModified.compareTo(a.rule.lastModified);
      return modifiedComparison != 0 ? modifiedComparison : a.rule.id.compareTo(b.rule.id);
    });
    return completed;
  }

  // ---------------------------------------------------------------------------
  // SETUP LOOKUPS
  // ---------------------------------------------------------------------------

  // Lazily built lookup cache for setup resolution.
  Map<String, List<Setup>>? _setupsByBikeSorted;

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

  // ---------------------------------------------------------------------------
  // FEEDBACK: LOOKUPS
  // ---------------------------------------------------------------------------

  /// Lazily built index behind [feedbacksForSetup], dropped on every data change.
  Map<String, List<RideFeedback>>? _feedbacksBySetup;

  Map<String, List<RideFeedback>> get _feedbacksBySetupIndex {
    final cached = _feedbacksBySetup;
    if (cached != null) return cached;
    final map = <String, List<RideFeedback>>{};
    for (final feedback in _feedbacks.values) {
      final setupId = resolvedSetupIdFor(feedback);
      if (setupId != null) (map[setupId] ??= []).add(feedback);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.dateTimeUTC.compareTo(a.dateTimeUTC));
    }
    return _feedbacksBySetup = map;
  }

  String? resolvedSetupIdFor(RideFeedback feedback) => resolveSetupId(bikeId: feedback.bike, atUtc: feedback.dateTimeUTC);
  Setup? resolvedSetupFor(RideFeedback feedback) => _setups[resolvedSetupIdFor(feedback)];

  bool hasSetupDrift(RideFeedback feedback) {
    final resolved = resolvedSetupIdFor(feedback);
    return resolved != null && resolved != feedback.setupId;
  }

  List<RideFeedback> feedbacksForSetup(String setupId) => _feedbacksBySetupIndex[setupId] ?? const []; // newest first

  /// Lazily built caches behind [rankFor] and [openIssuesFor], dropped on every
  /// data change. They ignore the filters: a rank needs every setup of the bike.
  Map<String, SetupRank>? _setupRanks;
  final Map<String, OpenIssues?> _openIssuesBySetup = {};

  SetupRank? rankFor(String setupId) =>
      (_setupRanks ??= FeedbackRankingService.rank(setups: _setups, feedbacksBySetup: _feedbacksBySetupIndex))[setupId];

  OpenIssues? openIssuesFor(String setupId) => _openIssuesBySetup.putIfAbsent(
        setupId,
        () => FeedbackOpenIssuesService.openIssues(feedbacksForSetup(setupId)),
      );

  Set<int>? _feedbackActivityIds;

  /// Whether [activity] is a ride on the bike's current setup that no feedback
  /// is linked to yet. Rides before the current setup belong to an older one.
  bool activityNeedsFeedback(StravaActivity activity) {
    final bike = _bikes.values.firstWhereOrNull((b) => b.stravaGear != null && b.stravaGear == activity.gearId);
    if (bike == null) return false;
    final current = _setups[resolveSetupId(bikeId: bike.id, atUtc: DateTime.now().toUtc())];
    if (current == null || activity.startDate.isBefore(current.datetime)) return false;
    final linked = _feedbackActivityIds ??= {
      for (final feedback in _feedbacks.values)
        if (feedback.stravaActivityId != null) feedback.stravaActivityId!,
    };
    return !linked.contains(activity.id);
  }

  CustomIssueIndex? _customIssues;

  /// The custom issues the live feedbacks use, regardless of the filters.
  CustomIssueIndex get customIssues => _customIssues ??= CustomIssueService.index(_feedbacks.values);

  List<Setup> setupsInSession(String sessionId) =>
      _setups.values.where((setup) => setup.testSessionId == sessionId).toList();

  TestSession? runningSessionFor(String bikeId) {
    TestSession? running;
    for (final session in _testSessions.values) {
      if (session.bike != bikeId || !session.isRunning) continue;
      if (running == null || session.startedAtUTC.isAfter(running.startedAtUTC)) running = session;
    }
    return running;
  }

  // ---------------------------------------------------------------------------
  // STRAVA: PAGING, QUERIES & SYNC
  // ---------------------------------------------------------------------------

  late final StravaPagingController _strava;
  int _stravaOperationVersion = 0;

  bool get hasMoreStrava => _strava.hasMore;
  bool get isLoadingMoreStrava => _strava.isLoadingMore;
  bool get stravaSortAscending => _strava.sortAscending;

  Future<List<StravaActivity>> get latestStravaActivities => _strava.latest;
  Future<List<StravaActivity>> getFilteredStravaActivitiesWithPosition() => _strava.filteredActivitiesWithPosition();

  /// Unfiltered: whether any synced activity carries coordinates the map can pin.
  Future<bool> hasStravaActivitiesWithPosition() => _strava.hasActivitiesWithPosition();

  Future<List<StravaActivity>> searchStravaActivities(String query) => _strava.search(query);
  Future<StravaActivity?> getStravaActivity(int id) => _strava.getActivity(id);

  Future<void> initialStravaLoad() => _strava.initialLoad();
  Future<void> reloadStravaWindow() => _strava.reloadWindow();
  Future<void> setStravaSortOrder(bool ascending) => _strava.setSortOrder(ascending);
  Future<void> loadMoreStravaActivities() => _strava.loadMore();

  /// Debug helper to override the pagination chunk size in tests.
  void debugSetStravaLimit(int limit) => _strava.limit = limit;

  StravaActivityQuery? _currentStravaQuery() => filters.stravaQuery(bikes[filters.bikeId]);
  bool get selectedBikeHasNoStravaGear => _currentStravaQuery() == null;

  Future<void> setStravaActivities(Iterable<StravaActivity> activities, {List<int>? toDelete}) async {
    final versionAtStart = _stravaOperationVersion;

    // Perform bulk operations in a single transaction for performance and to reduce race conditions
    await database.transaction(() async {
      if (toDelete != null && toDelete.isNotEmpty) {
        await database.stravaDao.deleteActivities(toDelete);
      }
      // Check if we were cleared while waiting for the transaction
      if (versionAtStart != _stravaOperationVersion) return;
      await database.stravaDao.upsertActivities(activities.map((a) => a.toCompanion()));
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

    // One transaction so the Strava watch streams re-query once, not per table.
    await database.transaction(() async {
      await database.delete(database.stravaActivities).go();
      await database.delete(database.stravaAthletes).go();
      await database.delete(database.stravaGears).go();
    });
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
  List<TaskRule> _deletedTaskRules = [];
  List<TaskEntry> _deletedTaskEntries = [];
  List<RideFeedback> _deletedFeedbacks = [];
  List<TestSession> _deletedTestSessions = [];

  List<Person> get deletedPersons => _deletedPersons;
  List<Bike> get deletedBikes => _deletedBikes;
  List<Component> get deletedComponents => _deletedComponents;
  List<Setup> get deletedSetups => _deletedSetups;
  List<TaskRule> get deletedTaskRules => _deletedTaskRules;
  List<TaskEntry> get deletedTaskEntries => _deletedTaskEntries;
  List<RideFeedback> get deletedFeedbacks => _deletedFeedbacks;
  List<TestSession> get deletedTestSessions => _deletedTestSessions;

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

  Future<void> removeFeedbacks(Iterable<RideFeedback> feedbacks) async {
    if (feedbacks.isEmpty) return;
    await database.transaction(() async {
      for (final feedback in feedbacks) {
        await database.feedbackDao.deleteFeedback(feedback.id);
      }
    });
  }

  Future<void> restoreFeedbacks(Iterable<RideFeedback> feedbacks) async {
    if (feedbacks.isEmpty) return;
    await database.transaction(() async {
      for (final feedback in feedbacks) {
        await database.feedbackDao.restoreFeedback(feedback.id);
      }
    });
  }

  Future<void> removeTestSessions(Iterable<TestSession> sessions) async {
    if (sessions.isEmpty) return;
    await database.transaction(() async {
      for (final session in sessions) {
        await database.feedbackDao.deleteTestSession(session.id);
      }
    });
  }

  Future<void> restoreTestSessions(Iterable<TestSession> sessions) async {
    if (sessions.isEmpty) return;
    await database.transaction(() async {
      for (final session in sessions) {
        await database.feedbackDao.restoreTestSession(session.id);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // WRITE OPERATIONS
  // ---------------------------------------------------------------------------

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

  Future<void> addFeedbacks(Iterable<RideFeedback> feedbacks) async {
    if (feedbacks.isEmpty) return;
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final feedback in feedbacks) {
        final updated = feedback.copyWith(lastModified: now);
        await database.feedbackDao.insertFeedbackWithChildren(
          feedback: updated.toCompanion(),
          observations: updated.observationCompanions(),
          comparisons: updated.comparisonCompanions(),
        );
      }
    });
  }

  Future<void> editFeedback(RideFeedback feedback) async {
    final updated = feedback.copyWith(lastModified: DateTime.now().toUtc());
    await database.feedbackDao.upsertFeedbackWithChildren(
      feedback: updated.toCompanion(),
      observations: updated.observationCompanions(),
      comparisons: updated.comparisonCompanions(),
    );
  }

  /// Renames the custom issue [slug] to [label] in every feedback, trashed ones
  /// included, and in the goals of every session. Merges into the issue the new
  /// label names when that exists. Returns false when [label] is blank.
  Future<bool> renameCustomIssue(String slug, String label) async {
    final to = CustomIssue.fromLabel(label);
    if (to == null) return false;
    await _rewriteCustomIssue(
      feedback: (feedback) => CustomIssueService.rename(feedback, slug, to),
      session: (session) => CustomIssueService.renameGoal(session, slug, to),
    );
    return true;
  }

  /// Strips the custom issue [slug] from every feedback, trashed ones included,
  /// and from the goals of every session.
  Future<void> removeCustomIssue(String slug) => _rewriteCustomIssue(
    feedback: (feedback) => CustomIssueService.remove(feedback, slug),
    session: (session) => CustomIssueService.removeGoal(session, slug),
  );

  Future<void> _rewriteCustomIssue({
    required RideFeedback? Function(RideFeedback feedback) feedback,
    required TestSession? Function(TestSession session) session,
  }) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final original in [..._feedbacks.values, ..._deletedFeedbacks]) {
        if (feedback(original) case final changed?) {
          final updated = changed.copyWith(lastModified: now);
          await database.feedbackDao.upsertFeedbackWithChildren(
            feedback: updated.toCompanion(),
            observations: updated.observationCompanions(),
            comparisons: updated.comparisonCompanions(),
          );
        }
      }
      for (final original in [..._testSessions.values, ..._deletedTestSessions]) {
        if (session(original) case final changed?) {
          await database.feedbackDao.upsertTestSession(changed.copyWith(lastModified: now).toCompanion());
        }
      }
    });
  }

  Future<void> addTestSessions(Iterable<TestSession> sessions) async {
    if (sessions.isEmpty) return;
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final session in sessions) {
        await database.feedbackDao.insertTestSession(session.copyWith(lastModified: now).toCompanion());
      }
    });
  }

  Future<void> editTestSession(TestSession session) async {
    await database.feedbackDao.upsertTestSession(
      session.copyWith(lastModified: DateTime.now().toUtc()).toCompanion(),
    );
  }

  Future<void> endTestSession(TestSession session, {DateTime? at}) {
    final when = at ?? DateTime.now();
    return editTestSession(session.copyWith(endedAtUTC: when.toUtc(), endedAtLocal: when));
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
            inst.copyWith(id: const Uuid().v4()).toCompanion(componentId: updateComponent.id)
          ).toList(),
        );
      }
    });
  }

  Future<void> editPerson(Person person, {List<ValueMigration> migrations = const []}) async {
    final updated = person.copyWith(lastModified: DateTime.now().toUtc());
    await database.transaction(() async {
      await database.personsDao.updatePersonWithData(
        person: updated.toCompanion(),
        adjustmentsList: updated.adjustments.asMap().entries.map((entry) =>
          entry.value.toCompanion(personId: updated.id, orderIndex: entry.key)
        ).toList(),
      );
      for (final migration in migrations) {
        final adjustment = updated.adjustments.firstWhereOrNull((a) => a.id == migration.adjustmentId);
        if (adjustment == null) continue;
        await database.setupsDao.migrateAdjustmentValues(adjustment.id, adjustment.type, migration);
      }
    });
  }

  Future<void> editBikes(Iterable<Bike> bikes) async {
    final bikeList = bikes.toList();
    if (bikeList.isEmpty) return;
    // Initial stats also move every component inheriting them (installed since beginning).
    final statsInputsChanged = bikeList.any((bike) =>
        _bikes[bike.id]?.stravaGear != bike.stravaGear ||
        _bikes[bike.id]?.initialStats != bike.initialStats);
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final bike in bikeList) {
        await database.bikesDao.updateBike(bike.copyWith(lastModified: now).toCompanion());
      }
    });

    if (statsInputsChanged) await refreshTaskEntrySnapshots();
  }

  Future<void> editComponents(Iterable<Component> components, {List<ValueMigration> migrations = const []}) async {
    final componentList = components.toList();
    if (componentList.isEmpty) return;
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
    candidateHierarchy.validate();
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
      for (final migration in migrations) {
        final adjustment = updates
            .expand((component) => component.adjustments)
            .firstWhereOrNull((a) => a.id == migration.adjustmentId);
        if (adjustment == null) continue;
        await database.setupsDao.migrateAdjustmentValues(adjustment.id, adjustment.type, migration);
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
        // Preserve the stable installation ids across edits.
        inst.toCompanion(componentId: updated.id)
      ).toList(),
    );
  }

  Future<void> archiveComponent(Component component, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    final event = Archival(
      dateTimeUTC: when.toUtc(),
      dateTimeLocal: when,
    );
    await editComponents([
      component.copyWith(installations: [...component.installations, event]),
    ]);
  }

  Future<void> unarchiveComponent(Component component) async {
    final updated = List<Installation>.from(component.installations);
    final idx = updated.lastIndexWhere((i) => i is Archival);
    if (idx == -1) return;
    updated.removeAt(idx);
    await editComponents([component.copyWith(installations: updated)]);
  }

  Future<void> addSetups(Iterable<Setup> setups) async {
    if (setups.isEmpty) return;
    checkSetupValueTypes(setups, components: _components.values, persons: _persons.values);
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

  Future<void> editSetups(Iterable<Setup> setups) async {
    final setupList = setups.toList();
    if (setupList.isEmpty) return;
    checkSetupValueTypes(setupList, components: _components.values, persons: _persons.values);
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final setup in setupList) {
        await database.setupsDao.updateSetupWithValues(
          setup: setup.copyWith(lastModified: now).toCompanion(),
          bikeValues: setup.bikeAdjustmentValues,
          personValues: setup.personAdjustmentValues,
        );
      }
    });
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
