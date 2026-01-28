import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';

enum FilterType {
  person,
  bike,
  component,
  componentType,
  global, // always apply rating
}

class Rating {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final String? filter; // id of filter object (Bike, Component, Person)
  final FilterType filterType;
  final List<Adjustment> adjustments;

  static const IconData iconData = Icons.star;

  Rating({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    required this.filter,
    required this.filterType,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now(),
       assert ((filter == null && filterType == FilterType.global) || (filter != null && filterType != FilterType.global));
  
  Rating deepCopy() {
    return Rating(
      name: name,
      filter: filter,
      filterType: filterType,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
    "filter": filter,
    "filterType": filterType.toString(),
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
  };

  factory Rating.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return Rating(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          filter: json["filter"],
          filterType: FilterType.values.firstWhere(
            (e) => e.toString() == json["filterType"],
            orElse: () => FilterType.global,
          ),
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson))
            .toList()
            ?? <Adjustment>[],
        );
      default: throw Exception("Json Version $version of Rating incompatible.");
    }
  }
}
