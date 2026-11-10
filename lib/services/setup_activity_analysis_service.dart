import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/adjustment/adjustment.dart';
import '../models/adjustment_activity_histogram.dart';
import '../utils/adjustment_activity_histogram_grouping.dart';
import 'component_hierarchy_resolver.dart';
import 'component_slot.dart';

class SetupActivityAnalysisService extends ChangeNotifier {
  final AppDatabase _database;
  final ComponentHierarchyResolver Function()? _hierarchy;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Completer<void> _changeStreamReady = Completer<void>();
  final Completer<void> _activityGateReady = Completer<void>();

  Future<Map<String, int>>? _setupActivityCountsFuture;
  Map<String, int> _setupActivityCounts = const {};
  bool _setupActivityCountsLoaded = false;
  bool _setupActivityCountsFailed = false;
  final Map<String, Future<AdjustmentActivityHistogram>> _histogramFutures = {};
  bool _hasAnyActivity = false;
  bool _disposed = false;
  int _generation = 0;

  SetupActivityAnalysisService(this._database, {this._hierarchy}) {
    var receivedInitialChange = false;
    _subscriptions.add(
      _database
          .customSelect(
            'SELECT 1 AS change_token',
            readsFrom: {
              _database.setups,
              _database.setupAdjustmentValues,
              _database.adjustments,
              _database.bikes,
              _database.components,
              _database.installations,
              _database.stravaActivities,
            },
          )
          .watch()
          .listen((_) {
            if (!receivedInitialChange) {
              receivedInitialChange = true;
              if (!_changeStreamReady.isCompleted) _changeStreamReady.complete();
              return;
            }
            _invalidateAnalysis();
          }),
    );
    _subscriptions.add(
      _database.stravaDao.watchHasAnyActivity().listen((hasAnyActivity) {
        final changed = _hasAnyActivity != hasAnyActivity;
        _hasAnyActivity = hasAnyActivity;
        if (!_activityGateReady.isCompleted) _activityGateReady.complete();
        if (changed) _notifyListeners();
      }),
    );
  }

  bool get hasAnyActivity => _hasAnyActivity;
  Map<String, int> get setupActivityCounts => _setupActivityCounts;
  bool get setupActivityCountsLoaded => _setupActivityCountsLoaded;
  bool get setupActivityCountsFailed => _setupActivityCountsFailed;

  Future<Map<String, int>> getSetupActivityCounts() async {
    await _ready;
    if (_disposed) return const {};
    return _setupActivityCountsFuture ??= _loadSetupActivityCounts(_generation);
  }

  Future<AdjustmentActivityHistogram> getAdjustmentHistogram(String adjustmentId) async {
    await _ready;
    if (_disposed || !_hasAnyActivity) return AdjustmentActivityHistogram.empty(adjustmentId);
    return _histogramFutures.putIfAbsent(
      adjustmentId,
      () => _loadAdjustmentHistogram(adjustmentId),
    );
  }

  Future<void> get _ready => Future.wait([
    _changeStreamReady.future,
    _activityGateReady.future,
  ]);

  Future<Map<String, int>> _loadSetupActivityCounts(int generation) async {
    final Map<String, int> counts;
    try {
      counts = Map<String, int>.unmodifiable(await _database.stravaDao.getSetupActivityCounts());
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _setupActivityCountsFailed = true;
        _notifyListeners();
      }
      rethrow;
    }
    if (!_disposed && generation == _generation) {
      _setupActivityCounts = counts;
      _setupActivityCountsLoaded = true;
      _notifyListeners();
    }
    return counts;
  }

  Future<AdjustmentActivityHistogram> _loadAdjustmentHistogram(String adjustmentId) async {
    final countsFuture = getSetupActivityCounts();
    final setupsFuture = _database.setupsDao.getAllSetupsWithValuesBypass();
    final counts = await countsFuture;
    final setups = await setupsFuture;
    final hierarchy = _hierarchy?.call();

    AdjustmentDb? adjustmentDb;
    final values = <AdjustmentActivityValue>[];
    for (final setup in setups) {
      if (setup.setup.isDeleted) continue;
      for (final typedValue in setup.values) {
        final adjustment = typedValue.adjustment;
        if (adjustment == null || adjustment.id != adjustmentId) continue;
        adjustmentDb ??= adjustment;
        final component = hierarchy?.components[adjustment.componentId];
        values.add(
          AdjustmentActivityValue(
            setupId: setup.setup.id,
            value: AdjustmentValue.decode(typedValue.value.value, adjustment.type),
            activityCount: counts[setup.setup.id] ?? 0,
            slot: hierarchy == null || component == null
                ? null
                : slotOnBikeAt(
                    hierarchy,
                    component,
                    bikeId: setup.setup.bikeId,
                    atUTC: setup.setup.datetimeLocal.toUtc(),
                  ),
          ),
        );
      }
    }

    final adjustment = adjustmentDb?.toModel();
    final histogram = adjustment == null
        ? AdjustmentActivityHistogram.empty(adjustmentId)
        : groupAdjustmentActivityHistogram(adjustment: adjustment, values: values);
    return histogram;
  }

  void _invalidateAnalysis() {
    if (_disposed) return;
    _generation++;
    _setupActivityCountsFuture = null;
    _setupActivityCounts = const {};
    _setupActivityCountsLoaded = false;
    _setupActivityCountsFailed = false;
    _histogramFutures.clear();
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    if (!_changeStreamReady.isCompleted) _changeStreamReady.complete();
    if (!_activityGateReady.isCompleted) _activityGateReady.complete();
    super.dispose();
  }
}
