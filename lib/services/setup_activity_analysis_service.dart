import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/adjustment_value_codec.dart';
import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/adjustment_activity_histogram.dart';
import '../utils/adjustment_activity_histogram_grouping.dart';

class SetupActivityAnalysisService extends ChangeNotifier {
  final AppDatabase _database;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Completer<void> _changeStreamReady = Completer<void>();
  final Completer<void> _activityGateReady = Completer<void>();

  Future<Map<String, int>>? _setupActivityCountsFuture;
  Map<String, int> _setupActivityCounts = const {};
  final Map<String, Future<AdjustmentActivityHistogram>> _histogramFutures = {};
  bool _hasAnyActivity = false;
  bool _disposed = false;
  int _generation = 0;

  SetupActivityAnalysisService(this._database) {
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
    final counts = Map<String, int>.unmodifiable(await _database.stravaDao.getSetupActivityCounts());
    if (!_disposed && generation == _generation) {
      _setupActivityCounts = counts;
      _notifyListeners();
    }
    return counts;
  }

  Future<AdjustmentActivityHistogram> _loadAdjustmentHistogram(String adjustmentId) async {
    final countsFuture = getSetupActivityCounts();
    final setupsFuture = _database.setupsDao.getAllSetupsWithValuesBypass();
    final counts = await countsFuture;
    final setups = await setupsFuture;

    AdjustmentDb? adjustmentDb;
    final values = <AdjustmentActivityValue>[];
    for (final setup in setups) {
      if (setup.setup.isDeleted) continue;
      for (final typedValue in setup.values) {
        if (typedValue.adjustment.id != adjustmentId) continue;
        adjustmentDb ??= typedValue.adjustment;
        values.add(
          AdjustmentActivityValue(
            setupId: setup.setup.id,
            value: decodeAdjustmentValue(typedValue.value.value, typedValue.adjustment.type),
            activityCount: counts[setup.setup.id] ?? 0,
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
