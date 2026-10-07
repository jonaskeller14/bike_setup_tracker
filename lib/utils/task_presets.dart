import '../models/component/component.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_template.dart';
import '../models/task/task_threshold/task_threshold.dart';

const _month = DurationThreshold(Duration(days: 30));
const _threeMonths = DurationThreshold(Duration(days: 90));
const _sixMonths = DurationThreshold(Duration(days: 180));
const _year = DurationThreshold(Duration(days: 365));

const _wheelTemplates = [
  TaskTemplate(
    key: 'wheel:spoke_tension',
    name: 'Spoke tension check',
    notes: 'Squeeze spoke pairs and check the rim for wobble; new wheels settle during the first rides.',
    interval: DistanceThreshold(1000000),
    fallbackInterval: _sixMonths,
    preselected: true,
  ),
  TaskTemplate(
    key: 'wheel:hub_bearing',
    name: 'Hub bearing check',
    notes: 'Check the hub for play and rough or notchy rotation.',
    interval: DistanceThreshold(3000000),
    fallbackInterval: _year,
  ),
];

/// Generic task templates per component type. Ride-based intervals are
/// stored metric; without Strava, [TaskTemplate.fallbackInterval] applies.
const Map<ComponentType, List<TaskTemplate>> taskPresets = {
  ComponentType.chain: [
    TaskTemplate(
      key: 'chain:wear_check',
      name: 'Check chain wear',
      notes: 'Measure chain stretch with a wear gauge and replace the chain once it reaches the wear limit.',
      interval: DistanceThreshold(500000),
      fallbackInterval: _month,
      preselected: true,
    ),
    TaskTemplate(
      key: 'chain:replace',
      name: 'Replace chain',
      interval: DistanceThreshold(2000000),
      priority: TaskPriority.high,
    ),
    TaskTemplate(
      key: 'chain:lube',
      name: 'Clean & lube chain',
      interval: ActivityCountThreshold(5),
      priority: TaskPriority.low,
    ),
  ],
  ComponentType.casette: [
    TaskTemplate(
      key: 'cassette:wear_check',
      name: 'Check cassette wear',
      notes: 'Look for hooked or shark-fin teeth and chain skipping under load.',
      interval: DistanceThreshold(6000000),
      fallbackInterval: _year,
    ),
  ],
  ComponentType.fork: [
    TaskTemplate(
      key: 'fork:lower_leg_service',
      name: 'Lower leg service',
      notes: 'Clean the stanchions and seals, replace the foam rings and refresh the bath oil.',
      interval: MovingTimeThreshold(Duration(hours: 50)),
      fallbackInterval: _sixMonths,
      preselected: true,
    ),
    TaskTemplate(
      key: 'fork:full_service',
      name: 'Damper & spring service',
      notes: 'Full service of the damper and air spring, including seals and oil.',
      interval: MovingTimeThreshold(Duration(hours: 200)),
      fallbackInterval: _year,
      preselected: true,
    ),
  ],
  ComponentType.shock: [
    TaskTemplate(
      key: 'shock:air_can_service',
      name: 'Air can service',
      notes: 'Clean and re-grease the air can and replace its seals.',
      interval: MovingTimeThreshold(Duration(hours: 50)),
      fallbackInterval: _sixMonths,
      preselected: true,
    ),
    TaskTemplate(
      key: 'shock:full_service',
      name: 'Damper service',
      notes: 'Full damper service, including seals, oil and nitrogen charge.',
      interval: MovingTimeThreshold(Duration(hours: 200)),
      fallbackInterval: _year,
      preselected: true,
    ),
  ],
  ComponentType.brakePad: [
    TaskTemplate(
      key: 'brake_pad:wear_check',
      name: 'Check pad wear',
      notes: 'Replace the pads before the friction material is worn down to the backing plate.',
      interval: DistanceThreshold(500000),
      fallbackInterval: _month,
      priority: TaskPriority.high,
      preselected: true,
    ),
  ],
  ComponentType.brakeCalliper: [
    TaskTemplate(
      key: 'brake:bleed',
      name: 'Bleed brakes',
      notes: 'Replace the brake fluid and remove air from the system.',
      interval: _year,
    ),
  ],
  ComponentType.tire: [
    TaskTemplate(
      key: 'tire:sealant',
      name: 'Refresh tubeless sealant',
      notes: 'Top up or replace the sealant before it dries out.',
      interval: _threeMonths,
      preselected: true,
    ),
  ],
  ComponentType.wheelFront: _wheelTemplates,
  ComponentType.wheelRear: _wheelTemplates,
  ComponentType.headset: [
    TaskTemplate(
      key: 'headset:service',
      name: 'Clean & grease headset',
      interval: MovingTimeThreshold(Duration(hours: 100)),
      fallbackInterval: _year,
    ),
  ],
  ComponentType.bottomBracket: [
    TaskTemplate(
      key: 'bb:play_check',
      name: 'Check bottom bracket play',
      notes: 'Check the cranks for side play and the bearings for rough rotation.',
      interval: DistanceThreshold(2000000),
      fallbackInterval: _year,
    ),
  ],
  ComponentType.seatpost: [
    TaskTemplate(
      key: 'seatpost:service',
      name: 'Dropper post service',
      interval: MovingTimeThreshold(Duration(hours: 100)),
      fallbackInterval: _year,
    ),
  ],
  ComponentType.frame: [
    TaskTemplate(
      key: 'frame:pivot_bearings',
      name: 'Check pivot bearings',
      notes: 'Check the suspension linkage for play and rough bearings.',
      interval: MovingTimeThreshold(Duration(hours: 100)),
      fallbackInterval: _year,
    ),
    TaskTemplate(
      key: 'frame:bolt_torque',
      name: 'Check bolt torque',
      notes: 'Check all bolts against the torque values printed on the parts or in the manual.',
      interval: ActivityCountThreshold(10),
      fallbackInterval: _month,
    ),
  ],
  ComponentType.shiftInnerCable: [
    TaskTemplate(
      key: 'shift_cable:replace',
      name: 'Replace shift cable',
      interval: _year,
    ),
  ],
};
