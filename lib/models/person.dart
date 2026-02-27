import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';

class Person {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final String? notes;
  final int? stravaAthlete;
  final List<Adjustment> adjustments;

  static const IconData iconData = Icons.person;

  Person({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    this.stravaAthlete,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Person deepCopy() {
    return Person(
      name: name,
      notes: notes,
      stravaAthlete: stravaAthlete,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'stravaAthlete': stravaAthlete,
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
  };

  factory Person.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return Person(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          notes: json['notes'],
          stravaAthlete: json['stravaAthlete'],
          adjustments: (json["adjustments"] as List<dynamic>?)?.map((adjustmentJson) => Adjustment.fromJson(
            adjustmentJson, 
            defaultCategory: AdjustmentCategory.body)).toList() ?? <Adjustment>[],
        );
      default: throw Exception("Json Version $version of Person incompatible.");
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Person &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        notes == other.notes &&
        stravaAthlete == other.stravaAthlete &&
        listEquals(adjustments, other.adjustments);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isDeleted,
      lastModified,
      name,
      notes,
      stravaAthlete,
      Object.hashAll(adjustments),
    );
  }

  Person copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? stravaAthlete = const _Sentinel(),
    Object? adjustments = const _Sentinel(),
  }) {
    return Person(
      id: id is _Sentinel 
          ? this.id 
          : (id as String),
      isDeleted: isDeleted is _Sentinel 
          ? this.isDeleted 
          : (isDeleted as bool),
      lastModified: lastModified is _Sentinel 
          ? this.lastModified 
          : (lastModified as DateTime),
      name: name is _Sentinel 
          ? this.name 
          : (name as String),
      notes: notes is _Sentinel 
          ? this.notes 
          : (notes as String?),
      stravaAthlete: stravaAthlete is _Sentinel 
          ? this.stravaAthlete 
          : (stravaAthlete as int?),
      adjustments: adjustments is _Sentinel 
          ? this.adjustments 
          : (adjustments as List<Adjustment>),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
