abstract interface class Syncable {
  String get id;
  DateTime get lastModified;
  bool get isDeleted;
  Map<String, dynamic> toJson();
}
