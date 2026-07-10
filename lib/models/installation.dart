import 'package:uuid/uuid.dart';

enum InstallationParentType { bike, none, archived }

sealed class Installation {
  final String id;
  final String componentId; // Normalised at persist time
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;

  Installation._({
    String? id,
    String? componentId,
    required DateTime dateTimeUTC,
    required this.dateTimeLocal,
  })  : id = id ?? const Uuid().v4(),
        componentId = componentId ?? '',
        dateTimeUTC = dateTimeUTC.toUtc();

  String? get parent => switch (this) {
        BikeInstallation(:final bikeId) => bikeId,
        _ => null,
      };

  InstallationParentType get parentType => switch (this) {
        BikeInstallation _ => InstallationParentType.bike,
        Uninstallation _ => InstallationParentType.none,
        Archival _ => InstallationParentType.archived,
      };

  bool get isFromBeginning => dateTimeUTC.millisecondsSinceEpoch == 0;

  factory Installation({
    String? parent,
    String? id,
    String? componentId,
    required DateTime dateTimeUTC,
    required DateTime dateTimeLocal,
  }) {
    return parent == null
        ? Uninstallation(
            id: id,
            componentId: componentId,
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          )
        : BikeInstallation(
            bikeId: parent,
            id: id,
            componentId: componentId,
            dateTimeUTC: dateTimeUTC,
            dateTimeLocal: dateTimeLocal,
          );
  }

  factory Installation.sinceBeginning({
    String? parent,
    String? id,
    String? componentId,
  }) {
    return Installation(
      parent: parent,
      id: id,
      componentId: componentId,
      dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
    );
  }

  /// When [parent] is provided the event is *retargeted* (subtype chosen by
  /// null-ness — this intentionally drops [Archival], since giving it a target
  /// means it is installed/uninstalled again). Otherwise the subtype is
  /// preserved and only id/componentId/dates change.
  Installation copyWith({
    Object? parent = const _Sentinel(),
    Object? id = const _Sentinel(),
    Object? componentId = const _Sentinel(),
    Object? dateTimeUTC = const _Sentinel(),
    Object? dateTimeLocal = const _Sentinel(),
  }) {
    final newId = id is _Sentinel ? this.id : id as String?;
    final newComponentId = componentId is _Sentinel
        ? this.componentId
        : componentId as String?;
    final newDateUtc = dateTimeUTC is _Sentinel
        ? this.dateTimeUTC
        : dateTimeUTC as DateTime;
    final newDateLocal = dateTimeLocal is _Sentinel
        ? this.dateTimeLocal
        : dateTimeLocal as DateTime;

    if (parent is! _Sentinel) {
      return Installation(
        parent: parent as String?,
        id: newId,
        componentId: newComponentId,
        dateTimeUTC: newDateUtc,
        dateTimeLocal: newDateLocal,
      );
    }

    return switch (this) {
      BikeInstallation(:final bikeId) => BikeInstallation(
          bikeId: bikeId,
          id: newId,
          componentId: newComponentId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
      Uninstallation _ => Uninstallation(
          id: newId,
          componentId: newComponentId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
      Archival _ => Archival(
          id: newId,
          componentId: newComponentId,
          dateTimeUTC: newDateUtc,
          dateTimeLocal: newDateLocal,
        ),
    };
  }

  Map<String, dynamic> toJson() => {
        'type': parentType.name,
        'id': id,
        'componentId': componentId,
        'parent': parent,
        'dateTimeUTC': dateTimeUTC.toUtc().toIso8601String(),
        'dateTimeLocal': dateTimeLocal.toIso8601String(),
      };

  /// Accepts both the new shape (with `type`) and the legacy shape (only
  /// `parent`). [componentId] is used as a fallback for legacy payloads that
  /// don't carry it.
  factory Installation.fromJson(
    Map<String, dynamic> json, {
    String? componentId,
  }) {
    final id = json['id'] as String?;
    final cid = json['componentId'] as String? ?? componentId;
    final dateTimeUTC = DateTime.parse(json['dateTimeUTC'] as String).toUtc();
    final dateTimeLocal = DateTime.parse(json['dateTimeLocal'] as String).copyWith(isUtc: false);
    final typeName = json['type'] as String?;

    if (typeName == null) {
      // Legacy shape: only `parent` (bike id) or null (uninstalled).
      return Installation(
        parent: json['parent'] as String?,
        id: id,
        componentId: cid,
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
          componentId: cid,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
        ),
      InstallationParentType.none => Uninstallation(
          id: id,
          componentId: cid,
          dateTimeUTC: dateTimeUTC,
          dateTimeLocal: dateTimeLocal,
        ),
      InstallationParentType.archived => Archival(
          id: id,
          componentId: cid,
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
        componentId == other.componentId &&
        parent == other.parent &&
        dateTimeUTC == other.dateTimeUTC &&
        dateTimeLocal == other.dateTimeLocal;
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, componentId, parent, dateTimeUTC, dateTimeLocal);
}

class BikeInstallation extends Installation {
  final String bikeId;

  BikeInstallation({
    required this.bikeId,
    super.id,
    super.componentId,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class Uninstallation extends Installation {
  Uninstallation({
    super.id,
    super.componentId,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class Archival extends Installation {
  Archival({
    super.id,
    super.componentId,
    required super.dateTimeUTC,
    required super.dateTimeLocal,
  }) : super._();
}

class _Sentinel {
  const _Sentinel();
}
