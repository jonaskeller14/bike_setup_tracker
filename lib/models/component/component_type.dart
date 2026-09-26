part of 'component.dart';

enum ComponentTypeCategory {
  frame('Frame'),
  suspension('Suspension'),
  cockpit('Cockpit'),
  drivetrain('Drivetrain'),
  brakes('Brakes'),
  wheels('Wheels'),
  seating('Seating'),
  electronics('Electronics'),
  others('Others');

  final String label;
  const ComponentTypeCategory(this.label);
}

enum ComponentType {
  frame('Frame', ComponentTypeCategory.frame),

  fork('Fork', ComponentTypeCategory.suspension),
  shock('Shock', ComponentTypeCategory.suspension),

  cockpit('Handlebar', ComponentTypeCategory.cockpit),
  stem('Stem', ComponentTypeCategory.cockpit),
  grip('Grip', ComponentTypeCategory.cockpit, maxCount: 2),
  headset('Headset', ComponentTypeCategory.cockpit),

  shifter('Shifter', ComponentTypeCategory.drivetrain, maxCount: 2),
  bottomBracket('Bottom Bracket', ComponentTypeCategory.drivetrain),
  crank('Crank', ComponentTypeCategory.drivetrain),
  derailleur('Derailleur', ComponentTypeCategory.drivetrain, maxCount: 2),
  chainring('Chainring', ComponentTypeCategory.drivetrain),
  casette('Cassette', ComponentTypeCategory.drivetrain),
  chain('Chain', ComponentTypeCategory.drivetrain),
  pedal('Pedal', ComponentTypeCategory.drivetrain, maxCount: 2),
  shiftInnerCable('Shift Inner Cable', ComponentTypeCategory.drivetrain, maxCount: 2),

  brakeCalliper('Brake Calliper', ComponentTypeCategory.brakes, maxCount: 2),
  brakeLever('Brake Lever', ComponentTypeCategory.brakes, maxCount: 2),
  brakePad('Brake Pad', ComponentTypeCategory.brakes, maxCount: 2),
  brakeDisc('Brake Disc', ComponentTypeCategory.brakes, maxCount: 2),

  wheelFront('Front Wheel', ComponentTypeCategory.wheels),
  wheelRear('Rear Wheel', ComponentTypeCategory.wheels),
  tire('Tire', ComponentTypeCategory.wheels, maxCount: 2),

  saddle('Saddle', ComponentTypeCategory.seating),
  seatpost('Seatpost', ComponentTypeCategory.seating),

  battery('Battery', ComponentTypeCategory.electronics, maxCount: 2),
  motor('Motor', ComponentTypeCategory.electronics),

  bearing('Bearing', ComponentTypeCategory.others),
  equipment('Equipment', ComponentTypeCategory.others),
  other('Other', ComponentTypeCategory.others);

  final String label;
  final ComponentTypeCategory category;
  final int maxCount;
  const ComponentType(this.label, this.category, {this.maxCount = 1});

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
