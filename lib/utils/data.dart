import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';

class Data {
  final Map<String, Bike> bikes;
  final List<Setup> setups;
  final List<Component> components;

  Data({
    required this.bikes,
    required this.setups,
    required this.components,
  });

  Map<String, dynamic> toJson() => {
    'bikes': bikes.values.map((b) => b.toJson()).toList(),
    'setups': setups.map((s) => s.toJson()).toList(),
    'components': components.map((c) => c.toJson()).toList(),
  };
}
