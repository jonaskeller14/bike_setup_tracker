import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../icons/bike_icons.dart';
import 'adjustment/adjustment.dart';
import 'component_stats.dart';
import 'installation.dart';

part 'component_type.dart';

class Component {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final ComponentType componentType; 
  final List<Adjustment> adjustments;
  final List<Installation> installations;
  final String? notes;
  final int orderIndex;

  final ComponentStats initialStats;
  final ComponentStats totalStats;

  String? get bike => bikeAt(DateTime.now().toUtc());

  String? bikeAt(DateTime timeUTC) {
    if (installations.isEmpty) return null;
    
    // Sort installations by dateTimeUTC to ensure chronological order
    final sorted = List<Installation>.from(installations)
      ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
      
    // Find the last installation that happened at or before the given time
    Installation? result;
    for (final installation in sorted) {
      if (installation.dateTimeUTC.isAfter(timeUTC)) break;
      result = installation;
    }
    
    return result?.parent;
  }

  Installation? get latestInstallation {
    if (installations.isEmpty) return null;
    return installations.reduce(
      (a, b) => a.dateTimeUTC.isAfter(b.dateTimeUTC) ? a : b,
    );
  }

  bool get isArchived => latestInstallation is Archival;
  bool get isUninstalled => latestInstallation is Uninstallation;

  static const IconData iconData = Icons.grid_view_sharp;

  Component({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    required this.installations,
    required this.componentType,
    this.notes,
    this.orderIndex = 0,
    List<Adjustment>? adjustments,
    ComponentStats? initialStats,
    ComponentStats? totalStats,
  }) : adjustments = adjustments ?? [],
       initialStats = initialStats ?? ComponentStats.zero(),
       totalStats = totalStats ?? ComponentStats.zero(),
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();
    
  Component deepCopy() {
    return Component(
      name: name,
      installations: installations.map((i) => i.copyWith()).toList(),
      componentType: componentType,
      notes: notes,
      orderIndex: orderIndex,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
      initialStats: initialStats,
      totalStats: totalStats,
    );
  }

  Component copyWithNewInstallation(String? newBike) {
    return copyWith(
      installations: [
        Installation.sinceBeginning(parent: newBike, componentId: id)
      ],
    );
  }

  Component copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted= const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? componentType = const _Sentinel(),
    Object? adjustments = const _Sentinel(),
    Object? installations = const _Sentinel(),
    Object? orderIndex = const _Sentinel(),
    Object? initialStats = const _Sentinel(),
    Object? totalStats = const _Sentinel(),
  }) {
    return Component(
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
      componentType: componentType is _Sentinel
          ? this.componentType
          : (componentType as ComponentType),
      adjustments: adjustments is _Sentinel
          ? this.adjustments
          : (adjustments as List<Adjustment>),
      installations: installations is _Sentinel
          ? this.installations
          : (installations as List<Installation>),  
      orderIndex: orderIndex is _Sentinel
          ? this.orderIndex
          : (orderIndex as int),
      initialStats: initialStats is _Sentinel
          ? this.initialStats
          : (initialStats as ComponentStats),
      totalStats: totalStats is _Sentinel
          ? this.totalStats
          : (totalStats as ComponentStats),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 5,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'componentType': componentType.toString(),
    'installations': installations.map((i) => i.toJson()).toList(),
    'notes': notes,
    'orderIndex': orderIndex,
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
    'initialStats': initialStats.toJson(),
  };

  /// Reads the initial stats of any component version: nested since version 5,
  /// flat `initial*` keys (without kilojoules) before that.
  static ComponentStats _initialStatsFromJson(Map<String, dynamic> json) {
    final nested = json['initialStats'] as Map<String, dynamic>?;
    if (nested != null) return ComponentStats.fromJson(nested);
    return ComponentStats(
      distance: (json['initialDistance'] as num?)?.toDouble() ?? 0.0,
      elevationGain: (json['initialElevationGain'] as num?)?.toDouble() ?? 0.0,
      movingTime: Duration(seconds: json['initialMovingTime'] as int? ?? 0),
      elapsedTime: Duration(seconds: json['initialElapsedTime'] as int? ?? 0),
      activityCount: json['initialActivityCount'] as int? ?? 0,
    );
  }

  factory Component.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1:
        final bike = json["bike"] as String?;
        return Component(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          componentType: ComponentType.fromString(json['componentType'] as String?),
          installations: [
            Installation.sinceBeginning(parent: bike, componentId: json["id"] as String)
          ],
          notes: json["notes"] as String?,
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson as Map<String, dynamic>))
            .toList()
            ?? <Adjustment>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
          initialStats: _initialStatsFromJson(json),
        );
      case 2 || 3 || 4 || 5:
        return Component(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.tryParse(json["lastModified"] as String? ?? ""),
          name: json['name'] as String,
          componentType: ComponentType.fromString(json['componentType'] as String?),
          installations: (json["installations"] as List<dynamic>?)
            ?.map((i) => Installation.fromJson(i as Map<String, dynamic>, componentId: json["id"] as String))
            .toList() ?? [],
          notes: json["notes"] as String?,
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson as Map<String, dynamic>))
            .toList()
            ?? <Adjustment>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
          initialStats: _initialStatsFromJson(json),
        );
      default: throw Exception("Json Version $version of Component incompatible.");
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Component &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        componentType == other.componentType &&
        listEquals(installations, other.installations) &&
        notes == other.notes &&
        listEquals(adjustments, other.adjustments) &&
        initialStats == other.initialStats &&
        totalStats == other.totalStats;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isDeleted,
      lastModified,
      name,
      componentType,
      Object.hashAll(installations),
      notes,
      Object.hashAll(adjustments),
      initialStats,
      totalStats,
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
