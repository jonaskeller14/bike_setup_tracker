import 'dart:convert';
import 'package:drift/drift.dart' hide Component;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';
import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/component_stats.dart';
import '../models/context/context_weather.dart';
import '../models/installation.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/rating_association.dart';
import '../models/rating_entry.dart';
import '../models/rating_metric.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../models/task/task_entry.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_threshold.dart';
import 'adjustment_value_codec.dart';
import 'app_database.dart';
import 'daos/rating_entries_dao.dart';
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
      initialDistance: initialDistance,
      initialElevationGain: initialElevationGain,
      initialMovingTime: initialMovingTime,
      initialElapsedTime: initialElapsedTime,
      initialActivityCount: initialActivityCount,
    );
  }
}

extension InstallationDbMapper on InstallationDb {
  Installation toModel() {
    final utc = _toUtcSafe(dateTimeUTC, 'Installation.dateTimeUTC');
    return switch (parentType) {
      // Defensive: a 'bike' row with no parent is treated as uninstalled.
      InstallationParentType.bike => parent == null
          ? Uninstallation(id: id, componentId: componentId, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal)
          : BikeInstallation(id: id, componentId: componentId, bikeId: parent!, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
      InstallationParentType.none =>
        Uninstallation(id: id, componentId: componentId, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
      InstallationParentType.archived =>
        Archival(id: id, componentId: componentId, dateTimeUTC: utc, dateTimeLocal: dateTimeLocal),
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

extension RatingDbMapper on RatingDb {
  Rating toModel({List<RatingMetric> metrics = const []}) {
    return Rating(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'Rating.lastModified'),
      name: name,
      notes: notes,
      filter: filter,
      filterType: filterType,
      metrics: metrics,
      orderIndex: orderIndex,
    );
  }
}

extension RatingMetricDbMapper on RatingMetricDb {
  RatingMetric toModel() {
    final Map<String, dynamic> payload = jsonDecode(jsonPayload ?? '{}') as Map<String, dynamic>;
    payload['id'] = id;
    payload['name'] = name;
    payload['notes'] = notes;
    payload['unit'] = unit;
    payload['type'] = type.name;
    payload['version'] = payload['version'] ?? 1;

    return RatingMetric(
      adjustment: Adjustment.fromJson(payload),
      weight: weight,
    );
  }
}

extension TaskRuleDbMapper on TaskRuleDb {
  TaskRule toModel() {
    return TaskRule(
      componentId: componentId,
      bikeId: bikeId,
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
      componentId: componentId,
      bikeId: bikeId,
      snapshot: snapshot != null ? ComponentStats.fromJson(jsonDecode(snapshot!) as Map<String, dynamic>) : null,
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
      initialDistance: Value<double>(initialDistance),
      initialElevationGain: Value<double>(initialElevationGain),
      initialMovingTime: Value<Duration>(initialMovingTime),
      initialElapsedTime: Value<Duration>(initialElapsedTime),
      initialActivityCount: Value<int>(initialActivityCount),
    );
  }
}

extension InstallationMapper on Installation {
  InstallationsCompanion toCompanion() {
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
    final typeString = json['type'] as String;
    return AdjustmentsCompanion(
      id: Value<String>(id),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      unit: Value<String?>(unit?.encode()),
      type: Value<AdjustmentType>(
        AdjustmentType.values.firstWhere((e) => e.name == typeString),
      ),
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

extension RatingMetricMapper on RatingMetric {
  RatingMetricsCompanion toCompanion({
    required String ratingId,
    required int orderIndex,
  }) {
    final json = adjustment.toJson();
    final typeString = json['type'] as String;
    return RatingMetricsCompanion(
      id: Value<String>(adjustment.id),
      ratingId: Value<String>(ratingId),
      orderIndex: Value<int>(orderIndex),
      weight: Value<double>(weight),
      name: Value<String>(adjustment.name),
      notes: Value<String?>(adjustment.notes),
      unit: Value<String?>(adjustment.unit?.encode()),
      type: Value<AdjustmentType>(
        AdjustmentType.values.firstWhere((e) => e.name == typeString),
      ),
      jsonPayload: Value<String?>(jsonEncode(json)),
    );
  }
}

extension RatingMapper on Rating {
  RatingsCompanion toCompanion() {
    return RatingsCompanion(
      id: Value<String>(id),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String>(name),
      notes: Value<String?>(notes),
      filter: Value<String?>(filter),
      filterType: Value<FilterType>(filterType),
      orderIndex: Value<int>(orderIndex),
    );
  }
}

extension TaskRuleMapper on TaskRule {
  TaskRulesCompanion toCompanion() {
    return TaskRulesCompanion(
      componentId: Value<String?>(componentId),
      bikeId: Value<String?>(bikeId),
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
      componentId: Value<String?>(componentId),
      bikeId: Value<String?>(bikeId),
      snapshot: Value<String?>(snapshot != null ? jsonEncode(snapshot!.toJson()) : null),
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
      datetime: Value<DateTime>(datetime),
      datetimeLocal: Value<DateTime>(datetimeLocal),
      notes: Value<String?>(notes),
      tags: Value<Set<String>>(tags),
      images: Value<List<String>>(images),
      bikeId: Value<String>(bike),
      personId: Value<String?>(person),
      position: Value<LocationData?>(position),
      place: Value<geo.Placemark?>(place),
      weather: Value<ContextWeather?>(weather),
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
    final bikeAdjustmentValues = <String, dynamic>{};
    final personAdjustmentValues = <String, dynamic>{};

    for (var typedValue in values) {
      final adj = typedValue.adjustment;
      final valStr = typedValue.value.value;
      final dynamic parsedValue = decodeAdjustmentValue(valStr, adj.type);

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
      datetime: _toUtcSafe(datetime, 'Setup.datetime'),
      datetimeLocal: datetimeLocal,
      notes: notes,
      tags: tags,
      images: images,
      bike: bikeId,
      person: personId,
      bikeAdjustmentValues: bikeAdjustmentValues,
      personAdjustmentValues: personAdjustmentValues,
      position: position,
      place: place,
      weather: weather,
    );
  }
}

extension RatingEntryDbMapper on RatingEntryDb {
  RatingEntry toModel({List<TypedRatingEntryValue> values = const []}) {
    final metricValues = <String, dynamic>{};
    for (final typedValue in values) {
      metricValues[typedValue.metric.id] =
          decodeAdjustmentValue(typedValue.value.value, typedValue.metric.type);
    }

    return RatingEntry(
      id: id,
      isDeleted: isDeleted,
      lastModified: _toUtcSafe(lastModified, 'RatingEntry.lastModified'),
      name: name,
      bike: bikeId,
      setupId: setupId,
      dateTimeUTC: _toUtcSafe(dateTimeUTC, 'RatingEntry.dateTimeUTC'),
      dateTimeLocal: dateTimeLocal,
      notes: notes,
      metricValues: metricValues,
      position: position,
      place: place,
      weather: weather,
    );
  }
}

extension RatingEntryMapper on RatingEntry {
  RatingEntriesCompanion toCompanion() {
    return RatingEntriesCompanion(
      id: Value<String>(id),
      bikeId: Value<String>(bike),
      setupId: Value<String>(setupId),
      isDeleted: Value<bool>(isDeleted),
      lastModified: Value<DateTime>(lastModified),
      name: Value<String?>(name),
      dateTimeUTC: Value<DateTime>(dateTimeUTC),
      dateTimeLocal: Value<DateTime>(dateTimeLocal),
      notes: Value<String?>(notes),
      position: Value<LocationData?>(position),
      place: Value<geo.Placemark?>(place),
      weather: Value<ContextWeather?>(weather),
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
