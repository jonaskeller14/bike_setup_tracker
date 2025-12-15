import 'package:uuid/uuid.dart';

class Bike {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  String name;
  String? person;

  Bike({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    required this.person,
  })
    : id = id ?? const Uuid().v4(),
      isDeleted = isDeleted ?? false,
      lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
    'person': person,
  };

  factory Bike.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return Bike(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          person: json['person'], // = null
        );
      case 1:
        return Bike(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          person: json['person'],
        );
      default: throw Exception("Json Version $version of Bike incompatible.");
    }
  }
}
