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

  factory Data.fromJson({required Map<String, dynamic> json}) {
    final loadedBikes = (json['bikes'] as List<dynamic>? ?? [])
        .map((a) => Bike.fromJson(a))
        .toList();

    final loadedComponents = (json['components'] as List<dynamic>? ?? [])
        .map((c) => Component.fromJson(json: c))
        .toList();
    
    final loadedSetups = (json['setups'] as List<dynamic>? ?? [])
        .map((s) => Setup.fromJson(json: s))
        .toList();
    
    return Data(
      bikes: <String, Bike>{for (var item in loadedBikes) item.id: item},
      setups: loadedSetups,
      components: loadedComponents,
    );
  }
}
