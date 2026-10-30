import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/context/context_weather.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_plan.dart';
import '../models/task/task_rule.dart';
import '../models/tip_product.dart';
import '../utils/installation_issue.dart';
import 'app_localizations.dart';

/// Display names of enums. The enums themselves are persisted by `name` (or
/// `toString()` in JSON), never by these labels, so a language switch can't
/// change stored data.

extension ComponentTypeCategoryLabel on ComponentTypeCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ComponentTypeCategory.frame => l10n.componentTypeCategoryFrame,
    ComponentTypeCategory.suspension => l10n.componentTypeCategorySuspension,
    ComponentTypeCategory.cockpit => l10n.componentTypeCategoryCockpit,
    ComponentTypeCategory.drivetrain => l10n.componentTypeCategoryDrivetrain,
    ComponentTypeCategory.brakes => l10n.componentTypeCategoryBrakes,
    ComponentTypeCategory.wheels => l10n.componentTypeCategoryWheels,
    ComponentTypeCategory.seating => l10n.componentTypeCategorySeating,
    ComponentTypeCategory.electronics => l10n.componentTypeCategoryElectronics,
    ComponentTypeCategory.others => l10n.componentTypeCategoryOthers,
  };
}

extension ComponentTypeLabel on ComponentType {
  String label(AppLocalizations l10n) => switch (this) {
    ComponentType.frame => l10n.componentTypeFrame,
    ComponentType.fork => l10n.componentTypeFork,
    ComponentType.shock => l10n.componentTypeShock,
    ComponentType.cockpit => l10n.componentTypeCockpit,
    ComponentType.stem => l10n.componentTypeStem,
    ComponentType.grip => l10n.componentTypeGrip,
    ComponentType.headset => l10n.componentTypeHeadset,
    ComponentType.shifter => l10n.componentTypeShifter,
    ComponentType.bottomBracket => l10n.componentTypeBottomBracket,
    ComponentType.crank => l10n.componentTypeCrank,
    ComponentType.derailleur => l10n.componentTypeDerailleur,
    ComponentType.chainring => l10n.componentTypeChainring,
    ComponentType.casette => l10n.componentTypeCasette,
    ComponentType.chain => l10n.componentTypeChain,
    ComponentType.pedal => l10n.componentTypePedal,
    ComponentType.shiftInnerCable => l10n.componentTypeShiftInnerCable,
    ComponentType.brakeCalliper => l10n.componentTypeBrakeCalliper,
    ComponentType.brakeLever => l10n.componentTypeBrakeLever,
    ComponentType.brakePad => l10n.componentTypeBrakePad,
    ComponentType.brakeDisc => l10n.componentTypeBrakeDisc,
    ComponentType.wheelFront => l10n.componentTypeWheelFront,
    ComponentType.wheelRear => l10n.componentTypeWheelRear,
    ComponentType.tire => l10n.componentTypeTire,
    ComponentType.saddle => l10n.componentTypeSaddle,
    ComponentType.seatpost => l10n.componentTypeSeatpost,
    ComponentType.battery => l10n.componentTypeBattery,
    ComponentType.motor => l10n.componentTypeMotor,
    ComponentType.bearing => l10n.componentTypeBearing,
    ComponentType.equipment => l10n.componentTypeEquipment,
    ComponentType.other => l10n.componentTypeOther,
  };
}

extension UnitQuantityLabel on UnitQuantity {
  String label(AppLocalizations l10n) => switch (this) {
    UnitQuantity.pressure => l10n.unitQuantityPressure,
    UnitQuantity.length => l10n.unitQuantityLength,
    UnitQuantity.mass => l10n.unitQuantityMass,
    UnitQuantity.temperature => l10n.unitQuantityTemperature,
    UnitQuantity.speed => l10n.unitQuantitySpeed,
    UnitQuantity.angle => l10n.unitQuantityAngle,
    UnitQuantity.torque => l10n.unitQuantityTorque,
    UnitQuantity.volume => l10n.unitQuantityVolume,
    UnitQuantity.springRate => l10n.unitQuantitySpringRate,
  };
}

extension TaskPriorityLabel on TaskPriority {
  String label(AppLocalizations l10n) => switch (this) {
    TaskPriority.low => l10n.taskPriorityLow,
    TaskPriority.medium => l10n.taskPriorityMedium,
    TaskPriority.high => l10n.taskPriorityHigh,
    TaskPriority.critical => l10n.taskPriorityCritical,
  };
}

extension StravaPlanLabel on StravaPlan {
  String label(AppLocalizations l10n) => switch (this) {
    StravaPlan.monthly => l10n.stravaPlanMonthlyLabel,
    StravaPlan.yearly => l10n.stravaPlanYearlyLabel,
  };

  String tagline(AppLocalizations l10n) => switch (this) {
    StravaPlan.monthly => l10n.stravaPlanMonthlyTagline,
    StravaPlan.yearly => l10n.stravaPlanYearlyTagline,
  };

  String period(AppLocalizations l10n) => switch (this) {
    StravaPlan.monthly => l10n.stravaPlanMonthlyPeriod,
    StravaPlan.yearly => l10n.stravaPlanYearlyPeriod,
  };
}

extension StravaWorkoutTypeLabel on StravaWorkoutType {
  String label(AppLocalizations l10n) => switch (this) {
    StravaWorkoutType.none => l10n.stravaWorkoutTypeNone,
    StravaWorkoutType.race => l10n.stravaWorkoutTypeRace,
    StravaWorkoutType.workout => l10n.stravaWorkoutTypeWorkout,
  };
}

extension SportTypeLabel on SportType {
  String label(AppLocalizations l10n) => switch (this) {
    SportType.AlpineSki => l10n.sportTypeAlpineSki,
    SportType.BackcountrySki => l10n.sportTypeBackcountrySki,
    SportType.Badminton => l10n.sportTypeBadminton,
    SportType.Canoeing => l10n.sportTypeCanoeing,
    SportType.Crossfit => l10n.sportTypeCrossfit,
    SportType.EBikeRide => l10n.sportTypeEBikeRide,
    SportType.Elliptical => l10n.sportTypeElliptical,
    SportType.EMountainBikeRide => l10n.sportTypeEMountainBikeRide,
    SportType.Golf => l10n.sportTypeGolf,
    SportType.GravelRide => l10n.sportTypeGravelRide,
    SportType.Handcycle => l10n.sportTypeHandcycle,
    SportType.HighIntensityIntervalTraining => l10n.sportTypeHighIntensityIntervalTraining,
    SportType.Hike => l10n.sportTypeHike,
    SportType.IceSkate => l10n.sportTypeIceSkate,
    SportType.InlineSkate => l10n.sportTypeInlineSkate,
    SportType.Kayaking => l10n.sportTypeKayaking,
    SportType.Kitesurf => l10n.sportTypeKitesurf,
    SportType.MountainBikeRide => l10n.sportTypeMountainBikeRide,
    SportType.NordicSki => l10n.sportTypeNordicSki,
    SportType.Pickleball => l10n.sportTypePickleball,
    SportType.Pilates => l10n.sportTypePilates,
    SportType.Racquetball => l10n.sportTypeRacquetball,
    SportType.Ride => l10n.sportTypeRide,
    SportType.RockClimbing => l10n.sportTypeRockClimbing,
    SportType.RollerSki => l10n.sportTypeRollerSki,
    SportType.Rowing => l10n.sportTypeRowing,
    SportType.Run => l10n.sportTypeRun,
    SportType.Sail => l10n.sportTypeSail,
    SportType.Skateboard => l10n.sportTypeSkateboard,
    SportType.Snowboard => l10n.sportTypeSnowboard,
    SportType.Snowshoe => l10n.sportTypeSnowshoe,
    SportType.Soccer => l10n.sportTypeSoccer,
    SportType.Squash => l10n.sportTypeSquash,
    SportType.StairStepper => l10n.sportTypeStairStepper,
    SportType.StandUpPaddling => l10n.sportTypeStandUpPaddling,
    SportType.Surfing => l10n.sportTypeSurfing,
    SportType.Swim => l10n.sportTypeSwim,
    SportType.TableTennis => l10n.sportTypeTableTennis,
    SportType.Tennis => l10n.sportTypeTennis,
    SportType.TrailRun => l10n.sportTypeTrailRun,
    SportType.Velomobile => l10n.sportTypeVelomobile,
    SportType.VirtualRide => l10n.sportTypeVirtualRide,
    SportType.VirtualRow => l10n.sportTypeVirtualRow,
    SportType.VirtualRun => l10n.sportTypeVirtualRun,
    SportType.Walk => l10n.sportTypeWalk,
    SportType.WeightTraining => l10n.sportTypeWeightTraining,
    SportType.Wheelchair => l10n.sportTypeWheelchair,
    SportType.Windsurf => l10n.sportTypeWindsurf,
    SportType.Workout => l10n.sportTypeWorkout,
    SportType.Yoga => l10n.sportTypeYoga,
    SportType.Other => l10n.sportTypeOther,
  };
}

extension ConditionLabel on Condition {
  String label(AppLocalizations l10n) => switch (this) {
    Condition.dry => l10n.weatherConditionDry,
    Condition.moist => l10n.weatherConditionMoist,
    Condition.wet => l10n.weatherConditionWet,
    Condition.muddy => l10n.weatherConditionMuddy,
  };
}

extension StepAdjustmentVisualizationLabel on StepAdjustmentVisualization {
  String label(AppLocalizations l10n) => switch (this) {
    StepAdjustmentVisualization.minusButtonValuePlusButton => l10n.stepVisualizationMinusButtonValuePlusButton,
    StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial =>
      l10n.stepVisualizationMinusButtonValuePlusButtonClockwiseDial,
    StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial =>
      l10n.stepVisualizationMinusButtonValuePlusButtonCounterclockwiseDial,
    StepAdjustmentVisualization.slider => l10n.stepVisualizationSlider,
    StepAdjustmentVisualization.sliderWithClockwiseDial => l10n.stepVisualizationSliderWithClockwiseDial,
    StepAdjustmentVisualization.sliderWithCounterclockwiseDial => l10n.stepVisualizationSliderWithCounterclockwiseDial,
  };
}

extension TipProductLabel on TipProduct {
  String label(AppLocalizations l10n) => switch (this) {
    TipProduct.small => l10n.tipProductSmall,
    TipProduct.medium => l10n.tipProductMedium,
    TipProduct.large => l10n.tipProductLarge,
  };
}

extension InstallationIssueLabel on InstallationIssue {
  String label(AppLocalizations l10n) => switch (this) {
    InstallationIssue.missingBike => l10n.installationIssueMissingBike,
    InstallationIssue.missingParent => l10n.installationIssueMissingParent,
  };
}
