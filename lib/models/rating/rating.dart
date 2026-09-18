import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../adjustment/adjustment.dart';
import 'rating_association.dart';
import 'rating_metric.dart';

class Rating {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final String? notes;
  final RatingAssociation association;
  final int orderIndex;
  final List<RatingMetric> metrics;

  static const IconData iconData = Icons.star;

  Rating({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    this.notes,
    required this.association,
    this.orderIndex = 0,
    List<RatingMetric>? metrics,
  }) : metrics = metrics ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now().toUtc();

  Rating deepCopy() {
    return Rating(
      name: name,
      notes: notes,
      association: association,
      metrics: metrics.map((m) => m.deepCopy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 4,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'notes': notes,
    'association': association.toJson(),
    'orderIndex': orderIndex,
    'metrics': metrics.map((m) => m.toJson()).toList(),
  };

  factory Rating.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1 || 2:
        // Legacy: a flat list of adjustments without weights -> default metrics.
        return Rating(
          id: json["id"] as String?,
          isDeleted: json["isDeleted"] as bool?,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          notes: json['notes'] as String?,
          association: RatingAssociation.fromLegacyJson(json),
          metrics: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => RatingMetric(
                  adjustment: Adjustment.fromJson(adjustmentJson as Map<String, dynamic>),
                ))
            .toList()
            ?? <RatingMetric>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
        );
      case 3:
        return Rating(
          id: json["id"] as String?,
          isDeleted: json["isDeleted"] as bool?,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          notes: json['notes'] as String?,
          association: RatingAssociation.fromLegacyJson(json),
          metrics: (json["metrics"] as List<dynamic>?)
            ?.map((metricJson) => RatingMetric.fromJson(metricJson as Map<String, dynamic>))
            .toList()
            ?? <RatingMetric>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
        );
      case 4:
        return Rating(
          id: json["id"] as String?,
          isDeleted: json["isDeleted"] as bool?,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          notes: json['notes'] as String?,
          association: RatingAssociation.fromJson(json['association'] as Map<String, dynamic>),
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
        association == other.association &&
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
      association,
      Object.hashAll(metrics),
    );
  }

  Rating copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted = const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? association = const _Sentinel(),
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
      association: association is _Sentinel
          ? this.association
          : (association as RatingAssociation),
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
