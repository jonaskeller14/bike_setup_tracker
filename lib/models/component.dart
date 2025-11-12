import 'adjustment.dart';

class Component {
  final String name;
  final List<Adjustment> adjustments;

  Component({
    required this.name,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [];
  
  Map<String, dynamic> toJson() => {'name': name, 'adjustments': adjustments.map((a) => a.toJson()).toList()};

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(name: json['name']);
  }
}