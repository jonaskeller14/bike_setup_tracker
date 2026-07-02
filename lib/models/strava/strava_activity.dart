import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

part 'strava_sportType.dart';

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
  final int? workoutType;  // 10=None, 11=Race, 12=Workout

  StravaActivity({
    required this.id,
    DateTime? lastModified,
    required this.name,
    required this.athlete,
    required this.sportType,
    required DateTime startDate,
    required this.startDateLocal,
    required this.gearId,
    required this.startLat,
    required this.startLon,
    required this.distance,
    required this.totalElevationGain,
    required this.movingTime,
    required this.elapsedTime,
    this.workoutType,
  }): lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
      startDate = startDate.toUtc();

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
    'workoutType': workoutType,
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
          sportType: SportType.fromString(json['sportType'] as String?),
          startDate: DateTime.parse(json['startDate']),
          startDateLocal: DateTime.parse(json['startDateLocal']).copyWith(isUtc: false),
          gearId: json['gearId'] as String?,
          startLat: (json['startLat'] as num?)?.toDouble(),
          startLon: (json['startLon'] as num?)?.toDouble(),
          distance: (json['distance'] as num?)?.toDouble(),
          totalElevationGain: (json['totalElevationGain'] as num?)?.toDouble(),
          movingTime: Duration(seconds: json['movingTime'] as int),
          elapsedTime: Duration(seconds: json['elapsedTime'] as int),
          workoutType: (json['workoutType'] as num?)?.toInt(),
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
          sportType: SportType.fromString(json['sportType'] as String?),
          startDate: DateTime.parse(json['startDate']),
          startDateLocal: DateTime.parse(json['startDateLocal']).copyWith(isUtc: false),
          gearId: json['gearId'] as String?,
          startLat: (json['startLat'] as num?)?.toDouble(),
          startLon: (json['startLon'] as num?)?.toDouble(),
          distance: (json['distance'] as num?)?.toDouble(),
          totalElevationGain: (json['totalElevationGain'] as num?)?.toDouble(),
          movingTime: Duration(seconds: json['movingTime'] as int),
          elapsedTime: Duration(seconds: json['elapsedTime'] as int),
          workoutType: (json['workoutType'] as num?)?.toInt(),
        );
      default: throw Exception("Json Version $version of StravaActivitiy incompatible.");
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
        elapsedTime == other.elapsedTime &&
        workoutType == other.workoutType;
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
      workoutType,
    );
  }
}