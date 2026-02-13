import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StravaAthlete {
  final int id;
  DateTime lastModified;
  final String? firstname;
  final String? lastname;
  final String? profile;
  final Set<String> gears;

  StravaAthlete({
    required this.id,
    DateTime? lastModified,
    required this.firstname,
    required this.lastname,
    required this.profile,
    required this.gears,
  }): lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'id': id,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'firstname': firstname,
    'lastname': lastname,
    'profile': profile,
    'gears': gears.toList(),
  };

  factory StravaAthlete.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return StravaAthlete(
          id: json["id"] as int,
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          firstname: json['firstname'] as String?,
          lastname: json['lastname'] as String?,
          profile: json['profile'] as String?,
          gears: (json['gears'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet(),
        );
      default: throw Exception("Json Version $version of StravaAthlete incompatible.");
    }
  }

  factory StravaAthlete.fromFireStore(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return StravaAthlete(
          id: json["id"] as int,
          lastModified: (json["lastModified"] as Timestamp?)?.toDate().toUtc(),
          firstname: json['firstname'] as String?,
          lastname: json['lastname'] as String?,
          profile: json['profile'] as String?,
          gears: (json['gears'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet(),
        );
      default: throw Exception("Json Version $version of StravaAthlete incompatible.");
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
        other is StravaAthlete &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        lastModified == other.lastModified &&
        firstname == other.firstname &&
        lastname == other.lastname &&
        profile == other.profile &&
        setEquals(gears, other.gears);
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      lastModified,
      firstname,
      lastname,
      profile,
      Object.hashAllUnordered(gears),
    );
  }
}