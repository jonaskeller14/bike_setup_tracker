import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Bike {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final String? notes;
  final String? person;

  static const IconData iconData = Icons.pedal_bike;

  Bike({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required this.person,
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'version': 2,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
    'notes': notes,
    'person': person,
  };

  factory Bike.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2:
        return Bike(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          notes: json['notes'], // = null
          person: json['person'], // = null
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
        person == other.person;
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
    );
  }
}
