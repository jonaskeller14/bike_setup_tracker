import '../models/bike.dart';
import '../models/adjustment.dart';
import '../models/setting.dart';
import '../models/component.dart';

class Data {
  final List<Bike> bikes;
  final List<Adjustment> adjustments;
  final List<Setting> settings;
  final List<Component> components;

  Data({
    required this.bikes,
    required this.adjustments,
    required this.settings,
    required this.components,
  });
}
