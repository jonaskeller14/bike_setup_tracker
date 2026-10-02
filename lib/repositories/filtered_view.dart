import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../models/component/resolved_installation.dart';
import '../models/filters/local_date_range.dart';
import '../models/filters/setup_filter.dart';
import '../models/filters/task_rule_filter.dart';
import '../models/person.dart';
import '../models/rating/rating.dart';
import '../models/rating/rating_association.dart';
import '../models/rating/rating_entry.dart';
import '../models/setup.dart';
import '../models/task/task_association.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../services/component_hierarchy_resolver.dart';

/// A snapshot of the raw data narrowed by the filter criteria.
///
/// Every result is computed on first read, so results nobody asks for cost
/// nothing and a result always sees the ones it depends on. The raw maps must
/// not be mutated while a snapshot is alive: the repository replaces them and
/// builds a new snapshot instead.
class FilteredView {
  final Map<String, Bike> _bikes;
  final Map<String, Component> _components;
  final Map<String, Setup> _setups;
  final Map<String, RatingEntry> _ratingEntries;
  final Map<String, Person> _persons;
  final Map<String, Rating> _ratings;
  final Map<String, TaskRule> _taskRules;
  final Map<String, TaskEntry> _taskEntries;
  final ComponentHierarchyResolver _hierarchy;
  final String? _bikeId;
  final LocalDateRange? _dateRange;
  final SetupFilter _setupFilter;
  final TaskRuleFilter _taskRuleFilter;

  FilteredView({
    required this._bikes,
    required this._components,
    required this._setups,
    required this._ratingEntries,
    required this._persons,
    required this._ratings,
    required this._taskRules,
    required this._taskEntries,
    required this._hierarchy,
    required this._bikeId,
    required this._dateRange,
    required this._setupFilter,
    required this._taskRuleFilter,
  });

  /// The date range narrows the dated entries by their local calendar day.
  bool _inDateRange(DateTime local) => _dateRange?.contains(local) ?? true;

  late final Map<String, Bike> bikes = _bikeId == null
      ? _bikes
      : Map.fromEntries(_bikes.entries.where((entry) => entry.key == _bikeId));

  late final Map<String, Component> components = Map.fromEntries(
    _components.entries.where((entry) {
      final placement = _hierarchy.resolveCurrent(entry.key);
      if (placement.isArchived || placement.isDeleted) return false;
      return _bikeId == null || placement.bikeId == _bikeId;
    }),
  );

  late final Map<String, Setup> setups = Map.fromEntries(
    _setups.entries.where(
      (entry) =>
          (_bikeId == null || entry.value.bike == _bikeId) &&
          _inDateRange(entry.value.datetimeLocal) &&
          _setupFilter.matches(entry.value),
    ),
  );

  late final Map<String, RatingEntry> ratingEntries = Map.fromEntries(
    _ratingEntries.entries.where(
      (entry) => (_bikeId == null || entry.value.bike == _bikeId) && _inDateRange(entry.value.dateTimeLocal),
    ),
  );

  late final Map<String, Person> persons = _bikeId == null
      ? _persons
      : Map.fromEntries(_persons.entries.where((entry) => entry.value.id == _bikes[_bikeId]?.person));

  late final Map<String, Rating> ratings = Map.fromEntries(
    _ratings.entries.where((entry) {
      if (_bikeId == null) return true;
      return switch (entry.value.association) {
        GlobalRatingAssociation() => true,
        PersonRatingAssociation() => true,
        BikeRatingAssociation(:final bikeId) => bikeId == _bikeId,
        ComponentRatingAssociation(:final componentId) => components.containsKey(componentId),
        ComponentTypeRatingAssociation(:final componentTypeStr) => components.values.any(
          (c) => c.componentType.toString() == componentTypeStr,
        ),
      };
    }),
  );

  /// The task rules of the bike scope, before priority and tag narrowing.
  late final Map<String, TaskRule> taskRulesInScope = Map.fromEntries(
    _taskRules.entries.where(
      (entry) => switch (entry.value.association) {
        GeneralTaskAssociation() => true,
        BikeTaskAssociation(:final id) => _bikeId == null || id == _bikeId,
        ComponentTaskAssociation(:final id) => components.containsKey(id),
      },
    ),
  );

  late final Map<String, TaskRule> taskRules = Map.fromEntries(
    taskRulesInScope.entries.where((entry) => _taskRuleFilter.matches(entry.value)),
  );

  /// The [taskRules] that have no entry yet, whatever the date range hides.
  late final Map<String, TaskRule> openTaskRules = () {
    final rulesWithEntries = {for (final entry in _taskEntries.values) entry.taskRule};
    return Map.fromEntries(taskRules.entries.where((entry) => !rulesWithEntries.contains(entry.key)));
  }();

  late final Map<String, TaskEntry> taskEntries = Map.fromEntries(
    _taskEntries.entries.where(
      (entry) => taskRules.containsKey(entry.value.taskRule) && _inDateRange(entry.value.dateTimeLocal),
    ),
  );

  /// Every installation change in the date range that touches the bike scope,
  /// as its origin or its target.
  late final List<ResolvedInstallation> installations = () {
    final result = <ResolvedInstallation>[];
    for (final component in _components.values) {
      final sorted = List<Installation>.from(component.installations)
        ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

      for (int i = 0; i < sorted.length; i++) {
        final installation = sorted[i];
        if (installation.dateTimeUTC.millisecondsSinceEpoch == 0) continue;
        if (!_inDateRange(installation.dateTimeLocal)) continue;

        final previousInstallation = i > 0 ? sorted[i - 1] : null;
        final targetBike = _hierarchy.bikeAt(component.id, installation.dateTimeUTC);
        final originTime = installation.dateTimeUTC.subtract(const Duration(microseconds: 1));
        final originBike = _hierarchy.bikeAt(component.id, originTime);
        if (_bikeId == null || targetBike == _bikeId || originBike == _bikeId) {
          result.add(
            ResolvedInstallation(
              component: component,
              installation: installation,
              originParent: previousInstallation?.parent,
              originParentType: previousInstallation?.parentType,
              isInitial: i == 0,
            ),
          );
        }
      }
    }
    return result;
  }();
}
