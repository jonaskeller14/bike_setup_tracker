import '../l10n/l10n.dart';
import '../models/component/component.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_template.dart';
import '../models/task/task_threshold/task_threshold.dart';

const _month = DurationThreshold(Duration(days: 30));
const _threeMonths = DurationThreshold(Duration(days: 90));
const _sixMonths = DurationThreshold(Duration(days: 180));
const _year = DurationThreshold(Duration(days: 365));

List<TaskTemplate> _wheelTemplates(AppLocalizations l10n) => [
  TaskTemplate(
    key: 'wheel:spoke_tension',
    name: l10n.taskTemplateWheelSpokeTensionName,
    notes: l10n.taskTemplateWheelSpokeTensionNotes,
    interval: const DistanceThreshold(1000000),
    fallbackInterval: _sixMonths,
    preselected: true,
  ),
  TaskTemplate(
    key: 'wheel:hub_bearing',
    name: l10n.taskTemplateWheelHubBearingName,
    notes: l10n.taskTemplateWheelHubBearingNotes,
    interval: const DistanceThreshold(3000000),
    fallbackInterval: _year,
  ),
];

Map<ComponentType, List<TaskTemplate>> taskPresetsFor(AppLocalizations l10n) {
  final wheel = _wheelTemplates(l10n);
  return {
    ComponentType.chain: [
      TaskTemplate(
        key: 'chain:wear_check',
        name: l10n.taskTemplateChainWearCheckName,
        notes: l10n.taskTemplateChainWearCheckNotes,
        interval: const DistanceThreshold(500000),
        fallbackInterval: _month,
        preselected: true,
      ),
      TaskTemplate(
        key: 'chain:replace',
        name: l10n.taskTemplateChainReplaceName,
        interval: const DistanceThreshold(2000000),
        priority: TaskPriority.high,
      ),
      TaskTemplate(
        key: 'chain:lube',
        name: l10n.taskTemplateChainLubeName,
        interval: const ActivityCountThreshold(5),
        priority: TaskPriority.low,
      ),
    ],
    ComponentType.casette: [
      TaskTemplate(
        key: 'cassette:wear_check',
        name: l10n.taskTemplateCassetteWearCheckName,
        notes: l10n.taskTemplateCassetteWearCheckNotes,
        interval: const DistanceThreshold(6000000),
        fallbackInterval: _year,
      ),
    ],
    ComponentType.fork: [
      TaskTemplate(
        key: 'fork:lower_leg_service',
        name: l10n.taskTemplateForkLowerLegServiceName,
        notes: l10n.taskTemplateForkLowerLegServiceNotes,
        interval: const MovingTimeThreshold(Duration(hours: 50)),
        fallbackInterval: _sixMonths,
        preselected: true,
      ),
      TaskTemplate(
        key: 'fork:full_service',
        name: l10n.taskTemplateForkFullServiceName,
        notes: l10n.taskTemplateForkFullServiceNotes,
        interval: const MovingTimeThreshold(Duration(hours: 200)),
        fallbackInterval: _year,
        preselected: true,
      ),
    ],
    ComponentType.shock: [
      TaskTemplate(
        key: 'shock:air_can_service',
        name: l10n.taskTemplateShockAirCanServiceName,
        notes: l10n.taskTemplateShockAirCanServiceNotes,
        interval: const MovingTimeThreshold(Duration(hours: 50)),
        fallbackInterval: _sixMonths,
        preselected: true,
      ),
      TaskTemplate(
        key: 'shock:full_service',
        name: l10n.taskTemplateShockFullServiceName,
        notes: l10n.taskTemplateShockFullServiceNotes,
        interval: const MovingTimeThreshold(Duration(hours: 200)),
        fallbackInterval: _year,
        preselected: true,
      ),
    ],
    ComponentType.brakePad: [
      TaskTemplate(
        key: 'brake_pad:wear_check',
        name: l10n.taskTemplateBrakePadWearCheckName,
        notes: l10n.taskTemplateBrakePadWearCheckNotes,
        interval: const DistanceThreshold(500000),
        fallbackInterval: _month,
        priority: TaskPriority.high,
        preselected: true,
      ),
    ],
    ComponentType.brakeCalliper: [
      TaskTemplate(
        key: 'brake:bleed',
        name: l10n.taskTemplateBrakeBleedName,
        notes: l10n.taskTemplateBrakeBleedNotes,
        interval: _year,
      ),
    ],
    ComponentType.tire: [
      TaskTemplate(
        key: 'tire:sealant',
        name: l10n.taskTemplateTireSealantName,
        notes: l10n.taskTemplateTireSealantNotes,
        interval: _threeMonths,
        preselected: true,
      ),
    ],
    ComponentType.wheelFront: wheel,
    ComponentType.wheelRear: wheel,
    ComponentType.headset: [
      TaskTemplate(
        key: 'headset:service',
        name: l10n.taskTemplateHeadsetServiceName,
        interval: const MovingTimeThreshold(Duration(hours: 100)),
        fallbackInterval: _year,
      ),
    ],
    ComponentType.bottomBracket: [
      TaskTemplate(
        key: 'bb:play_check',
        name: l10n.taskTemplateBbPlayCheckName,
        notes: l10n.taskTemplateBbPlayCheckNotes,
        interval: const DistanceThreshold(2000000),
        fallbackInterval: _year,
      ),
    ],
    ComponentType.seatpost: [
      TaskTemplate(
        key: 'seatpost:service',
        name: l10n.taskTemplateSeatpostServiceName,
        interval: const MovingTimeThreshold(Duration(hours: 100)),
        fallbackInterval: _year,
      ),
    ],
    ComponentType.frame: [
      TaskTemplate(
        key: 'frame:pivot_bearings',
        name: l10n.taskTemplateFramePivotBearingsName,
        notes: l10n.taskTemplateFramePivotBearingsNotes,
        interval: const MovingTimeThreshold(Duration(hours: 100)),
        fallbackInterval: _year,
      ),
      TaskTemplate(
        key: 'frame:bolt_torque',
        name: l10n.taskTemplateFrameBoltTorqueName,
        notes: l10n.taskTemplateFrameBoltTorqueNotes,
        interval: const ActivityCountThreshold(10),
        fallbackInterval: _month,
      ),
    ],
    ComponentType.shiftInnerCable: [
      TaskTemplate(
        key: 'shift_cable:replace',
        name: l10n.taskTemplateShiftCableReplaceName,
        interval: _year,
      ),
    ],
  };
}
