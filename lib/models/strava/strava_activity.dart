import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names
enum SportType {
  AlpineSki("Alpine Ski"),
  BackcountrySki("Backcountry Ski"),
  Badminton("Badminton"),
  Canoeing("Canoeing"),
  Crossfit("Crossfit"),
  EBikeRide("E-Bike Ride"),
  Elliptical("Elliptical"),
  EMountainBikeRide("E-Mountain Bike Ride"),
  Golf("Golf"),
  GravelRide("Gravel Ride"),
  Handcycle("Handcycle"),
  HighIntensityIntervalTraining("HIIT"),
  Hike("Hike"),
  IceSkate("Ice Skate"),
  InlineSkate("Inline Skate"),
  Kayaking("Kayaking"),
  Kitesurf("Kitesurf"),
  MountainBikeRide("Mountain Bike Ride"),
  NordicSki("Nordic Ski"),
  Pickleball("Pickleball"),
  Pilates("Pilates"),
  Racquetball("Racquetball"),
  Ride("Ride"),
  RockClimbing("Rock Climbing"),
  RollerSki("Roller Ski"),
  Rowing("Rowing"),
  Run("Run"),
  Sail("Sail"),
  Skateboard("Skateboard"),
  Snowboard("Snowboard"),
  Snowshoe("Snowshoe"),
  Soccer("Soccer"),
  Squash("Squash"),
  StairStepper("Stair Stepper"),
  StandUpPaddling("Stand Up Paddling"),
  Surfing("Surfing"),
  Swim("Swim"),
  TableTennis("Table Tennis"),
  Tennis("Tennis"),
  TrailRun("Trail Run"),
  Velomobile("Velomobile"),
  VirtualRide("Virtual Ride"),
  VirtualRow("Virtual Row"),
  VirtualRun("Virtual Run"),
  Walk("Walk"),
  WeightTraining("Weight Training"),
  Wheelchair("Wheelchair"),
  Windsurf("Windsurf"),
  Workout("Workout"),
  Yoga("Yoga"),
  Other("Other");

  final String label;
  const SportType(this.label);

  IconData getIconData() {
    switch (this) {
      case SportType.MountainBikeRide || SportType.EMountainBikeRide || SportType.GravelRide || SportType.RockClimbing:
        return Icons.terrain;
      case SportType.Ride || SportType.EBikeRide || SportType.Handcycle || SportType.Velomobile || SportType.VirtualRide:
        return Icons.directions_bike;
      case SportType.Run || SportType.TrailRun || SportType.VirtualRun:
        return Icons.directions_run;
      case SportType.Hike || SportType.Walk || SportType.Snowshoe:
        return Icons.directions_walk;
      case SportType.Swim:
        return Icons.pool;
      case SportType.AlpineSki || SportType.BackcountrySki || SportType.NordicSki || SportType.RollerSki:
        return Icons.downhill_skiing;
      case SportType.Snowboard:
        return Icons.snowboarding;
      case SportType.Kayaking || SportType.Canoeing || SportType.StandUpPaddling:
        return Icons.kayaking;
      case SportType.Rowing || SportType.VirtualRow:
        return Icons.rowing;
      case SportType.WeightTraining || SportType.Crossfit || SportType.Workout || SportType.HighIntensityIntervalTraining || SportType.Elliptical || SportType.StairStepper:
        return Icons.fitness_center;
      case SportType.Yoga || SportType.Pilates:
        return Icons.self_improvement;
      case SportType.Tennis || SportType.Badminton || SportType.Pickleball || SportType.Racquetball || SportType.Squash || SportType.TableTennis:
        return Icons.sports_tennis;
      case SportType.Golf:
        return Icons.sports_golf;
      case SportType.Soccer:
        return Icons.sports_soccer;
      case SportType.IceSkate || SportType.InlineSkate:
        return Icons.ice_skating;
      case SportType.Skateboard:
        return Icons.skateboarding;
      case SportType.Sail || SportType.Windsurf || SportType.Kitesurf:
        return Icons.sailing;
      case SportType.Surfing:
        return Icons.surfing;
      case SportType.Wheelchair:
        return Icons.accessible;
      case SportType.Other:
        return Icons.question_mark;
    }
  }
}

class StravaActivity {
  final int id;
  DateTime lastModified;
  final String name;
  final int athlete;
  final SportType sportType;
  final DateTime startDate;
  final DateTime startDateLocal;
  final String? gearId;
  final double? startLat;
  final double? startLon;

  final double? distance;
  final double? totalElevationGain;
  final Duration movingTime;
  final Duration elapsedTime;

  StravaActivity({
    required this.id,
    DateTime? lastModified,
    required this.name,
    required this.athlete,
    required this.sportType,
    required this.startDate,
    required this.startDateLocal,
    required this.gearId,
    required this.startLat,
    required this.startLon,
    required this.distance,
    required this.totalElevationGain,
    required this.movingTime,
    required this.elapsedTime,
  }): lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'id': id,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'athleteId': athlete,
    'sportType': sportType.name,
    'startDate': startDate.toUtc().toIso8601String(),
    'startDateLocal': startDateLocal.toIso8601String(),
    'gearId': gearId,
    'startLat': startLat,
    'startLon': startLon,
    'distance': distance,
    'totalElevationGain': totalElevationGain,
    'movingTime': movingTime.inSeconds,
    'elapsedTime': elapsedTime.inSeconds,
  };

  factory StravaActivity.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return StravaActivity(
          id: json["id"] as int,
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'] as String,
          athlete: json['athleteId'] as int,
          sportType: _parseSportType(json['sportType'] as String?),
          startDate: DateTime.parse(json['startDate']),
          startDateLocal: DateTime.parse(json['startDateLocal']),
          gearId: json['gearId'] as String?,
          startLat: (json['startLat'] as num?)?.toDouble(),
          startLon: (json['startLon'] as num?)?.toDouble(),
          distance: (json['distance'] as num?)?.toDouble(),
          totalElevationGain: (json['totalElevationGain'] as num?)?.toDouble(),
          movingTime: Duration(seconds: json['movingTime'] as int),
          elapsedTime: Duration(seconds: json['elapsedTime'] as int),
        );
      default: throw Exception("Json Version $version of StravaActivitiy incompatible.");
    }
  }

  factory StravaActivity.fromFirestore(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return StravaActivity(
          id: json["id"] as int,
          lastModified: (json["lastModified"] as Timestamp?)?.toDate().toUtc(),
          name: json['name'] as String,
          athlete: json['athleteId'] as int,
          sportType: _parseSportType(json['sportType'] as String?),
          startDate: DateTime.parse(json['startDate']),
          startDateLocal: DateTime.parse(json['startDateLocal']),
          gearId: json['gearId'] as String?,
          startLat: (json['startLat'] as num?)?.toDouble(),
          startLon: (json['startLon'] as num?)?.toDouble(),
          distance: (json['distance'] as num?)?.toDouble(),
          totalElevationGain: (json['totalElevationGain'] as num?)?.toDouble(),
          movingTime: Duration(seconds: json['movingTime'] as int),
          elapsedTime: Duration(seconds: json['elapsedTime'] as int),
        );
      default: throw Exception("Json Version $version of StravaActivitiy incompatible.");
    }
  }

  static SportType _parseSportType(String? value) {
    if (value == null) return SportType.Other;
    try {
      return SportType.values.byName(value);
    } catch (_) {
      return SportType.Other;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
        other is StravaActivity &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        lastModified == other.lastModified &&
        name == other.name &&
        athlete == other.athlete &&
        sportType == other.sportType &&
        startDate == other.startDate &&
        startDateLocal == other.startDateLocal &&
        gearId == other.gearId &&
        startLat == other.startLat &&
        startLon == other.startLon &&
        distance == other.distance &&
        totalElevationGain == other.totalElevationGain &&
        movingTime == other.movingTime &&
        elapsedTime == other.elapsedTime;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      lastModified,
      name,
      athlete,
      sportType,
      startDate,
      startDateLocal,
      gearId,
      startLat,
      startLon,
      distance,
      totalElevationGain,
      movingTime,
      elapsedTime,
    );
  }
}