/// Named starting states for the demo flows, each derived from the merged
/// master sample, so only the master needs curating.
///
/// A flow picks one with a `# scenario: <id>` line. The run scripts write that
/// id to [DemoScenario.markerFile] in the app's documents folder before the
/// flow starts; without the marker the app seeds [DemoScenario.full].
library;

import 'sample_date_shift.dart';

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
  tags('tags'),

  /// The Canyon Grizl alone, with what a bike fit sets: saddle height and
  /// setback on the seatpost, stem length and spacers on a cockpit. Its
  /// setups hold the values from before the fit.
  bikeFit('bike_fit'),

  /// The full master with the installation timeline on, so moving a part to
  /// another bike asks for the date and shows up in the part's history.
  swap('swap'),

  /// The full master with a Hightower ride about every other day, so the
  /// activity histogram has bars worth comparing.
  histogram('histogram'),

  /// "Fork lowers service" at 46 of its 50 riding hours, and no task due.
  serviceLoopBefore('service_loop_before'),

  /// [serviceLoopBefore] two rides later: the fork service is the only task due.
  serviceLoopAfter('service_loop_after'),

  /// The full master with the Lyrik's dials all in the default style, so the
  /// flow can make rebound and LSC look like the knobs on the fork.
  dialStyle('dial_style'),

  /// The Hightower alone with four setups that differ at a glance, the newest
  /// three fork values away from the one that felt right, and no rides or tasks
  /// between them in the history.
  restore('restore'),

  /// The Hightower alone, its newest setup with rebound on 9, so the next setup
  /// starts from every value and changes one.
  oneClick('one_click'),

  /// The Grizl alone with the same loop three times: dry, wet, dry again, only
  /// the tire pressures changing.
  wetDry('wet_dry'),

  /// The Hightower and the Session with their parts and rides, and the
  /// installation timeline on: the pedals moved across and back.
  partKm('part_km'),

  /// The Hightower with four setups that change only the rebound, and rides
  /// between them that are easy to count per value.
  ridesPerValue('rides_per_value'),

  /// "Fork lowers service" with 14 of its 50 riding hours left, on a bike ridden
  /// about once a week.
  forecastWeekly('forecast_weekly'),

  /// [forecastWeekly] after two more rides this week: 10 of the 50 h left, and a
  /// faster pace.
  forecastMore('forecast_more'),

  /// [forecastWeekly], ridden every three days.
  forecastOften('forecast_often');

  const DemoScenario(this.id);

  /// The name used in flows and in the marker file.
  final String id;

  static const markerFile = 'demo_scenario';

  static DemoScenario fromId(String id) =>
      values.firstWhere((s) => s.id == id, orElse: () => throw ArgumentError.value(id, 'id', 'Unknown demo scenario'));

  /// Preferences written over `ScreenshotSeed.settings`.
  Map<String, Object> get settings => switch (this) {
    tags => const {'enableSetupTags': true, 'enableTaskTags': true},
    swap || partKm => const {'enableInstallationTimeline': true},
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
    bikeFit => _withBikeFit(_dropBikes(json, _ids(json, 'bikes').difference({_grizlId}))),
    swap => json,
    histogram => _addHightowerRides(
      json,
      from: _firstHightowerSetup(json).add(const Duration(days: 1)),
      to: _latestRide(json).subtract(const Duration(days: 1)),
      movingTimes: List.filled(26, 5400),
      firstId: 18100000001,
    ),
    serviceLoopBefore => _serviceLoop(json, due: false),
    serviceLoopAfter => _serviceLoop(json, due: true),
    dialStyle => _withDefaultDials(json, _lyrikId),
    restore => _withRestoreHistory(json),
    oneClick => _oneClick(json),
    wetDry => _wetDry(json),
    partKm => _partKm(json),
    ridesPerValue => _ridesPerValue(json),
    forecastWeekly => _forecast(json, gapDays: 7),
    forecastMore => _forecast(json, gapDays: 7, idleDays: 2, moreRides: 2),
    forecastOften => _forecast(json, gapDays: 3),
  };
}

const String _grizlId = '2f04a328-75ee-4917-b140-2cafdaf1606f';
const String _grizlSeatpostId = 'dc2ffc45-7454-405f-b41c-be443d708fdb';
const String _saddleHeightId = '22162aac-e637-4b56-b1c5-9a1b6c0be1ba';
const String _saddleSetbackId = '7c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5';
const String _grizlCockpitId = '8d2e3f4a-5b6c-4d7e-9f80-a1b2c3d4e5f6';
const String _stemLengthId = '9e3f4a5b-6c7d-4e8f-a091-b2c3d4e5f607';
const String _spacersId = 'af4a5b6c-7d8e-4f90-b1a2-c3d4e5f60718';

const String _lyrikId = 'e47480ee-0f71-453e-bb97-61d2041d05f5';
const String _lyrikPressureId = '22866141-fe35-4cdc-99df-6e1ba91c1033';
const String _lyrikLscId = '2fae94d6-16d2-4b79-ad4b-55f6b9fa6e1d';
const String _lyrikReboundId = 'aefea436-580a-479b-bcd4-943a93c8e2fb';
const String _strombergSetupId = '665a7021-6bbc-4502-ad85-2f44ad17b087';
const String _lacBlancSetupId = '60546389-6a03-4f2a-86ff-ef00779c5340';
const String _finaleSetupId = 'aef06f55-8000-42f0-b9e9-d6d71ec2716b';
const String _steepChuteSetupId = '2e44d8eb-2141-4845-9b53-6ef7d3c17bc1';
// Clicks count from closed: fewer LSC clicks are firmer, more rebound clicks are faster.
const _restoreChange = {_lyrikPressureId: 88, _lyrikLscId: 6, _lyrikReboundId: 11};

const String _backToNeutralSetupId = '7bd910e8-e09f-4168-9217-e0583bbbdcdd';
const String _endOfMaySetupId = '50d59709-8863-40e0-8671-6cf4f0f3bc05';

const String _kaiserstuhlSetupId = '9c622baf-c14c-4631-b0a2-3d3ab01c6696';
const String _grizlFrontPressureId = 'e8bf4053-f593-4d05-a539-0e8a84e3ca3d';
const String _grizlRearPressureId = 'ee796534-cfd8-4d89-9f81-2b31396746a2';

const String _sessionId = '5c9f1ccd-f00b-4145-ad8d-5e74fbf3c55a';

const String _hightowerGearId = 'b18168107';
const String _forkLowersRuleId = '340ef012-fb70-40d6-889e-02ac62dd6699';
const String _bbCreakingRuleId = 'd18b5523-f7a1-46b2-8348-ee765964d139';

/// The fork services of May and June; without them the last one is the
/// autumn service, so the riding hours since are a winter's worth.
const Set<String> _recentForkServiceIds = {
  '252d23f9-3647-4b23-b8de-b9ba15373734',
  '5f1a9c72-4e8b-4d16-8a58-1b7e4f6a8a08',
};

/// Riding hours of the generated rides: with the master's Hightower rides
/// (10 h 10 min) they add up to 46 h, 4 h short of the 50 h interval; the two
/// rides of [DemoScenario.serviceLoopAfter] take it to 51.5 h, due but not
/// yet overdue (55 h).
final List<int> _winterRideSeconds = List.generate(16, (i) => i.isEven ? 7200 : 8925);
const List<int> _dueRideSeconds = [9900, 9900];

_Json _serviceLoop(_Json json, {required bool due}) {
  var result = _dropTaskRules(json, {..._otherDueTaskRuleIds, _bbCreakingRuleId});
  result = _where(result, 'taskEntries', (e) => !_recentForkServiceIds.contains(e['id']));
  final lastService = _list(result, 'taskEntries')
      .where((e) => e['taskRule'] == _forkLowersRuleId)
      .map((e) => DateTime.parse(e['dateTimeUTC'] as String))
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final latest = _latestRide(result);
  result = _addHightowerRides(
    result,
    from: lastService.add(const Duration(days: 4)),
    to: _hightowerRides(result).first.subtract(const Duration(days: 4)),
    movingTimes: _winterRideSeconds,
    firstId: 18200000001,
  );
  if (!due) return result;
  return _addHightowerRides(
    result,
    from: latest.subtract(const Duration(days: 3)),
    to: latest.subtract(const Duration(days: 1)),
    movingTimes: _dueRideSeconds,
    firstId: 18200000101,
  );
}

DateTime _firstHightowerSetup(_Json json) => _list(json, 'setups')
    .where((s) => s['bike'] == _hightowerId)
    .map((s) => DateTime.parse(s['datetime'] as String))
    .reduce((a, b) => a.isBefore(b) ? a : b);

List<DateTime> _hightowerRides(_Json json) => _list(
  json,
  'stravaActivities',
).where((a) => a['gearId'] == _hightowerGearId).map((a) => DateTime.parse(a['startDate'] as String)).toList()..sort();

DateTime _latestRide(_Json json) => _list(
  json,
  'stravaActivities',
).map((a) => DateTime.parse(a['startDate'] as String)).reduce((a, b) => a.isAfter(b) ? a : b);

/// Adds one Hightower hometrail ride per [movingTimes] entry (seconds),
/// evenly from [from] to [to], each at 17:00 local time (CEST).
_Json _addHightowerRides(
  _Json json, {
  required DateTime from,
  required DateTime to,
  required List<int> movingTimes,
  required int firstId,
}) {
  final span = to.difference(from);
  final rides = <_Json>[];
  for (final (i, seconds) in movingTimes.indexed) {
    final day = from.add(span * (movingTimes.length == 1 ? 0 : i / (movingTimes.length - 1)));
    final start = DateTime.utc(day.year, day.month, day.day, 15);
    rides.add({
      'id': firstId + i,
      'lastModified': start.add(Duration(seconds: seconds * 2)).toIso8601String(),
      'name': i.isEven ? 'Evening Mountain Bike Ride' : 'Afternoon Mountain Bike Ride',
      'athleteId': 100000001,
      'sportType': 'MountainBikeRide',
      'startDate': start.toIso8601String(),
      'startDateLocal': start.add(const Duration(hours: 2)).toIso8601String().replaceFirst('Z', ''),
      'gearId': _hightowerGearId,
      'startLat': 48.7758,
      'startLon': 9.1829,
      'distance': (seconds * 4.4).roundToDouble(),
      'totalElevationGain': (seconds / 3600 * 320).roundToDouble(),
      'movingTime': seconds,
      'elapsedTime': (seconds * 1.3).round(),
      'workoutType': null,
      'averageWatts': 160.0,
    });
  }
  return {
    ...json,
    'stravaActivities': [..._list(json, 'stravaActivities'), ...rides],
  };
}

_Json _numerical(String id, String name, String unit, {String? notes}) => {
  'version': 1,
  'id': id,
  'name': name,
  'notes': notes,
  'type': 'numerical',
  'unit': unit,
  'category': 'AdjustmentCategory.component',
  'min': null,
  'max': null,
};

/// Adds the fit adjustments and gives the Grizl's setups their pre-fit values.
_Json _withBikeFit(_Json json) {
  const preFit = {_saddleHeightId: 738.0, _saddleSetbackId: 25.0, _stemLengthId: 90.0, _spacersId: 20.0};
  final cockpit = <String, dynamic>{
    'version': 4,
    'id': _grizlCockpitId,
    'isDeleted': false,
    'lastModified': '2026-06-10T18:00:00.000Z',
    'name': 'Cockpit',
    'componentType': 'ComponentType.cockpit',
    'installations': [
      {
        'type': 'bike',
        'id': 'b05b6c7d-8e9f-4a01-82b3-d4e5f6071829',
        'componentId': _grizlCockpitId,
        'parent': _grizlId,
        'dateTimeUTC': '1970-01-01T00:00:00.000Z',
        'dateTimeLocal': '1970-01-01T01:00:00.000',
      },
    ],
    'notes': null,
    'orderIndex': 1,
    'adjustments': [
      _numerical(_stemLengthId, 'Stem Length', 'mm'),
      _numerical(_spacersId, 'Spacers', 'mm', notes: 'Under the stem'),
    ],
    'initialDistance': 0.0,
    'initialElevationGain': 0.0,
    'initialMovingTime': 0,
    'initialElapsedTime': 0,
    'initialActivityCount': 0,
  };
  return {
    ...json,
    'components': [
      for (final component in _list(json, 'components'))
        component['id'] == _grizlSeatpostId
            ? {
                ...component,
                'adjustments': [
                  ..._list(component, 'adjustments'),
                  _numerical(_saddleSetbackId, 'Saddle Setback', 'mm', notes: 'Saddle tip behind the BB'),
                ],
              }
            : component,
      cockpit,
    ],
    'setups': [
      for (final setup in _list(json, 'setups'))
        setup['bike'] == _grizlId
            ? {
                ...setup,
                'bikeAdjustmentValues': {...setup['bikeAdjustmentValues'] as _Json, ...preFit},
              }
            : setup,
    ],
  };
}

/// Reduces the Hightower's history to Stromberg, Lac Blanc and Finale, then a
/// firmer fork that didn't work out: the steep chute setup, 3 fork values from Finale.
_Json _withRestoreHistory(_Json json) {
  final hightower = _dropBikes(json, _ids(json, 'bikes').difference({_hightowerId}));
  _Json setup(String id) => _list(hightower, 'setups').firstWhere((s) => s['id'] == id);
  final finaleValues = {
    ...setup(_lacBlancSetupId)['bikeAdjustmentValues'] as _Json,
    _lyrikLscId: 8,
    _lyrikReboundId: 9,
  };
  final result = _dropTaskRules(hightower, _ids(hightower, 'taskRules'));
  return {
    ..._where(result, 'stravaActivities', (_) => false),
    'setups': [
      setup(_strombergSetupId),
      setup(_lacBlancSetupId),
      {
        ...setup(_finaleSetupId),
        'notes': 'Fork felt right: calm on the rocks, plenty of grip.',
        'bikeAdjustmentValues': finaleValues,
      },
      {
        ...setup(_steepChuteSetupId),
        'name': 'Firmer fork',
        'notes': 'More pressure, firmer LSC, faster rebound. Harsh on the roots now.',
        'bikeAdjustmentValues': {...finaleValues, ..._restoreChange},
        'personAdjustmentValues': setup(_finaleSetupId)['personAdjustmentValues'],
      },
    ],
  };
}

_Json _oneClick(_Json json) {
  final hightower = _dropBikes(json, _ids(json, 'bikes').difference({_hightowerId}));
  return _dropSetups(
    _where(_dropTaskRules(hightower, _ids(hightower, 'taskRules')), 'stravaActivities', (_) => false),
    (s) => const {_steepChuteSetupId, _backToNeutralSetupId}.contains(s['id']),
  );
}

/// The Kaiserstuhl setup as three rides of one loop, a week apart: the same place,
/// and the tire pressures and the ground the only things that differ.
_Json _wetDry(_Json json) {
  final grizl = _dropBikes(json, _ids(json, 'bikes').difference({_grizlId}));
  final base = _list(grizl, 'setups').firstWhere((s) => s['id'] == _kaiserstuhlSetupId);
  _Json ride(String id, String name, int daysAfter, double front, double rear, double soilMoisture, double dayRain, double temperature) {
    String moved(String key, _Json source) =>
        DateTime.parse(source[key] as String).add(Duration(days: daysAfter)).toIso8601String();
    final weather = base['weather'] as _Json;
    final datetime = moved('datetime', base);
    return {
      ...base,
      'id': id,
      'name': name,
      'notes': null,
      'tags': const <String>[],
      'datetime': datetime,
      'lastModified': datetime,
      'datetimeLocal': moved('datetimeLocal', base),
      'bikeAdjustmentValues': {
        ...base['bikeAdjustmentValues'] as _Json,
        _grizlFrontPressureId: front,
        _grizlRearPressureId: rear,
      },
      'weather': {
        ...weather,
        'currentDateTime': moved('currentDateTime', weather),
        'currentTemperature': temperature,
        'currentSoilMoisture0to7cm': soilMoisture,
        'dayAccumulatedPrecipitation': dayRain,
        'currentWeatherCode': dayRain > 0 ? 61 : 1,
        'condition': soilMoisture < 0.1 ? 'Condition.dry' : 'Condition.wet',
      },
    };
  }

  return {
    ..._where(_dropTaskRules(grizl, _ids(grizl, 'taskRules')), 'stravaActivities', (_) => false),
    'setups': [
      ride('1d6e4b70-3c55-4a3e-9d21-6f0a7b8c9d01', 'Kaiserstuhl - dry', -14, 2.6, 2.8, 0.08, 0.0, 14.0),
      ride('2e7f5c81-4d66-4b4f-8e32-7a1b8c9d0e12', 'Kaiserstuhl - wet', -7, 2.4, 2.6, 0.3, 6.5, 11.0),
      ride('3f806d92-5e77-4c50-9f43-8b2c9d0e1f23', 'Kaiserstuhl - dry', 0, 2.6, 2.8, 0.08, 0.0, 14.0),
    ],
  };
}

_Json _partKm(_Json json) {
  final bikes = _dropBikes(json, _ids(json, 'bikes').difference({_hightowerId, _sessionId}));
  final uninstalled = {
    for (final component in _list(bikes, 'components'))
      if (_list(component, 'installations').last['type'] != 'bike') component['id'] as String,
  };
  return _dropSetups(_dropComponents(_dropTaskRules(bikes, _ids(bikes, 'taskRules')), uninstalled), (_) => true);
}

/// Four setups differing in the Lyrik's rebound only, with 3 rides on 8 clicks, 7
/// on 9 (the newest setup's value) and 4 on 10.
_Json _ridesPerValue(_Json json) {
  final hightower = _dropBikes(json, _ids(json, 'bikes').difference({_hightowerId}));
  final result = _dropTaskRules(hightower, _ids(hightower, 'taskRules'));
  final setups = _list(result, 'setups');
  _Json setup(String id) => setups.firstWhere((s) => s['id'] == id);
  final values = setup(_endOfMaySetupId)['bikeAdjustmentValues'] as _Json;
  final windows = [(_strombergSetupId, 8, 3), (_lacBlancSetupId, 9, 4), (_endOfMaySetupId, 10, 4), (_backToNeutralSetupId, 9, 3)];
  var withRides = _where(result, 'stravaActivities', (_) => false);
  for (final (i, (id, _, count)) in windows.indexed) {
    final from = DateTime.parse(setup(id)['datetime'] as String).add(const Duration(days: 1));
    final to = i + 1 < windows.length
        ? DateTime.parse(setup(windows[i + 1].$1)['datetime'] as String).subtract(const Duration(days: 1))
        : from.add(const Duration(days: 9));
    withRides = _addHightowerRides(
      withRides,
      from: from,
      to: to,
      movingTimes: List.filled(count, 5400),
      firstId: 18300000001 + i * 100,
    );
  }
  return {
    ...withRides,
    'setups': [
      for (final (id, rebound, _) in windows)
        {
          ...setup(id),
          'notes': null,
          'bikeAdjustmentValues': {...values, _lyrikReboundId: rebound},
        },
    ],
  };
}

/// 18 rides of 2 h since the last fork service, the newest [idleDays] before the
/// sample's last day and each [gapDays] apart: 36 of the 50 h, and the forecast's
/// sample of 10 rides at the pace the Short names. [moreRides] then follow, one a
/// day up to the last day.
_Json _forecast(_Json json, {required int gapDays, int idleDays = 0, int moreRides = 0}) {
  final lastDay = newestSampleDate(json)!;
  final hightower = _dropBikes(json, _ids(json, 'bikes').difference({_hightowerId}));
  var result = _dropTaskRules(hightower, _ids(hightower, 'taskRules').difference({_forkLowersRuleId}));
  result = _where(result, 'taskEntries', (e) => !_recentForkServiceIds.contains(e['id']));
  final newest = lastDay.subtract(Duration(days: idleDays));
  final rides = _addHightowerRides(
    _dropSetups(
      _where(result, 'stravaActivities', (_) => false),
      (s) => const {_steepChuteSetupId, _backToNeutralSetupId}.contains(s['id']),
    ),
    from: newest.subtract(Duration(days: 17 * gapDays)),
    to: newest,
    movingTimes: List.filled(18, 7200),
    firstId: 18400000001,
  );
  if (moreRides == 0) return rides;
  return _addHightowerRides(
    rides,
    from: lastDay.subtract(Duration(days: moreRides - 1)),
    to: lastDay,
    movingTimes: List.filled(moreRides, 7200),
    firstId: 18400000101,
  );
}

/// Resets the color and size of [componentId]'s dials to the defaults.
_Json _withDefaultDials(_Json json, String componentId) => {
  ...json,
  'components': [
    for (final component in _list(json, 'components'))
      component['id'] == componentId
          ? {
              ...component,
              'adjustments': [
                for (final adjustment in _list(component, 'adjustments'))
                  adjustment['type'] == 'step' ? {...adjustment, 'dialColor': 'blue', 'dialSize': 'normal'} : adjustment,
              ],
            }
          : component,
  ],
};

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

/// Drops the setups that [test] matches.
_Json _dropSetups(_Json json, bool Function(_Json setup) test) {
  final setupIds = {
    for (final setup in _list(json, 'setups'))
      if (test(setup)) setup['id'] as String,
  };
  return _where(json, 'setups', (s) => !setupIds.contains(s['id']));
}

/// Drops the task rules [ruleIds] and their entries.
_Json _dropTaskRules(_Json json, Set<String> ruleIds) {
  final result = _where(json, 'taskRules', (r) => !ruleIds.contains(r['id']));
  return _where(result, 'taskEntries', (e) => !ruleIds.contains(e['taskRule']));
}
