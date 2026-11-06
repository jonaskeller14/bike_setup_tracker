import '../l10n/l10n.dart';
import '../l10n/task_threshold_text.dart';
import '../models/component/component.dart';
import '../models/task/task_association.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_template.dart';
import '../models/task/task_threshold/task_threshold.dart';
import 'task_presets.dart';

/// Whether one of [rules] was created from the template with [key].
///
/// Matched by [TaskRule.presetKey] alone, so a renamed rule still consumes its
/// template. Callers pass the rules of a single component.
bool isTaskPresetConsumed(String key, Iterable<TaskRule> rules) => rules.any((rule) => !rule.isDeleted && rule.presetKey == key);

/// The templates still on offer for [component], resolved against the Strava
/// entitlement. [overrides] (from the component catalog) replace a generic
/// template's interval and source by key, or add a brand-only template.
List<TaskSuggestion> taskSuggestionsFor(
  Component component,
  AppLocalizations l10n, {
  required Iterable<TaskRule> existingRules,
  required bool hasStravaEntitlement,
  Map<String, TaskTemplateOverride> overrides = const {},
}) {
  final componentRules = existingRules.where((rule) => rule.association.componentId == component.id).toList();
  final generic = taskPresetsFor(l10n)[component.componentType] ?? const <TaskTemplate>[];
  final genericKeys = generic.map((template) => template.key).toSet();
  final candidates = [
    for (final template in generic) (template: template, override: overrides[template.key]),
    for (final MapEntry(:key, value: override) in overrides.entries)
      if (!genericKeys.contains(key) && override.name != null)
        (
          template: TaskTemplate(key: key, name: override.name!, interval: override.interval),
          override: override,
        ),
  ];

  return [
    for (final (:template, :override) in candidates)
      if (!isTaskPresetConsumed(template.key, componentRules)) ?_resolve(template, override, hasStravaEntitlement: hasStravaEntitlement),
  ];
}

TaskSuggestion? _resolve(
  TaskTemplate template,
  TaskTemplateOverride? catalogOverride, {
  required bool hasStravaEntitlement,
}) {
  // A ride-based manufacturer interval without a published time-based
  // fallback says nothing without Strava, so the generic template applies.
  final override = !hasStravaEntitlement &&
          catalogOverride != null &&
          catalogOverride.interval.requiresActivityData &&
          catalogOverride.fallbackInterval == null
      ? null
      : catalogOverride;
  final TaskThreshold interval = override?.interval ?? template.interval;
  final fallback = override?.fallbackInterval ?? template.fallbackInterval;
  final useFallback = interval.requiresActivityData && !hasStravaEntitlement;
  if (useFallback && fallback == null) return null;

  return TaskSuggestion(
    key: template.key,
    name: override?.name ?? template.name,
    notes: override?.notes ?? template.notes,
    priority: override?.priority ?? template.priority,
    repeat: template.repeat,
    preselected: override?.preselected ?? template.preselected,
    interval: useFallback ? fallback! : interval,
    stravaInterval: useFallback ? interval : null,
    source: override?.source,
  );
}

extension TaskSuggestionRule on TaskSuggestion {
  /// The rule to create, its notes in the language of [l10n] and stored as written.
  TaskRule toTaskRule(String componentId, AppLocalizations l10n, {String distanceUnit = 'km', String altitudeUnit = 'm'}) {
    final line = _recommendationLine(l10n, distanceUnit: distanceUnit, altitudeUnit: altitudeUnit);
    return TaskRule(
      name: name,
      notes: line == null ? notes : (notes == null ? line : '$notes\n\n$line'),
      priority: priority,
      tags: const <String>{},
      association: ComponentTaskAssociation(componentId),
      interval: interval,
      repeat: repeat,
      presetKey: key,
    );
  }

  /// `null` for a generic interval: the rule's own trigger already says it.
  String? _recommendationLine(AppLocalizations l10n, {required String distanceUnit, required String altitudeUnit}) {
    final strava = stravaInterval;
    if (strava == null && source == null) return null;
    final effective = taskIntervalLabel(interval, l10n, distanceUnit: distanceUnit, altitudeUnit: altitudeUnit);
    final origin = strava != null
        ? l10n.taskRecommendedTimeBased(taskIntervalLabel(strava, l10n, distanceUnit: distanceUnit, altitudeUnit: altitudeUnit))
        : '';
    final sourceSuffix = source == null ? '' : ' — $source';
    return '${l10n.taskRecommendedInterval(effective)}$origin$sourceSuffix';
  }
}
