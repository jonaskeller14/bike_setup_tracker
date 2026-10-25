import 'package:flutter/foundation.dart';

import '../models/bike.dart';
import '../models/filters/activity_filter.dart';
import '../models/filters/layer_filter.dart';
import '../models/filters/local_date_range.dart';
import '../models/filters/setup_filter.dart';
import '../models/filters/task_rule_filter.dart';
import '../models/strava/strava_activity_query.dart';

/// Owns the filter criteria: the selected bike, the date range and one
/// immutable filter object per domain.
///
/// The owning repository is told about changes through [onChanged] and derives
/// the filtered results from the criteria.
class FilterController {
  /// Fired once a criterion actually changed.
  final void Function() onChanged;

  FilterController({required this.onChanged});

  String? _bikeId;
  LocalDateRange? _dateRange;
  SetupFilter _setup = const SetupFilter();
  TaskRuleFilter _taskRule = TaskRuleFilter();
  LayerFilter _layers = const LayerFilter();
  ActivityFilter _activity = const ActivityFilter();

  int _batchDepth = 0;
  bool _changedInBatch = false;

  String? get bikeId => _bikeId;

  /// `null` shows the entries of every day.
  LocalDateRange? get dateRange => _dateRange;
  SetupFilter get setup => _setup;
  TaskRuleFilter get taskRule => _taskRule;
  LayerFilter get layers => _layers;
  ActivityFilter get activity => _activity;

  /// Selects [bikeId], or clears the selection when it is `null` or already selected.
  void toggleBike(String? bikeId) {
    final next = bikeId == _bikeId ? null : bikeId;
    if (next == _bikeId) return;
    _bikeId = next;
    _changed();
  }

  set dateRange(LocalDateRange? value) {
    if (value == _dateRange) return;
    _dateRange = value;
    _changed();
  }

  set setup(SetupFilter value) {
    if (value == _setup) return;
    _setup = value;
    _changed();
  }

  set taskRule(TaskRuleFilter value) {
    if (value == _taskRule) return;
    _taskRule = value;
    _changed();
  }

  set layers(LayerFilter value) {
    if (value == _layers) return;
    _layers = value;
    _changed();
  }

  set activity(ActivityFilter value) {
    if (value == _activity) return;
    _activity = value;
    _changed();
  }

  /// Runs [update] and fires [onChanged] once afterwards if any criterion
  /// changed, so several setters cost one refilter instead of one each.
  void batch(void Function() update) {
    _batchDepth++;
    try {
      update();
    } finally {
      if (--_batchDepth == 0 && _changedInBatch) {
        _changedInBatch = false;
        onChanged();
      }
    }
  }

  void _changed() {
    if (_batchDepth > 0) {
      _changedInBatch = true;
    } else {
      onChanged();
    }
  }

  Map<String, Object?> toJson() => {
    'bikeId': _bikeId,
    'setup': _setup.toJson(),
    'taskRule': _taskRule.toJson(),
    'layers': _layers.toJson(),
    'activity': _activity.toJson(),
  };

  /// Applies criteria saved by [toJson] and fires [onChanged] once. Malformed
  /// [json] leaves every criterion as it is. A bike or tag that no longer
  /// exists is dropped by the next [normalize].
  void restore(Map<String, Object?> json) {
    try {
      Map<String, Object?> section(String key) => json[key] as Map<String, Object?>? ?? const {};
      final bikeId = json['bikeId'] as String?;
      final setup = SetupFilter.fromJson(section('setup'));
      final taskRule = TaskRuleFilter.fromJson(section('taskRule'));
      final layers = LayerFilter.fromJson(section('layers'));
      final activity = ActivityFilter.fromJson(section('activity'));
      _bikeId = bikeId;
      _setup = setup;
      _taskRule = taskRule;
      _layers = layers;
      _activity = activity;
    } catch (e) {
      debugPrint("Ignoring malformed saved filters: $e");
      return;
    }
    onChanged();
  }

  /// The Strava activities the criteria select, given the [selectedBike] that
  /// [bikeId] resolves to. `null` when that bike has no linked Strava gear: it
  /// owns no activities, so there is nothing to query.
  StravaActivityQuery? stravaQuery(Bike? selectedBike) {
    final query = StravaActivityQuery(activity: _activity, dateRange: _dateRange);
    if (selectedBike == null) return query;
    final gearId = selectedBike.stravaGear;
    return gearId == null ? null : query.copyWith(gearId: gearId);
  }

  /// Drops criteria whose bike, tags or test sessions no longer exist. Runs inside the
  /// repository's recompute, so it never fires [onChanged].
  void normalize({
    required Iterable<String> bikeIds,
    required Set<String> setupTags,
    required Set<String> testSessionNames,
    required Set<String> taskRuleTags,
  }) {
    if (_bikeId != null && !bikeIds.contains(_bikeId)) _bikeId = null;
    if (!setupTags.containsAll(_setup.tags)) {
      _setup = _setup.copyWith(tags: _setup.tags.intersection(setupTags));
    }
    if (!testSessionNames.containsAll(_setup.testSessionNames)) {
      _setup = _setup.copyWith(testSessionNames: _setup.testSessionNames.intersection(testSessionNames));
    }
    if (!taskRuleTags.containsAll(_taskRule.tags)) {
      _taskRule = _taskRule.copyWith(tags: _taskRule.tags.intersection(taskRuleTags));
    }
  }
}
