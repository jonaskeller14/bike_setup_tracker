import 'dart:convert';

abstract interface class Syncable {
  String get id;
  DateTime get lastModified;
  bool get isDeleted;
  Map<String, dynamic> toJson();
}

extension SyncableContent on Syncable {
  /// Equal apart from [Syncable.lastModified].
  bool hasSameContent(Syncable other) =>
      jsonEncode(toJson()..remove('lastModified')) == jsonEncode(other.toJson()..remove('lastModified'));
}
