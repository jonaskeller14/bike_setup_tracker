import 'package:uuid/uuid.dart';

class Bike {
  final String id;
  final String name;

  Bike({String? id, required this.name}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json["id"],
      name: json['name'],
    );
  }
}
