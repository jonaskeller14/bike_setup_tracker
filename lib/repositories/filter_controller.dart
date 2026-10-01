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
    onChanged();
  }

  set dateRange(LocalDateRange? value) {
    if (value == _dateRange) return;
    _dateRange = value;
    onChanged();
  }

  set setup(SetupFilter value) {
    if (value == _setup) return;
    _setup = value;
    onChanged();
  }

  set taskRule(TaskRuleFilter value) {
    if (value == _taskRule) return;
    _taskRule = value;
    onChanged();
  }

  set layers(LayerFilter value) {
    if (value == _layers) return;
    _layers = value;
    onChanged();
  }

  set activity(ActivityFilter value) {
    if (value == _activity) return;
    _activity = value;
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

  /// Drops criteria whose bike or tags no longer exist. Runs inside the
  /// repository's recompute, so it never fires [onChanged].
  void normalize({
    required Iterable<String> bikeIds,
    required Set<String> setupTags,
    required Set<String> taskRuleTags,
  }) {
    if (_bikeId != null && !bikeIds.contains(_bikeId)) _bikeId = null;
    if (!setupTags.containsAll(_setup.tags)) {
      _setup = _setup.copyWith(tags: _setup.tags.intersection(setupTags));
    }
    if (!taskRuleTags.containsAll(_taskRule.tags)) {
      _taskRule = _taskRule.copyWith(tags: _taskRule.tags.intersection(taskRuleTags));
    }
  }
}
