import '../models/bike.dart';
import '../models/adjustment.dart';
import '../models/setup.dart';
import '../models/component.dart';

class Data {
  final List<Bike> bikes;
  final List<Adjustment> adjustments;
  final List<Setup> setups;
  final List<Component> components;

  Data({
    required this.bikes,
    required this.adjustments,
    required this.setups,
    required this.components,
  });
}
