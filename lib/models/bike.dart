import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'component_stats.dart';

class Bike {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final String? person;
  final String? stravaGear;
  final int orderIndex;
  final ComponentStats initialStats;

  static const IconData iconData = Icons.pedal_bike;

  Bike({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required this.person,
    this.stravaGear,
    this.orderIndex = 0,
    ComponentStats? initialStats,
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc(),
      initialStats = initialStats ?? ComponentStats.zero();

  Map<String, dynamic> toJson() => {
    'version': 5,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'person': person,
    'stravaGear': stravaGear,
    'orderIndex': orderIndex,
    'initialStats': initialStats.toJson(),
  };

  factory Bike.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1 || 2 || 3 || 4 || 5:
        final initialStats = json['initialStats'] as Map<String, dynamic>?; // since version 5
        return Bike(
          id: json["id"] as String?,
          isDeleted: json["isDeleted"] as bool?,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          notes: json['notes'] as String?, // = null
          person: json['person'] as String?, // = null
          stravaGear: json['stravaGear'] as String?, // = null
          orderIndex: json['orderIndex'] as int? ?? 0,
          initialStats: initialStats == null ? null : ComponentStats.fromJson(initialStats),
        );
      default: throw Exception("Json Version $version of Bike incompatible.");
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
        other is Bike &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        notes == other.notes &&
        person == other.person &&
        stravaGear == other.stravaGear &&
        initialStats == other.initialStats;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isDeleted,
      lastModified,
      name,
      notes,
      person,
      stravaGear,
      initialStats,
    );
  }

  Bike deepCopy() {
    return Bike(
      name: name,
      notes: notes,
      person: person,
      stravaGear: stravaGear,
      orderIndex: orderIndex,
      initialStats: initialStats,
    );
  }

  Bike copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? person = const _Sentinel(),
    Object? stravaGear = const _Sentinel(),
    Object? orderIndex = const _Sentinel(),
    Object? initialStats = const _Sentinel(),
  }) {
    return Bike(
      id: id is _Sentinel ? this.id : (id as String),
      isDeleted: isDeleted is _Sentinel ? this.isDeleted : (isDeleted as bool),
      lastModified: lastModified is _Sentinel ? this.lastModified : (lastModified as DateTime),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      person: person is _Sentinel ? this.person : (person as String?),
      stravaGear: stravaGear is _Sentinel ? this.stravaGear : (stravaGear as String?),
      orderIndex: orderIndex is _Sentinel ? this.orderIndex : (orderIndex as int),
      initialStats: initialStats is _Sentinel ? this.initialStats : (initialStats as ComponentStats),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
