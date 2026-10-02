import 'component.dart';

const Map<ComponentType, Set<ComponentType>> kSuggestedParentTypes = {
  // Frame
  ComponentType.frame: {},

  // Suspension
  ComponentType.fork: {ComponentType.frame},
  ComponentType.shock: {ComponentType.frame},

  // Cockpit
  ComponentType.cockpit: {ComponentType.stem, ComponentType.frame},
  ComponentType.stem: {ComponentType.fork, ComponentType.frame},
  ComponentType.grip: {ComponentType.cockpit, ComponentType.frame},
  ComponentType.headset: {ComponentType.frame},

  // Drivetrain
  ComponentType.shifter: {ComponentType.cockpit, ComponentType.frame},
  ComponentType.bottomBracket: {ComponentType.frame},
  ComponentType.crank: {
    ComponentType.bottomBracket,
    ComponentType.motor,
    ComponentType.frame,
  },
  ComponentType.derailleur: {ComponentType.frame},
  ComponentType.chainring: {ComponentType.crank, ComponentType.motor},
  ComponentType.casette: {ComponentType.wheelRear},
  ComponentType.chain: {},
  ComponentType.pedal: {ComponentType.crank, ComponentType.frame},
  ComponentType.shiftInnerCable: {
    ComponentType.shifter,
    ComponentType.derailleur,
    ComponentType.frame,
  },

  // Brakes
  ComponentType.brakeCalliper: {ComponentType.frame, ComponentType.fork},
  ComponentType.brakeLever: {ComponentType.cockpit, ComponentType.frame},
  ComponentType.brakePad: {ComponentType.brakeCalliper},
  ComponentType.brakeDisc: {
    ComponentType.wheelFront,
    ComponentType.wheelRear,
    ComponentType.frame,
  },

  // Wheels
  ComponentType.wheelFront: {ComponentType.frame},
  ComponentType.wheelRear: {ComponentType.frame},
  ComponentType.tire: {ComponentType.wheelFront, ComponentType.wheelRear},

  // Seating
  ComponentType.saddle: {ComponentType.seatpost, ComponentType.frame},
  ComponentType.seatpost: {ComponentType.frame},

  // Electronics
  ComponentType.battery: {ComponentType.frame, ComponentType.motor},
  ComponentType.motor: {ComponentType.frame},

  // Others
  ComponentType.bearing: {
    ComponentType.frame,
    ComponentType.fork,
    ComponentType.shock,
    ComponentType.headset,
    ComponentType.bottomBracket,
    ComponentType.wheelFront,
    ComponentType.wheelRear,
    ComponentType.crank,
    ComponentType.pedal,
    ComponentType.derailleur,
    ComponentType.motor,
  },
};

bool isSuggestedParent(ComponentType? child, ComponentType parent) {
  if (child == null) return true;
  final allowed = kSuggestedParentTypes[child];
  if (allowed == null) return true;
  return allowed.contains(parent);
}
