part of 'component.dart';

enum ComponentType {
  frame('Frame'),
  fork('Fork'),
  shock('Shock'),
  wheelFront('Front Wheel'),
  wheelRear('Rear Wheel'),
  cockpit('Cockpit'),
  saddle('Saddle'),
  seatpost('Seatpost'),
  pedal('Pedal'),
  motor('Motor'),
  equipment('Equipment'),
  other('Other');

  final String value;
  const ComponentType(this.value);
  IconData getIconData() {
    switch (this) {
      case frame: return BikeIcons.frame;
      case fork: return BikeIcons.fork;
      case shock: return BikeIcons.shock;
      case wheelFront: return BikeIcons.wheelFront;
      case wheelRear: return BikeIcons.wheelRear;
      case cockpit: return BikeIcons.cockpit;
      case saddle: return BikeIcons.saddle;
      case seatpost: return BikeIcons.seatpost;
      case pedal: return BikeIcons.pedal;
      case motor: return BikeIcons.motor;
      case equipment: return BikeIcons.equipment;
      case other: return BikeIcons.other;
    }
  }
}
