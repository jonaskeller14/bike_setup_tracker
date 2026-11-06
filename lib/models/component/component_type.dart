part of 'component.dart';

enum ComponentTypeCategory {
  frame,
  suspension,
  cockpit,
  drivetrain,
  brakes,
  wheels,
  seating,
  electronics,
  others;
}

enum ComponentType {
  frame(ComponentTypeCategory.frame),

  fork(ComponentTypeCategory.suspension),
  shock(ComponentTypeCategory.suspension),

  cockpit(ComponentTypeCategory.cockpit),
  stem(ComponentTypeCategory.cockpit),
  grip(ComponentTypeCategory.cockpit, maxCount: 2),
  headset(ComponentTypeCategory.cockpit),

  shifter(ComponentTypeCategory.drivetrain, maxCount: 2),
  bottomBracket(ComponentTypeCategory.drivetrain),
  crank(ComponentTypeCategory.drivetrain),
  derailleur(ComponentTypeCategory.drivetrain, maxCount: 2),
  chainring(ComponentTypeCategory.drivetrain),
  casette(ComponentTypeCategory.drivetrain),
  chain(ComponentTypeCategory.drivetrain),
  pedal(ComponentTypeCategory.drivetrain, maxCount: 2),
  shiftInnerCable(ComponentTypeCategory.drivetrain, maxCount: 2),

  brakeCalliper(ComponentTypeCategory.brakes, maxCount: 2),
  brakeLever(ComponentTypeCategory.brakes, maxCount: 2),
  brakePad(ComponentTypeCategory.brakes, maxCount: 2),
  brakeDisc(ComponentTypeCategory.brakes, maxCount: 2),

  wheelFront(ComponentTypeCategory.wheels),
  wheelRear(ComponentTypeCategory.wheels),
  tire(ComponentTypeCategory.wheels, maxCount: 2),

  saddle(ComponentTypeCategory.seating),
  seatpost(ComponentTypeCategory.seating),

  battery(ComponentTypeCategory.electronics, maxCount: 2),
  motor(ComponentTypeCategory.electronics),

  bearing(ComponentTypeCategory.others),
  equipment(ComponentTypeCategory.others),
  other(ComponentTypeCategory.others);

  final ComponentTypeCategory category;
  final int maxCount;
  const ComponentType(this.category, {this.maxCount = 1});

  IconData getIconData() {
    switch (this) {
      case frame: return BikeIcons.frame;
      case fork: return BikeIcons.fork;
      case shock: return BikeIcons.shock;
      case wheelFront: return BikeIcons.wheelFront;
      case wheelRear: return BikeIcons.wheelRear;
      case cockpit: return BikeIcons.cockpit;
      case stem: return BikeIcons.stem;
      case grip: return BikeIcons.grip;
      case headset: return BikeIcons.headset;
      case shifter: return BikeIcons.shifter;
      case bottomBracket: return BikeIcons.bottomBracket;
      case crank: return BikeIcons.crank;
      case derailleur: return BikeIcons.derailleur;
      case chainring: return BikeIcons.chainring;
      case casette: return BikeIcons.casette;
      case chain: return BikeIcons.chain;
      case pedal: return BikeIcons.pedal;
      case shiftInnerCable: return BikeIcons.shiftInnerCable;
      case brakeCalliper: return BikeIcons.brakeCalliper;
      case brakeLever: return BikeIcons.brakeLever;
      case brakePad: return BikeIcons.brakePad;
      case brakeDisc: return BikeIcons.brakeDisc;
      case tire: return BikeIcons.tire;
      case saddle: return BikeIcons.saddle;
      case seatpost: return BikeIcons.seatpost;
      case battery: return BikeIcons.battery;
      case motor: return BikeIcons.motor;
      case bearing: return BikeIcons.bearing;
      case equipment: return BikeIcons.equipment;
      case other: return BikeIcons.other;
    }
  }

  factory ComponentType.fromString(String? value) {
    return ComponentType.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => ComponentType.other,
    );
  }
}
