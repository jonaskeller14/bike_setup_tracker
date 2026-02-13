import 'package:cloud_firestore/cloud_firestore.dart';

class StravaGear {
  final String id;
  DateTime lastModified;
  final String name;
  final int? frameType;

  StravaGear({
    required this.id,
    DateTime? lastModified,
    required this.name,
    required this.frameType,
  }): lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'id': id,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'frameType': frameType,
  };

  factory StravaGear.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return StravaGear(
          id: json["id"] as String,
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'] as String,
          frameType: json['frameType'] as int?,
        );
      default: throw Exception("Json Version $version of StravaGear incompatible.");
    }
  }

  factory StravaGear.fromFireStore(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return StravaGear(
          id: json["id"] as String,
          lastModified: (json["lastModified"] as Timestamp?)?.toDate().toUtc(),
          name: json['name'] as String,
          frameType: json['frameType'] as int?,
        );
      default: throw Exception("Json Version $version of StravaGear incompatible.");
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
        other is StravaGear &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        lastModified == other.lastModified &&
        name == other.name &&
        frameType == other.frameType;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      lastModified,
      name,
      frameType,
    );
  }
}