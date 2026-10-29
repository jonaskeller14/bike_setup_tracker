import 'dart:convert';

import 'package:drift/drift.dart' hide Component;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../models/adjustment/adjustment.dart';
import '../models/attachment.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/component_preset.dart';
import '../models/component/installation.dart';
import '../models/component_stats.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/feedback/feedback_comparison.dart';
import '../models/feedback/feedback_key.dart';
import '../models/feedback/feedback_observation.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';
import '../models/feedback/test_session_method.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/task/task_association.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold/task_threshold.dart';
import 'app_database.dart';
import 'daos/feedback_dao.dart';
import 'daos/setups_dao.dart';

extension BikeDbMapper on BikeDb {
  Bike toModel() {
    return Bike(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'Bike.lastModified'),
      name: name,
      notes: notes,
      person: person,
      stravaGear: stravaGear,
      orderIndex: orderIndex,
      initialStats: ComponentStats(
        distance: initialDistance,
        elevationGain: initialElevationGain,
        movingTime: initialMovingTime,
        elapsedTime: initialElapsedTime,
        activityCount: initialActivityCount,
        kilojoules: initialKilojoules,
      ),
      attachments: attachments,
    );
  }
}

extension ComponentDbMapper on ComponentDb {
  Component toModel({
    List<Adjustment> adjustments = const [],
    List<Installation> installations = const [],
  }) {
    return Component(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'Component.lastModified'),
      name: name,
      notes: notes,
      componentType: componentType,
      adjustments: adjustments,
      installations: installations,
      orderIndex: orderIndex,
      initialStats: ComponentStats(
        distance: initialDistance,
        elevationGain: initialElevationGain,
        movingTime: initialMovingTime,
        elapsedTime: initialElapsedTime,
        activityCount: initialActivityCount,
        kilojoules: initialKilojoules,
      ),
      preset: preset,
      attachments: attachments,
    );
  }
}

extension InstallationDbMapper on InstallationDb {
  Installation toModel() {
    final utc = _toUtcSafe(dateTimeUTC, 'Installation.dateTimeUTC');
    return switch (parentType) {
      // Defensive: a 'bike' row with no parent is treated as uninstalled.
      InstallationParentType.bike => parent == null
          ? Uninstallation(id: id, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal)
          : BikeInstallation(id: id, bikeId: parent!, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
      InstallationParentType.component => parent == null
          ? Uninstallation(id: id, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal)
          : ComponentInstallation(id: id, parentComponentId: parent!, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
      InstallationParentType.none =>
        Uninstallation(id: id, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
      InstallationParentType.archived =>
        Archival(id: id, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
    };
  }
}

extension AdjustmentDbMapper on AdjustmentDb {
  Adjustment toModel() {
    final Map<String, dynamic> payload = jsonDecode(jsonPayload ?? '{}') as Map<String, dynamic>;
    // Ensure core fields from the table override anything in the payload
    payload['id'] = id;
    payload['name'] = name;
    payload['notes'] = notes;
    payload['unit'] = unit;
    payload['type'] = type.name;
    payload['version'] = payload['version'] ?? 1;

    return Adjustment.fromJson(payload);
  }
}

extension PersonDbMapper on PersonDb {
  Person toModel({List<Adjustment> adjustments = const []}) {
    return Person(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'Person.lastModified'),
      name: name,
      notes: notes,
      stravaAthlete: stravaAthlete,
      adjustments: adjustments,
      orderIndex: orderIndex,
    );
  }
}

extension TaskRuleDbMapper on TaskRuleDb {
  TaskRule toModel() {
    return TaskRule(
      association: TaskAssociation.fromIds(componentId: componentId, bikeId: bikeId),
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'TaskRule.lastModified'),
      name: name,
      notes: notes,
      priority: priority,
      tags: tags,
      interval: interval != null ? TaskThreshold.fromJson(jsonDecode(interval!) as Map<String, dynamic>) : null,
      delay: delay != null ? TaskThreshold.fromJson(jsonDecode(delay!) as Map<String, dynamic>) : null,
      repeat: repeat,
      attachments: attachments,
      presetKey: presetKey,
    );
  }
}

extension TaskEntryDbMapper on TaskEntryDb {
  TaskEntry toModel() {
    return TaskEntry(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'TaskEntry.lastModified'),
      name: name,
      taskRule: taskRule,
      dateTimeUTC: _toUtcSafe(dateTimeUTC, 'TaskEntry.dateTimeUTC'),
      dateTimeLocal: dateTimeLocal,
      notes: notes,
      association: TaskAssociation.fromIds(componentId: componentId, bikeId: bikeId),
      snapshot: snapshot != null ? ComponentStats.fromJson(jsonDecode(snapshot!) as Map<String, dynamic>) : null,
      attachments: attachments,
    );
  }
}

// --- Reverse Mappers (Model -> Companion) ---

extension BikeMapper on Bike {
  BikesCompanion toCompanion() {
    return BikesCompanion(
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      person: Value<String?>(person),
      stravaGear: Value<String?>(stravaGear),
      orderIndex: Value<int>(orderIndex),
      initialDistance: Value<double>(initialStats.distance),
      initialElevationGain: Value<double>(initialStats.elevationGain),
      initialMovingTime: Value<Duration>(initialStats.movingTime),
      initialElapsedTime: Value<Duration>(initialStats.elapsedTime),
      initialActivityCount: Value<int>(initialStats.activityCount),
      initialKilojoules: Value<double>(initialStats.kilojoules),
      attachments: Value<List<Attachment>>(attachments),
    );
  }
}

extension ComponentMapper on Component {
  ComponentsCompanion toCompanion() {
    return ComponentsCompanion(
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      componentType: Value<ComponentType>(componentType),
      orderIndex: Value<int>(orderIndex),
      initialDistance: Value<double>(initialStats.distance),
      initialElevationGain: Value<double>(initialStats.elevationGain),
      initialMovingTime: Value<Duration>(initialStats.movingTime),
      initialElapsedTime: Value<Duration>(initialStats.elapsedTime),
      initialActivityCount: Value<int>(initialStats.activityCount),
      initialKilojoules: Value<double>(initialStats.kilojoules),
      preset: Value<ComponentPreset?>(preset),
      attachments: Value<List<Attachment>>(attachments),
    );
  }
}

extension InstallationMapper on Installation {
  InstallationsCompanion toCompanion({required String componentId}) {
    return InstallationsCompanion(
      id: Value(id),
      componentId: Value(componentId),
      parent: Value<String?>(parent),
      parentType: Value(parentType),
      dateTimeUTC: Value(dateTimeUTC),
      dateTimeLocal: Value(dateTimeLocal),
    );
  }
}

extension AdjustmentMapper on Adjustment {
  AdjustmentsCompanion toCompanion({
    String? componentId,
    String? personId,
    int? orderIndex,
  }) {
    final json = toJson();
    return AdjustmentsCompanion(
      id: Value<String>(id),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      unit: Value<String?>(unit?.encode()),
      type: Value<AdjustmentType>(type),
      componentId: componentId == null
          ? const Value.absent()
          : Value<String?>(componentId),
      personId: personId == null
          ? const Value.absent()
          : Value<String?>(personId),
      orderIndex: orderIndex == null
          ? const Value.absent()
          : Value<int>(orderIndex),
      jsonPayload: Value<String?>(jsonEncode(json)),
    );
  }
}

extension PersonMapper on Person {
  PersonsCompanion toCompanion() {
    return PersonsCompanion(
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      stravaAthlete: Value<int?>(stravaAthlete),
      orderIndex: Value<int>(orderIndex),
    );
  }
}

extension TaskRuleMapper on TaskRule {
  TaskRulesCompanion toCompanion() {
    return TaskRulesCompanion(
      componentId: Value<String?>(association.componentId),
      bikeId: Value<String?>(association.bikeId),
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      priority: Value<TaskPriority>(priority),
      tags: Value<Set<String>>(tags),
      interval: Value<String?>(interval != null ? jsonEncode(interval!.toJson()) : null),
      delay: Value<String?>(delay != null ? jsonEncode(delay!.toJson()) : null),
      repeat: Value<bool>(repeat),
      attachments: Value<List<Attachment>>(attachments),
      presetKey: Value<String?>(presetKey),
    );
  }
}

extension TaskEntryMapper on TaskEntry {
  TaskEntriesCompanion toCompanion() {
    return TaskEntriesCompanion(
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      dateTimeUTC: Value<DateTime>(dateTimeUTC),
      dateTimeLocal: Value<DateTime>(dateTimeLocal),
      taskRule: Value<String>(taskRule),
      componentId: Value<String?>(association.componentId),
      bikeId: Value<String?>(association.bikeId),
      snapshot: Value<String?>(snapshot != null ? jsonEncode(snapshot!.toJson()) : null),
      attachments: Value<List<Attachment>>(attachments),
    );
  }
}

extension SetupMapper on Setup {
  SetupsCompanion toCompanion() {
    return SetupsCompanion(
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String?>(name),
      isBookmarked: Value<bool>(isBookmarked),
      datetime: Value<DateTime>(datetime),
      datetimeLocal: Value<DateTime>(datetimeLocal),
      notes: Value<String?>(notes),
      tags: Value<Set<String>>(tags),
      attachments: Value<List<Attachment>>(attachments),
      bikeId: Value<String>(bike),
      personId: Value<String?>(person),
      position: Value<ContextPosition?>(position),
      place: Value<geo.Placemark?>(place),
      weather: Value<ContextWeather?>(weather),
      testSessionId: Value<String?>(testSessionId),
      sourceSetupId: Value<String?>(sourceSetupId),
      sourceKind: Value<SetupSourceKind?>(sourceKind),
    );
  }

  static Map<String, dynamic> placemarkToJson(geo.Placemark p) => {
    'name': p.name,
    'street': p.street,
    'isoCountryCode': p.isoCountryCode,
    'country': p.country,
    'postalCode': p.postalCode,
    'administrativeArea': p.administrativeArea,
    'subAdministrativeArea': p.subAdministrativeArea,
    'locality': p.locality,
    'subLocality': p.subLocality,
    'thoroughfare': p.thoroughfare,
    'subThoroughfare': p.subThoroughfare,
  };
}

extension SetupDbMapper on SetupDb {
  Setup toModel({
    List<TypedSetupValue> values = const [],
  }) {
    final bikeAdjustmentValues = <String, AdjustmentValue>{};
    final personAdjustmentValues = <String, AdjustmentValue>{};

    for (var typedValue in values) {
      final adj = typedValue.adjustment;
      if (adj == null) {
        // The owner of a removed adjustment is unknown; the bike map is where
        // the dangling UI picks it up.
        final unresolved = UnresolvedValue.orNull(typedValue.value.value);
        if (unresolved != null) bikeAdjustmentValues[typedValue.value.adjustmentId] = unresolved;
        continue;
      }
      final parsedValue = AdjustmentValue.decode(typedValue.value.value, adj.type);
      if (parsedValue == null) continue;

      if (adj.componentId != null) {
        bikeAdjustmentValues[adj.id] = parsedValue;
      } else if (adj.personId != null) {
        personAdjustmentValues[adj.id] = parsedValue;
      }
    }

    return Setup(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'Setup.lastModified'),
      name: name,
      isBookmarked: isBookmarked,
      datetime: _toUtcSafe(datetime, 'Setup.datetime'),
      datetimeLocal: datetimeLocal,
      notes: notes,
      tags: tags,
      attachments: attachments,
      bike: bikeId,
      person: personId,
      bikeAdjustmentValues: bikeAdjustmentValues,
      personAdjustmentValues: personAdjustmentValues,
      position: position,
      place: place,
      weather: weather,
      testSessionId: testSessionId,
      sourceSetupId: sourceSetupId,
      sourceKind: sourceKind,
    );
  }
}

extension FeedbackWithChildrenMapper on FeedbackWithChildren {
  RideFeedback toModel() {
    return RideFeedback(
      id: feedback.id,
      isDeleted: feedback.isDeleted,
      lastModified: _toUtcSafe(feedback.lastModified, 'Feedback.lastModified'),
      bike: feedback.bikeId,
      setupId: feedback.setupId,
      stravaActivityId: feedback.stravaActivityId,
      dateTimeUTC: _toUtcSafe(feedback.dateTimeUTC, 'Feedback.dateTimeUTC'),
      dateTimeLocal: feedback.dateTimeLocal,
      notes: feedback.notes,
      position: feedback.position,
      place: feedback.place,
      weather: feedback.weather,
      observations: {
        for (final o in observations)
          FeedbackObservation(key: FeedbackKey.parse(o.key), value: o.value, textValue: o.textValue),
      },
      comparisons: {
        for (final c in comparisons)
          FeedbackComparison(
            referenceSetupId: c.referenceSetupId,
            aspect: FeedbackAspect.parse(c.aspect),
            outcome: c.outcome,
          ),
      },
    );
  }
}

extension RideFeedbackMapper on RideFeedback {
  FeedbacksCompanion toCompanion() {
    return FeedbacksCompanion(
      id: Value<String>(id),
      bikeId: Value<String>(bike),
      setupId: Value<String>(setupId),
      stravaActivityId: Value<int?>(stravaActivityId),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      dateTimeUTC: Value<DateTime>(dateTimeUTC),
      dateTimeLocal: Value<DateTime>(dateTimeLocal),
      notes: Value<String?>(notes),
      position: Value<ContextPosition?>(position),
      place: Value<geo.Placemark?>(place),
      weather: Value<ContextWeather?>(weather),
    );
  }

  List<FeedbackObservationsCompanion> observationCompanions() {
    return [
      for (final o in observations)
        FeedbackObservationsCompanion(
          feedbackId: Value<String>(id),
          key: Value<String>(o.key.raw),
          value: Value<double?>(o.value),
          textValue: Value<String?>(o.textValue),
        ),
    ];
  }

  List<FeedbackComparisonsCompanion> comparisonCompanions() {
    return [
      for (final c in comparisons)
        FeedbackComparisonsCompanion(
          feedbackId: Value<String>(id),
          referenceSetupId: Value<String>(c.referenceSetupId),
          aspect: Value<String>(c.aspect.raw),
          outcome: Value<int>(c.outcome),
        ),
    ];
  }
}

extension TestSessionDbMapper on TestSessionDb {
  /// [adjustmentTypes] decodes the lock and proposal values; values of other
  /// ids stay unresolved.
  TestSession toModel({Map<String, AdjustmentType> adjustmentTypes = const {}}) {
    Map<String, AdjustmentValue> values(Object? json) =>
        Setup.adjustmentValuesFromJson(json as Map<String, dynamic>, adjustmentTypes: adjustmentTypes);

    return TestSession(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'TestSession.lastModified'),
      bike: bikeId,
      name: name,
      method: method != null ? TestSessionMethod.fromJson(jsonDecode(method!) as Map<String, dynamic>) : null,
      adjustmentIds: (jsonDecode(adjustmentIds) as List).cast<String>(),
      goal: (jsonDecode(goal) as List).map((e) => FeedbackAspect.parse(e as String)).toList(),
      locks: values(jsonDecode(locks)),
      startedAtUTC: _toUtcSafe(startedAtUTC, 'TestSession.startedAtUTC'),
      startedAtLocal: startedAtLocal,
      endedAtUTC: endedAtUTC,
      endedAtLocal: endedAtLocal,
      place: place,
      notes: notes,
      proposals: (jsonDecode(proposals) as Map<String, dynamic>).map(
        (setupId, json) => MapEntry(setupId, values(json)),
      ),
    );
  }
}

extension TestSessionMapper on TestSession {
  TestSessionsCompanion toCompanion() {
    return TestSessionsCompanion(
      id: Value<String>(id),
      bikeId: Value<String>(bike),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String?>(name),
      method: Value<String?>(method != null ? jsonEncode(method!.toJson()) : null),
      adjustmentIds: Value<String>(jsonEncode(adjustmentIds)),
      goal: Value<String>(jsonEncode(goal.map((a) => a.raw).toList())),
      locks: Value<String>(jsonEncode(Setup.adjustmentValuesToJson(locks))),
      startedAtUTC: Value<DateTime>(startedAtUTC),
      startedAtLocal: Value<DateTime>(startedAtLocal),
      endedAtUTC: Value<DateTime?>(endedAtUTC),
      endedAtLocal: Value<DateTime?>(endedAtLocal),
      place: Value<geo.Placemark?>(place),
      notes: Value<String?>(notes),
      proposals: Value<String>(jsonEncode(
        proposals.map((setupId, values) => MapEntry(setupId, Setup.adjustmentValuesToJson(values))),
      )),
    );
  }
}

extension StravaAthleteDbMapper on StravaAthleteDb {
  StravaAthlete toModel() {
    return StravaAthlete(
      id: id,
      lastModified: _toUtcSafe(lastModified, 'StravaAthlete.lastModified'),
      firstname: firstname,
      lastname: lastname,
      profile: profile,
      gears: gears,
    );
  }
}

extension StravaGearDbMapper on StravaGearDb {
  StravaGear toModel() {
    return StravaGear(
      id: id,
      lastModified: _toUtcSafe(lastModified, 'StravaGear.lastModified'),
      name: name,
    );
  }
}

extension StravaActivityDbMapper on StravaActivityDb {
  StravaActivity toModel() {
    return StravaActivity(
      id: id,
      lastModified: _toUtcSafe(lastModified, 'StravaActivity.lastModified'),
      name: name,
      athlete: athlete,
      sportType: sportType,
      startDate: _toUtcSafe(startDate, 'StravaActivity.startDate'),
      startDateLocal: startDateLocal,
      gearId: gearId,
      startLat: startLat,
      startLon: startLon,
      distance: distance,
      totalElevationGain: totalElevationGain,
      movingTime: Duration(seconds: movingTime),
      elapsedTime: Duration(seconds: elapsedTime),
      workoutType: workoutType,
      averageWatts: averageWatts,
    );
  }
}

extension StravaAthleteMapper on StravaAthlete {
  StravaAthletesCompanion toCompanion() {
    return StravaAthletesCompanion(
      id: Value(id),
      lastModified: Value(lastModified),
      firstname: Value(firstname),
      lastname: Value(lastname),
      profile: Value(profile),
      gears: Value(gears),
    );
  }
}

extension StravaGearMapper on StravaGear {
  StravaGearsCompanion toCompanion() {
    return StravaGearsCompanion(
      id: Value(id),
      lastModified: Value(lastModified),
      name: Value(name),
    );
  }
}

extension StravaActivityMapper on StravaActivity {
  StravaActivitiesCompanion toCompanion() {
    return StravaActivitiesCompanion(
      id: Value<int>(id),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      athlete: Value<int>(athlete),
      sportType: Value<SportType>(sportType),
      startDate: Value<DateTime>(startDate),
      startDateLocal: Value<DateTime>(startDateLocal),
      gearId: Value<String?>(gearId),
      startLat: Value<double?>(startLat),
      startLon: Value<double?>(startLon),
      distance: Value<double?>(distance),
      totalElevationGain: Value<double?>(totalElevationGain),
      movingTime: Value<int>(movingTime.inSeconds),
      elapsedTime: Value<int>(elapsedTime.inSeconds),
      workoutType: Value<int?>(workoutType),
      averageWatts: Value<double?>(averageWatts),
    );
  }
}

DateTime _toUtcSafe(DateTime dt, String fieldName) {
  if (!dt.isUtc) {
    debugPrint('WARNING: $fieldName read from DB as Local time. Converting to UTC.');
    return dt.toUtc();
  }
  return dt;
}
