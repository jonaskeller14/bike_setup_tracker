import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Bike {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final String? person;
  final String? stravaGear;
  final int orderIndex;

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
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'version': 4,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'person': person,
    'stravaGear': stravaGear,
    'orderIndex': orderIndex,
  };

  factory Bike.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1 || 2 || 3 || 4:
        return Bike(
          id: json["id"] as String?,
          isDeleted: json["isDeleted"] as bool?,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          notes: json['notes'] as String?, // = null
          person: json['person'] as String?, // = null
          stravaGear: json['stravaGear'] as String?, // = null
          orderIndex: json['orderIndex'] as int? ?? 0,
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
        stravaGear == other.stravaGear;
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
    );
  }

  Bike deepCopy() {
    return Bike(
      name: name,
      notes: notes,
      person: person,
      stravaGear: stravaGear,
      orderIndex: orderIndex,
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
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
