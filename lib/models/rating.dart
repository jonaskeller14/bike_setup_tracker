import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';
import 'rating_metric.dart';

enum FilterType {
  person,
  bike,
  component,
  componentType,
  global, // always apply rating
}

class Rating {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final String? filter; // id of filter object (Bike, Component, Person)
  final FilterType filterType;
  final int orderIndex;
  final List<RatingMetric> metrics;

  static const IconData iconData = Icons.star;

  Rating({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required this.filter,
    required this.filterType,
    this.orderIndex = 0,
    List<RatingMetric>? metrics,
  }) : metrics = metrics ?? [],
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
      metrics: metrics.map((m) => m.deepCopy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 3,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    "filter": filter,
    "filterType": filterType.toString(),
    'orderIndex': orderIndex,
    'metrics': metrics.map((m) => m.toJson()).toList(),
  };

  factory Rating.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2:
        // Legacy: a flat list of adjustments without weights -> default metrics.
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
          metrics: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => RatingMetric(
                  adjustment: Adjustment.fromJson(adjustmentJson, defaultCategory: AdjustmentCategory.rating),
                ))
            .toList()
            ?? <RatingMetric>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
        );
      case 3:
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
          metrics: (json["metrics"] as List<dynamic>?)
            ?.map((metricJson) => RatingMetric.fromJson(metricJson as Map<String, dynamic>))
            .toList()
            ?? <RatingMetric>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
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
        listEquals(metrics, other.metrics);
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
      Object.hashAll(metrics),
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
    Object? orderIndex = const _Sentinel(),
    Object? metrics = const _Sentinel(),
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
      orderIndex: orderIndex is _Sentinel
          ? this.orderIndex
          : (orderIndex as int),
      metrics: metrics is _Sentinel
          ? this.metrics
          : (metrics as List<RatingMetric>),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
