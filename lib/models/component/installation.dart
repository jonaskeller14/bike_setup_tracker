import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum InstallationParentType { bike, component, none, archived }

@immutable
sealed class Installation {
  final String id;
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;

  Installation._({
    String? id,
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
  })  : id = id ?? const Uuid().v4(),
        dateTimeUTC = truncateToMinute(dateTimeUTC.toUtc()),
        dateTimeLocal = truncateToMinute(dateTimeLocal);

  /// Drops seconds and below, preserving the `isUtc` flag.
  static DateTime truncateToMinute(DateTime value) =>
      value.copyWith(second: 0, millisecond: 0, microsecond: 0);

  String? get parent => switch (this) {
        BikeInstallation(:final bikeId) => bikeId,
        ComponentInstallation(:final parentComponentId) => parentComponentId,
        _ => null,
      };

  InstallationParentType get parentType => switch (this) {
        BikeInstallation _ => InstallationParentType.bike,
        ComponentInstallation _ => InstallationParentType.component,
        Uninstallation _ => InstallationParentType.none,
        Archival _ => InstallationParentType.archived,
      };

  bool get isFromBeginning => dateTimeUTC.millisecondsSinceEpoch == 0;

  factory Installation({
    String? parent,
    String? id,
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
  }) {
    return parent == null
        ? Uninstallation(
            id: id,
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          )
        : BikeInstallation(
            bikeId: parent,
            id: id,
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          );
  }

  factory Installation.componentSinceBeginning({required String parentComponentId}) {
    return ComponentInstallation(
      parentComponentId: parentComponentId,
      dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
    );
  }

  factory Installation.sinceBeginning({
    String? parent,
    String? id,
  }) {
    return Installation(
      parent: parent,
      id: id,
      dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
    );
  }

  /// A new event (fresh id) on the same parent as this one.
  Installation samePlacementAt({
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
  }) =>
      switch (this) {
        BikeInstallation(:final bikeId) => BikeInstallation(
            bikeId: bikeId,
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          ),
        ComponentInstallation(:final parentComponentId) => ComponentInstallation(
            parentComponentId: parentComponentId,
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          ),
        Uninstallation _ => Uninstallation(
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          ),
        Archival _ => Archival(
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          ),
      };

  Installation copyWith({
    Object? id = const _Sentinel(),
    Object? dateTimeUTC = const _Sentinel(),
    Object? dateTimeLocal = const _Sentinel(),
  }) {
    final newId = id is _Sentinel ? this.id : id as String?;
    final newDateUtc = dateTimeUTC is _Sentinel
        ? this.dateTimeUTC
        : dateTimeUTC as DateTime;
    final newDateLocal = dateTimeLocal is _Sentinel
        ? this.dateTimeLocal
        : dateTimeLocal as DateTime;

    return switch (this) {
      BikeInstallation(:final bikeId) => BikeInstallation(
          bikeId: bikeId,
          id: newId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
      ComponentInstallation(:final parentComponentId) => ComponentInstallation(
          parentComponentId: parentComponentId,
          id: newId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
      Uninstallation _ => Uninstallation(
          id: newId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
      Archival _ => Archival(
          id: newId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
    };
  }

  Map<String, dynamic> toJson() => {
        'type': parentType.name,
        'id': id,
        'parent': parent,
        'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
        'dateTimeLocal': dateTimeLocal.toIso8601String(),
      };

  /// Accepts both the new shape (with `type`) and the legacy shape (only
  /// `parent`). A `componentId` key written by older versions is ignored: the
  /// owning component is implied by nesting.
  factory Installation.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final dateTimeUTC = DateTime.parse(json['dateTimeUTC'] as String).toUtc();
    final dateTimeLocal = DateTime.parse(json['dateTimeLocal'] as String).copyWith(isUtc: false);
    final typeName = json['type'] as String?;

    if (typeName == null) {
      // Legacy shape: only `parent` (bike id) or null (uninstalled).
      return Installation(
        parent: json['parent'] as String?,
        id: id,
        dateTimeUTC: dateTimeUTC,
        dateTimeLocal: dateTimeLocal,
      );
    }

    final type = InstallationParentType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => InstallationParentType.none,
    );
    return switch (type) {
      InstallationParentType.bike => Installation(
          parent: json['parent'] as String?,
          id: id,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
        ),
      InstallationParentType.component => ComponentInstallation(
          parentComponentId: json['parent'] as String,
          id: id,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
        ),
      InstallationParentType.none => Uninstallation(
          id: id,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
        ),
      InstallationParentType.archived => Archival(
          id: id,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
        ),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Installation &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        parent == other.parent &&
        dateTimeUTC == other.dateTimeUTC &&
        dateTimeLocal == other.dateTimeLocal;
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, parent, dateTimeUTC, dateTimeLocal);
}

class BikeInstallation extends Installation {
  final String bikeId;

  BikeInstallation({
    required this.bikeId,
    super.id,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class ComponentInstallation extends Installation {
  final String parentComponentId;

  ComponentInstallation({
    required this.parentComponentId,
    super.id,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class Uninstallation extends Installation {
  Uninstallation({
    super.id,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class Archival extends Installation {
  Archival({
    super.id,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class _Sentinel {
  const _Sentinel();
}
