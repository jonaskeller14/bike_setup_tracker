import '../l10n/l10n.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';

Map<ComponentType, List<Adjustment>> componentAdjustmentPresetsFor(AppLocalizations l10n) {
  Set<String> wear() => {
    l10n.adjustmentTemplateOptionNew,
    l10n.adjustmentTemplateOptionUsed,
    l10n.adjustmentTemplateOptionWornOut,
  };
  Set<String> clothing() => {l10n.adjustmentTemplateOptionClothingA, l10n.adjustmentTemplateOptionClothingB};

  List<Adjustment> suspension(ComponentType type) {
    final prefix = type.name;
    return [
      BooleanAdjustment(
        name: l10n.adjustmentTemplateLockoutName,
        unit: null,
        notes: l10n.adjustmentTemplateLockoutNotes,
        presetKey: "$prefix:lockout",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplatePressureName,
        unit: AdjustmentUnit.fromLegacy("psi"),
        min: 0,
        notes: type == ComponentType.fork
            ? l10n.adjustmentTemplateForkPressureNotes
            : l10n.adjustmentTemplateShockPressureNotes,
        presetKey: "$prefix:pressure",
      ),
      if (type == ComponentType.shock)
        NumericalAdjustment(
          name: l10n.adjustmentTemplateSpringRateName,
          unit: AdjustmentUnit.fromLegacy("lbs/in"),
          min: 0,
          notes: l10n.adjustmentTemplateSpringRateNotes,
          presetKey: "shock:spring_rate",
        ),
      sagPresetFor(l10n, type),
      StepAdjustment(
        name: l10n.adjustmentTemplateReboundName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        dialColor: StepAdjustmentDialColor.red,
        notes: l10n.adjustmentTemplateReboundNotes,
        presetKey: "$prefix:rebound",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateCompressionName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        notes: l10n.adjustmentTemplateCompressionNotes,
        presetKey: "$prefix:compression",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateLsrName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        dialColor: StepAdjustmentDialColor.red,
        notes: l10n.adjustmentTemplateLsrNotes,
        presetKey: "$prefix:lsr",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateHsrName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        dialColor: StepAdjustmentDialColor.red,
        notes: l10n.adjustmentTemplateHsrNotes,
        presetKey: "$prefix:hsr",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateLscName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        notes: l10n.adjustmentTemplateLscNotes,
        presetKey: "$prefix:lsc",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateHscName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        notes: l10n.adjustmentTemplateHscNotes,
        presetKey: "$prefix:hsc",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateVolumeSpacersName,
        unit: null,
        step: 1,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.minusButtonValuePlusButton,
        notes: l10n.adjustmentTemplateVolumeSpacersNotes,
        presetKey: "$prefix:volume_spacers",
      ),
    ];
  }

  return {
    ComponentType.frame: [
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateFlipchipName,
        notes: l10n.adjustmentTemplateFlipchipNotes,
        unit: null,
        options: {
          l10n.adjustmentTemplateOptionLow,
          l10n.adjustmentTemplateOptionMid,
          l10n.adjustmentTemplateOptionHigh,
        },
        presetKey: "frame:flipchip",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateChainstayLengthName,
        notes: l10n.adjustmentTemplateChainstayLengthNotes,
        unit: null,
        options: {
          l10n.adjustmentTemplateOptionShort,
          l10n.adjustmentTemplateOptionMid,
          l10n.adjustmentTemplateOptionLong,
        },
        presetKey: "frame:chainstay_length",
      ),
    ],
    ComponentType.fork: suspension(ComponentType.fork),
    ComponentType.shock: suspension(ComponentType.shock),
    ComponentType.cockpit: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateBarRollName,
        unit: AdjustmentUnit.fromLegacy("°"),
        notes: l10n.adjustmentTemplateBarRollNotes,
        presetKey: "cockpit:bar_roll",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateBarWidthName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        min: 0,
        notes: l10n.adjustmentTemplateBarWidthNotes,
        presetKey: "cockpit:bar_width",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateBarRiseName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        min: 0,
        notes: l10n.adjustmentTemplateBarRiseNotes,
        presetKey: "cockpit:bar_rise",
      ),
    ],
    ComponentType.stem: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateStemLengthName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        min: 0,
        notes: l10n.adjustmentTemplateStemLengthNotes,
        presetKey: "stem:stem_length",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateStemAngleName,
        unit: AdjustmentUnit.fromLegacy("°"),
        notes: l10n.adjustmentTemplateStemAngleNotes,
        presetKey: "stem:stem_angle",
      ),
      StepAdjustment(
        name: l10n.adjustmentTemplateStackSpacersName,
        unit: null,
        step: 5,
        min: 0,
        max: 100,
        visualization: StepAdjustmentVisualization.minusButtonValuePlusButton,
        notes: l10n.adjustmentTemplateStackSpacersNotes,
        presetKey: "stem:stack_spacers",
      ),
    ],
    ComponentType.grip: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateGripRotationName,
        unit: AdjustmentUnit.fromLegacy("°"),
        notes: l10n.adjustmentTemplateGripRotationNotes,
        presetKey: "grip:rotation",
      ),
    ],
    ComponentType.shifter: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateLateralPositionName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        notes: l10n.adjustmentTemplateShifterLateralPositionNotes,
        presetKey: "shifter:lateral_position",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateAngleName,
        unit: AdjustmentUnit.fromLegacy("°"),
        notes: l10n.adjustmentTemplateShifterAngleNotes,
        presetKey: "shifter:angle",
      ),
    ],
    ComponentType.derailleur: [
      BooleanAdjustment(
        name: l10n.adjustmentTemplateClutchName,
        notes: l10n.adjustmentTemplateClutchNotes,
        unit: null,
        presetKey: "derailleur:clutch",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateClutchTensionName,
        options: {
          l10n.adjustmentTemplateOptionSoft,
          l10n.adjustmentTemplateOptionMedium,
          l10n.adjustmentTemplateOptionHard,
        },
        notes: l10n.adjustmentTemplateClutchTensionNotes,
        unit: null,
        presetKey: "derailleur:clutch_tension",
      ),
    ],
    ComponentType.pedal: [
      StepAdjustment(
        name: l10n.adjustmentTemplateClipSpringTensionName,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        notes: l10n.adjustmentTemplateClipSpringTensionNotes,
        presetKey: "pedal:spring_tension",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplatePinArrangementName,
        options: {
          l10n.adjustmentTemplateOptionFull,
          l10n.adjustmentTemplateOptionAggressive,
          l10n.adjustmentTemplateOptionBalanced,
          l10n.adjustmentTemplateOptionMinimum,
        },
        notes: l10n.adjustmentTemplatePinArrangementNotes,
        unit: null,
        presetKey: "pedal:pin_arrangement",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplatePinHeightName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        min: 0,
        notes: l10n.adjustmentTemplatePinHeightNotes,
        presetKey: "pedal:pin_height",
      ),
    ],
    ComponentType.brakeLever: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateLeverReachName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        notes: l10n.adjustmentTemplateLeverReachNotes,
        presetKey: "brake_lever:lever_reach",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateLeverAngleName,
        unit: AdjustmentUnit.fromLegacy("°"),
        notes: l10n.adjustmentTemplateLeverAngleNotes,
        presetKey: "brake_lever:lever_angle",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateLateralPositionName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        notes: l10n.adjustmentTemplateBrakeLeverLateralPositionNotes,
        presetKey: "brake_lever:lateral_position",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateBitePointName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        notes: l10n.adjustmentTemplateBitePointNotes,
        presetKey: "brake_lever:bite_point",
      ),
    ],
    ComponentType.wheelFront: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplatePressureName,
        unit: AdjustmentUnit.fromLegacy("bar"),
        min: 0,
        notes: l10n.adjustmentTemplateFrontPressureNotes,
        presetKey: "wheel_front:pressure",
      ),
      BooleanAdjustment(
        name: l10n.adjustmentTemplateInsertName,
        unit: null,
        notes: l10n.adjustmentTemplateInsertNotes,
        presetKey: "wheel_front:insert",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateWearName,
        options: wear(),
        unit: null,
        notes: l10n.adjustmentTemplateWearNotes,
        presetKey: "wheel_front:wear",
      ),
    ],
    ComponentType.wheelRear: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateTirePressureName,
        unit: AdjustmentUnit.fromLegacy("bar"),
        min: 0,
        notes: l10n.adjustmentTemplateRearPressureNotes,
        presetKey: "wheel_rear:tire_pressure",
      ),
      BooleanAdjustment(
        name: l10n.adjustmentTemplateInsertName,
        unit: null,
        notes: l10n.adjustmentTemplateInsertNotes,
        presetKey: "wheel_rear:insert",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateTireWearName,
        options: wear(),
        unit: null,
        notes: l10n.adjustmentTemplateWearNotes,
        presetKey: "wheel_rear:tire_wear",
      ),
    ],
    ComponentType.tire: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplatePressureName,
        unit: AdjustmentUnit.fromLegacy("bar"),
        min: 0,
        notes: l10n.adjustmentTemplateTirePressureNotes,
        presetKey: "tire:pressure",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateWearName,
        options: wear(),
        unit: null,
        notes: l10n.adjustmentTemplateWearNotes,
        presetKey: "tire:wear",
      ),
    ],
    ComponentType.saddle: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateSaddleTiltName,
        unit: AdjustmentUnit.fromLegacy("°"),
        notes: l10n.adjustmentTemplateSaddleTiltNotes,
        presetKey: "saddle:saddle_tilt",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateSaddleForeAftName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        notes: l10n.adjustmentTemplateSaddleForeAftNotes,
        presetKey: "saddle:saddle_fore_aft",
      ),
    ],
    ComponentType.seatpost: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateSaddleHeightName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        min: 0,
        notes: l10n.adjustmentTemplateSaddleHeightNotes,
        presetKey: "seatpost:saddle_height",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateDropperPressureName,
        unit: AdjustmentUnit.fromLegacy("psi"),
        min: 0,
        notes: l10n.adjustmentTemplateDropperPressureNotes,
        presetKey: "seatpost:dropper_pressure",
      ),
    ],
    ComponentType.motor: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateMaxPowerName,
        unit: AdjustmentUnit.fromLegacy("W"),
        min: 0,
        notes: l10n.adjustmentTemplateMaxPowerNotes,
        presetKey: "motor:max_power",
      ),
      NumericalAdjustment(
        name: l10n.adjustmentTemplateMaxTorqueName,
        unit: AdjustmentUnit.fromLegacy("Nm"),
        min: 0,
        notes: l10n.adjustmentTemplateMaxTorqueNotes,
        presetKey: "motor:max_torque",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateModeName,
        notes: l10n.adjustmentTemplateModeNotes,
        unit: null,
        options: {
          l10n.adjustmentTemplateOptionEco,
          l10n.adjustmentTemplateOptionTrail,
          l10n.adjustmentTemplateOptionTurbo,
          l10n.adjustmentTemplateOptionBoost,
          l10n.adjustmentTemplateOptionAuto,
        },
        presetKey: "motor:mode",
      ),
    ],
    ComponentType.equipment: [
      BooleanAdjustment(
        name: l10n.adjustmentTemplateBackpackName,
        notes: l10n.adjustmentTemplateBackpackNotes,
        unit: null,
        presetKey: "equipment:backpack",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateUpperLayer1Name,
        notes: l10n.adjustmentTemplateUpperLayer1Notes,
        unit: null,
        options: clothing(),
        presetKey: "equipment:upper_clothing_1",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateUpperLayer2Name,
        notes: l10n.adjustmentTemplateUpperLayer2Notes,
        unit: null,
        options: clothing(),
        presetKey: "equipment:upper_clothing_2",
      ),
      CategoricalAdjustment(
        name: l10n.adjustmentTemplateCleatPositionName,
        notes: l10n.adjustmentTemplateCleatPositionNotes,
        unit: null,
        options: {
          l10n.adjustmentTemplateOptionForward,
          l10n.adjustmentTemplateOptionNeutral,
          l10n.adjustmentTemplateOptionRearward,
        },
        presetKey: "equipment:cleat_position",
      ),
    ],
    ComponentType.other: [
      NumericalAdjustment(
        name: l10n.adjustmentTemplateStackHeightName,
        unit: AdjustmentUnit.fromLegacy("mm"),
        min: 0,
        notes: l10n.adjustmentTemplateStackSpacersNotes,
        presetKey: "other:stack_height",
      ),
    ],
  };
}

SagAdjustment sagPresetFor(AppLocalizations l10n, ComponentType type) => SagAdjustment(
  name: l10n.adjustmentTemplateSagName,
  notes: type == ComponentType.shock ? l10n.adjustmentTemplateShockSagNotes : l10n.adjustmentTemplateForkSagNotes,
  presetKey: "${type.name}:sag",
);

NumericalAdjustment ridingWeightPresetFor(AppLocalizations l10n) => NumericalAdjustment(
  name: l10n.riderTemplateRidingWeightName,
  unit: AdjustmentUnit.fromLegacy('kg'),
  min: 0.0,
  notes: l10n.riderTemplateRidingWeightNotes,
  presetKey: "person:riding_weight",
);

List<Adjustment> personAdjustmentPresetsFor(AppLocalizations l10n) => [
  ridingWeightPresetFor(l10n),
  NumericalAdjustment(
    name: l10n.riderTemplateHeightName,
    unit: AdjustmentUnit.fromLegacy('cm'),
    min: 0.0,
    notes: l10n.riderTemplateHeightNotes,
    presetKey: "person:height",
  ),
  NumericalAdjustment(
    name: l10n.riderTemplateInseamName,
    unit: AdjustmentUnit.fromLegacy('cm'),
    min: 0.0,
    notes: l10n.riderTemplateInseamNotes,
    presetKey: "person:inseam",
  ),
  NumericalAdjustment(
    name: l10n.riderTemplateFtpName,
    unit: AdjustmentUnit.fromLegacy('W'),
    min: 0.0,
    notes: l10n.riderTemplateFtpNotes,
    presetKey: "person:ftp",
  ),
  NumericalAdjustment(
    name: l10n.riderTemplateMaxHeartRateName,
    unit: AdjustmentUnit.fromLegacy('bpm'),
    min: 0.0,
    notes: l10n.riderTemplateMaxHeartRateNotes,
    presetKey: "person:max_heart_rate",
  ),
  NumericalAdjustment(
    name: l10n.riderTemplateRestingHeartRateName,
    unit: AdjustmentUnit.fromLegacy('bpm'),
    min: 0.0,
    notes: l10n.riderTemplateRestingHeartRateNotes,
    presetKey: "person:resting_heart_rate",
  ),
  NumericalAdjustment(
    name: l10n.riderTemplateLthrName,
    unit: AdjustmentUnit.fromLegacy('bpm'),
    min: 0.0,
    notes: l10n.riderTemplateLthrNotes,
    presetKey: "person:lthr",
  ),
  CategoricalAdjustment(
    name: l10n.riderTemplateRidingStyleName,
    unit: null,
    options: {
      l10n.adjustmentTemplateOptionComfort,
      l10n.adjustmentTemplateOptionBalanced,
      l10n.adjustmentTemplateOptionRace,
    },
    notes: l10n.riderTemplateRidingStyleNotes,
    presetKey: "person:riding_style",
  ),
];

String _normalizedName(String name) => name.trim().toLowerCase();

final Map<String, Set<String>> _nameVariants = () {
  final variants = <String, Set<String>>{};
  for (final l10n in allLocalizations) {
    for (final preset in [
      ...componentAdjustmentPresetsFor(l10n).values.expand((presets) => presets),
      ...personAdjustmentPresetsFor(l10n),
    ]) {
      final key = preset.presetKey;
      if (key != null) (variants[key] ??= {}).add(_normalizedName(preset.name));
    }
  }
  return variants;
}();

Set<String> adjustmentPresetNameVariants(Adjustment preset) =>
    _nameVariants[preset.presetKey] ?? {_normalizedName(preset.name)};
