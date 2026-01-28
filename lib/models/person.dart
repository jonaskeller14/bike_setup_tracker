import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';

class Person {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final List<Adjustment> adjustments;

  static const IconData iconData = Icons.person;

  Person({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now();

  Person deepCopy() {
    return Person(
      name: name,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
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
          adjustments: (json["adjustments"] as List<dynamic>?)?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson)).toList() ?? <Adjustment>[],
        );
      default: throw Exception("Json Version $version of Person incompatible.");
    }
  }
}
