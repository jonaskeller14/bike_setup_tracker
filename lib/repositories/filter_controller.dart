import '../models/filters/setup_filter.dart';
import '../models/filters/task_rule_filter.dart';

/// Owns the filter criteria: the selected bike plus one immutable filter object
/// per domain.
///
/// The owning repository is told about changes through [onChanged] and derives
/// the filtered results from the criteria.
class FilterController {
  /// Fired once a criterion actually changed.
  final void Function() onChanged;

  FilterController({required this.onChanged});

  String? _bikeId;
  SetupFilter _setup = const SetupFilter();
  TaskRuleFilter _taskRule = TaskRuleFilter();

  String? get bikeId => _bikeId;
  SetupFilter get setup => _setup;
  TaskRuleFilter get taskRule => _taskRule;

  /// Selects [bikeId], or clears the selection when it is `null` or already selected.
  void toggleBike(String? bikeId) {
    final next = bikeId == _bikeId ? null : bikeId;
    if (next == _bikeId) return;
    _bikeId = next;
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
