/// Named starting states for the demo flows, each derived from the merged
/// master sample, so only the master needs curating.
///
/// A flow picks one with a `# scenario: <id>` line. The run scripts write that
/// id to [DemoScenario.markerFile] in the app's documents folder before the
/// flow starts; without the marker the app seeds [DemoScenario.full].
library;

typedef _Json = Map<String, dynamic>;

const String _hightowerId = '93f93d45-3a56-43ae-8936-5cfcbd768c9b';

/// The due rules other than "Investigate BB creaking noise", which is one-off,
/// so ticking it off moves it to the completed section.
const Set<String> _otherDueTaskRuleIds = {
  'ca9ac6d2-19ed-427b-b381-7c24280dc0df', // Full suspension service
  '21e8fe3d-8ed4-4a42-b3b1-1dcd63fdfe36', // Pre-Worldcup DH bike check
  '1aff5ddb-0cd0-475f-b496-e6c7641dc08e', // Order: 2x brake pads, chain, sealant
  '2598ca74-03ab-4368-a19b-26c08998271b', // Dropper post getting sticky - service
  '6b0f4d7e-2c1a-4e59-8f3d-9a7c5e1b2d40', // Bolt torque check
};

enum DemoScenario {
  /// The whole master: store screenshots and most demos.
  full('full'),

  /// No bikes, and nothing recorded on them: the garage from zero.
  empty('empty'),

  /// The Santa Cruz Hightower and its rides, without components or setups.
  oneBikeNoComponents('one_bike_no_components'),

  /// Bikes and components, but no setups yet.
  noSetups('no_setups'),

  /// The full master without the suspension pressures that would squash the
  /// click-based series in the charts.
  analysis('analysis'),

  /// "Investigate BB creaking noise" as the only due task.
  tasksOneDue('tasks_one_due'),

  /// The full master with setup and task tags shown.
  tags('tags');

  const DemoScenario(this.id);

  /// The name used in flows and in the marker file.
  final String id;

  static const markerFile = 'demo_scenario';

  static DemoScenario fromId(String id) =>
      values.firstWhere((s) => s.id == id, orElse: () => throw ArgumentError.value(id, 'id', 'Unknown demo scenario'));

  /// Preferences written over `ScreenshotSeed.settings`.
  Map<String, Object> get settings => switch (this) {
    tags => const {'enableSetupTags': true, 'enableTaskTags': true},
    _ => const {},
  };

  /// Returns a copy of the merged seed [json] reduced to this scenario.
  Map<String, dynamic> apply(Map<String, dynamic> json) => switch (this) {
    full || tags => json,
    empty => _dropBikes(json, _ids(json, 'bikes')),
    oneBikeNoComponents => _dropSetups(
      _dropComponents(
        _dropBikes(json, _ids(json, 'bikes').difference({_hightowerId})),
        _ids(json, 'components'),
      ),
      (_) => true,
    ),
    noSetups => _dropSetups(json, (_) => true),
    analysis => _dropAdjustments(
      json,
      (component, adjustment) =>
          const {'ComponentType.fork', 'ComponentType.shock'}.contains(component['componentType']) &&
          adjustment['name'] == 'Pressure',
    ),
    tasksOneDue => _dropTaskRules(json, _otherDueTaskRuleIds),
  };
}

List<_Json> _list(_Json json, String key) => (json[key] as List<dynamic>).cast<_Json>();

Set<String> _ids(_Json json, String key) => {for (final item in _list(json, key)) item['id'] as String};

_Json _where(_Json json, String key, bool Function(_Json item) keep) => {
  ...json,
  key: _list(json, key).where(keep).toList(),
};

/// Drops [bikeIds] with everything recorded on them, including their Strava
/// rides and every component that was ever installed on them.
_Json _dropBikes(_Json json, Set<String> bikeIds) {
  final gearIds = {
    for (final bike in _list(json, 'bikes'))
      if (bikeIds.contains(bike['id'])) bike['stravaGear'],
  };
  final componentIds = {
    for (final component in _list(json, 'components'))
      if (_list(component, 'installations').any((i) => bikeIds.contains(i['parent']))) component['id'] as String,
  };
  var result = _where(json, 'bikes', (b) => !bikeIds.contains(b['id']));
  result = _where(result, 'stravaActivities', (a) => !gearIds.contains(a['gearId']));
  result = _where(result, 'ratings', (r) => !(r['filterType'] == 'FilterType.bike' && bikeIds.contains(r['filter'])));
  result = _where(result, 'ratingEntries', (e) => !bikeIds.contains(e['bike']));
  result = _dropTaskRules(result, {
    for (final rule in _list(result, 'taskRules'))
      if (bikeIds.contains(rule['bikeId'])) rule['id'] as String,
  });
  result = _where(result, 'taskEntries', (e) => !bikeIds.contains(e['bikeId']));
  result = _dropSetups(result, (s) => bikeIds.contains(s['bike']));
  return _dropComponents(result, componentIds);
}

/// Drops [componentIds], the components installed in them, their task rules
/// and their values in every setup.
_Json _dropComponents(_Json json, Set<String> componentIds) {
  final dropped = {...componentIds};
  var grew = true;
  while (grew) {
    grew = false;
    for (final component in _list(json, 'components')) {
      if (!dropped.contains(component['id']) &&
          _list(component, 'installations').any((i) => dropped.contains(i['parent']))) {
        grew = dropped.add(component['id'] as String) || grew;
      }
    }
  }
  var result = _dropAdjustments(json, (component, _) => dropped.contains(component['id']));
  result = _where(result, 'components', (c) => !dropped.contains(c['id']));
  result = _where(
    result,
    'ratings',
    (r) => !(r['filterType'] == 'FilterType.component' && dropped.contains(r['filter'])),
  );
  result = _dropTaskRules(result, {
    for (final rule in _list(result, 'taskRules'))
      if (dropped.contains(rule['componentId'])) rule['id'] as String,
  });
  return _where(result, 'taskEntries', (e) => !dropped.contains(e['componentId']));
}

/// Drops the adjustments that [test] matches and their values in every setup.
_Json _dropAdjustments(_Json json, bool Function(_Json component, _Json adjustment) test) {
  final adjustmentIds = {
    for (final component in _list(json, 'components'))
      for (final adjustment in _list(component, 'adjustments'))
        if (test(component, adjustment)) adjustment['id'] as String,
  };
  return {
    ...json,
    'components': [
      for (final component in _list(json, 'components'))
        {
          ...component,
          'adjustments': _list(component, 'adjustments').where((a) => !adjustmentIds.contains(a['id'])).toList(),
        },
    ],
    'setups': [
      for (final setup in _list(json, 'setups'))
        {
          ...setup,
          'bikeAdjustmentValues': {
            for (final MapEntry(:key, :value) in (setup['bikeAdjustmentValues'] as _Json).entries)
              if (!adjustmentIds.contains(key)) key: value,
          },
        },
    ],
  };
}

/// Drops the setups that [test] matches and the rating entries made on them.
_Json _dropSetups(_Json json, bool Function(_Json setup) test) {
  final setupIds = {
    for (final setup in _list(json, 'setups'))
      if (test(setup)) setup['id'] as String,
  };
  final result = _where(json, 'setups', (s) => !setupIds.contains(s['id']));
  return _where(result, 'ratingEntries', (e) => !setupIds.contains(e['setupId']));
}

/// Drops the task rules [ruleIds] and their entries.
_Json _dropTaskRules(_Json json, Set<String> ruleIds) {
  final result = _where(json, 'taskRules', (r) => !ruleIds.contains(r['id']));
  return _where(result, 'taskEntries', (e) => !ruleIds.contains(e['taskRule']));
}
