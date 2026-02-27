import 'package:flutter/foundation.dart';
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
  final String? notes;
  final String? filter; // id of filter object (Bike, Component, Person)
  final FilterType filterType;
  final List<Adjustment> adjustments;

  static const IconData iconData = Icons.star;

  Rating({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required this.filter,
    required this.filterType,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now().toUtc(),
       assert ((filter == null && filterType == FilterType.global) || (filter != null && filterType != FilterType.global));
  
  Rating deepCopy() {
    return Rating(
      name: name,
      notes: notes,
      filter: filter,
      filterType: filterType,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    "filter": filter,
    "filterType": filterType.toString(),
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
  };

  factory Rating.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return Rating(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          notes: json['notes'],
          filter: json["filter"],
          filterType: FilterType.values.firstWhere(
            (e) => e.toString() == json["filterType"],
            orElse: () => FilterType.global,
          ),
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson, defaultCategory: AdjustmentCategory.rating))
            .toList()
            ?? <Adjustment>[],
        );
      default: throw Exception("Json Version $version of Rating incompatible.");
    }
  }
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Rating &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        notes == other.notes &&
        filter == other.filter &&
        filterType == other.filterType &&
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
      filter,
      filterType,
      Object.hashAll(adjustments),
    );
  }

  Rating copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? filter = const _Sentinel(),
    Object? filterType = const _Sentinel(),
    Object? adjustments = const _Sentinel(),
  }) {
    return Rating(
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
      filter: filter is _Sentinel 
          ? this.filter 
          : (filter as String?),
      filterType: filterType is _Sentinel 
          ? this.filterType 
          : (filterType as FilterType),
      adjustments: adjustments is _Sentinel 
          ? this.adjustments 
          : (adjustments as List<Adjustment>),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
