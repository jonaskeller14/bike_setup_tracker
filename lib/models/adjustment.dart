abstract class Adjustment<T> {
  final String name;
  final Type valueType;
  
  Adjustment({required this.name}) : valueType = T;

  bool isValidValue(T value);
  Map<String, dynamic> toJson();
  
  static Adjustment fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'boolean':
        return BooleanAdjustment(name: json['name']);
      // case 'categorical':
      //   return CategoricalAdjustment(
      //     name: json['name'],
      //     options: List<String>.from(json['options']),
      //   );
      // case 'step':
      //   return StepAdjustment(
      //     name: json['name'],
      //     step: json['step'],
      //     min: json['min'],
      //     max: json['max'],
      //   );
      // case 'numerical':
      //   return NumericalAdjustment(
      //     name: json['name'],
      //     min: json['min'],
      //     max: json['max'],
      //   );
      default:
        throw Exception('Unknown adjustment type: $type');
    }
  }
}

// class CategoricalAdjustment extends Adjustment<String> {
//   final List<String> options;

//   CategoricalAdjustment({
//     required super.name,
//     required this.options,
//   });

//   @override
//   bool isValidValue(String value){
//     return options.contains(value);
//   }
// }

// class StepAdjustment extends Adjustment<int> {
//   final int step;
//   final int min;
//   final int max;

//   StepAdjustment({
//     required super.name,
//     required this.step,
//     required this.min,
//     required this.max,
//   });

//   @override
//   bool isValidValue(int value){
//     return value >= min && value <= max && ((value - min) % step == 0);
//   }
// }

// class NumericalAdjustment extends Adjustment<double> {
//   final double min;
//   final double max;

//   NumericalAdjustment({
//     required super.name,
//     required this.min,
//     required this.max,
//   });

//   @override
//   bool isValidValue(double value){
//     return value >= min && value <= max;
//   }
// }
class BooleanAdjustment extends Adjustment<bool> {
  BooleanAdjustment({
    required super.name,
  });
  
  @override
  bool isValidValue(bool value){
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': 'boolean',
    'valueType': valueType.toString(),
  };
}
