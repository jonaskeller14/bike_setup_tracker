import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../models/component/resolved_installation.dart';
import '../models/context/context_weather.dart';
import '../models/feedback/feedback_vocabulary.dart';
import '../models/service_error.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_plan.dart';
import '../models/task/task_rule.dart';
import '../models/tip_product.dart';
import '../services/location_service.dart';
import '../services/test_session/suggestion_result.dart';
import '../services/weather_service.dart';
import '../utils/installation_issue.dart';
import '../utils/installation_timeline_validation.dart';
import '../utils/table_column.dart';
import '../utils/value_delta.dart';
import 'adjustment_value_text.dart';
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

  /// [label] inside a sentence: lowercase in English, while German nouns keep their capital.
  String labelInSentence(AppLocalizations l10n) =>
      l10n.localeName == 'de' ? label(l10n) : label(l10n).toLowerCase();
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

extension ContextWeatherLabel on ContextWeather {
  String? getWeatherCodeLabel(AppLocalizations l10n) => weatherCodeLabel(currentWeatherCode, l10n);
}

/// The WMO weather [code] as text, `null` without a code.
String? weatherCodeLabel(int? code, AppLocalizations l10n) {
  if (code == null) return null;
  switch (code) {
    // Clear and Cloudy
    case 0: return l10n.weatherCode0;
    case 1: return l10n.weatherCode1;
    case 2: return l10n.weatherCode2;
    case 3: return l10n.weatherCode3;

    // Fog
    case 45: return l10n.weatherCode45;
    case 48: return l10n.weatherCode48;

    // Drizzle
    case 51: return l10n.weatherCode51;
    case 53: return l10n.weatherCode53;
    case 55: return l10n.weatherCode55;
    case 56: return l10n.weatherCode56;
    case 57: return l10n.weatherCode57;

    // Rain
    case 61: return l10n.weatherCode61;
    case 63: return l10n.weatherCode63;
    case 65: return l10n.weatherCode65;
    case 66: return l10n.weatherCode66;
    case 67: return l10n.weatherCode67;

    // Snow
    case 71: return l10n.weatherCode71;
    case 73: return l10n.weatherCode73;
    case 75: return l10n.weatherCode75;
    case 77: return l10n.weatherCode77;

    // Showers
    case 80: return l10n.weatherCode80;
    case 81: return l10n.weatherCode81;
    case 82: return l10n.weatherCode82;
    case 85: return l10n.weatherCode85;
    case 86: return l10n.weatherCode86;

    // Thunderstorms
    case 95: return l10n.weatherCode95;
    case 96: return l10n.weatherCode96;
    case 99: return l10n.weatherCode99;

    default: return l10n.weatherCodeUnknown;
  }
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

extension ResolvedInstallationLabel on ResolvedInstallation {
  String label(AppLocalizations l10n) {
    final name = component.name;
    if (isInitial) return l10n.timelineAdded(name);
    return switch (installation.parentType) {
      InstallationParentType.bike || InstallationParentType.component => l10n.timelineInstalled(name),
      InstallationParentType.none => l10n.timelineUninstalledName(name),
      InstallationParentType.archived => l10n.timelineArchivedName(name),
    };
  }
}

extension InstallationTimelineProblemLabel on InstallationTimelineProblem {
  String label(AppLocalizations l10n) => switch (this) {
    InstallationTimelineProblem.noEntries => l10n.timelineProblemNoEntries,
    InstallationTimelineProblem.archivalNotLast => l10n.timelineProblemArchivalNotLast,
    InstallationTimelineProblem.consecutiveUninstallations => l10n.timelineProblemConsecutiveUninstallations,
    InstallationTimelineProblem.consecutiveOnSameBike => l10n.timelineProblemConsecutiveOnSameBike,
    InstallationTimelineProblem.consecutiveOnSameComponent => l10n.timelineProblemConsecutiveOnSameComponent,
    InstallationTimelineProblem.multipleFromBeginning => l10n.timelineProblemMultipleFromBeginning,
    InstallationTimelineProblem.sameDateTime => l10n.timelineProblemSameDateTime,
    InstallationTimelineProblem.bikeMissing => l10n.timelineProblemBikeMissing,
    InstallationTimelineProblem.installedOnItself => l10n.timelineProblemInstalledOnItself,
    InstallationTimelineProblem.componentLoop => l10n.timelineProblemComponentLoop,
  };
}

extension TableColumnSectionLabel on TableColumnSection {
  String label(AppLocalizations l10n) => switch (this) {
    TableColumnSection.generalContext => l10n.tableSectionGeneralContext,
    TableColumnSection.weatherContext => l10n.tableSectionWeatherContext,
    TableColumnSection.componentAdjustments => l10n.tableSectionComponentAdjustments,
    TableColumnSection.personAttributes => l10n.tableSectionPersonAttributes,
    TableColumnSection.feedback => l10n.tableSectionFeedback,
  };
}

extension SetupColumnLabel on SetupColumn {
  String label(AppLocalizations l10n) => switch (this) {
    SetupColumn.name => l10n.setupColumnName,
    SetupColumn.notes => l10n.setupColumnNotes,
    SetupColumn.tags => l10n.setupColumnTags,
    SetupColumn.date => l10n.setupColumnDate,
    SetupColumn.time => l10n.setupColumnTime,
    SetupColumn.place => l10n.setupColumnPlace,
    SetupColumn.altitude => l10n.setupColumnAltitude,
    SetupColumn.bike => l10n.setupColumnBike,
    SetupColumn.bookmarked => l10n.setupColumnBookmarked,
    SetupColumn.activities => l10n.setupColumnActivities,
    SetupColumn.weatherCode => l10n.setupColumnWeatherCode,
    SetupColumn.temperature => l10n.setupColumnTemperature,
    SetupColumn.precipitation => l10n.setupColumnPrecipitation,
    SetupColumn.humidity => l10n.setupColumnHumidity,
    SetupColumn.windSpeed => l10n.setupColumnWindSpeed,
    SetupColumn.soilMoisture => l10n.setupColumnSoilMoisture,
    SetupColumn.condition => l10n.setupColumnCondition,
    SetupColumn.testSession => l10n.setupColumnTestSession,
  };
}

extension LocationStatusMessage on LocationStatus {
  String errorMessage(AppLocalizations l10n) => switch (this) {
    LocationStatus.noService => l10n.setupFormLocationDisabled,
    LocationStatus.noPermission => l10n.setupFormLocationNoPermission,
    LocationStatus.permissionDeniedForever => l10n.setupFormLocationDeniedForever,
    LocationStatus.timeout => l10n.mapLocationTimeout,
    LocationStatus.error => l10n.mapLocationError,
    _ => l10n.mapLocationNone,
  };
}

extension FeedbackEndLabel on FeedbackEnd {
  String label(AppLocalizations l10n) => switch (this) {
    FeedbackEnd.front => l10n.feedbackEndFront,
    FeedbackEnd.rear => l10n.feedbackEndRear,
  };
}

extension FeedbackAttributeLabel on FeedbackAttribute {
  String qualityLabel(AppLocalizations l10n) => switch (this) {
    FeedbackAttribute.grip => l10n.feedbackAttributeGripQuality,
    FeedbackAttribute.comfort => l10n.feedbackAttributeComfortQuality,
    FeedbackAttribute.support => l10n.feedbackAttributeSupportQuality,
    FeedbackAttribute.calm => l10n.feedbackAttributeCalmQuality,
    FeedbackAttribute.bottoming => l10n.feedbackAttributeBottomingQuality,
  };

  String problemLabel(AppLocalizations l10n) => switch (this) {
    FeedbackAttribute.grip => l10n.feedbackAttributeGripProblem,
    FeedbackAttribute.comfort => l10n.feedbackAttributeComfortProblem,
    FeedbackAttribute.support => l10n.feedbackAttributeSupportProblem,
    FeedbackAttribute.calm => l10n.feedbackAttributeCalmProblem,
    FeedbackAttribute.bottoming => l10n.feedbackAttributeBottomingProblem,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    FeedbackAttribute.grip => l10n.feedbackAttributeGripHint,
    FeedbackAttribute.comfort => l10n.feedbackAttributeComfortHint,
    FeedbackAttribute.support => l10n.feedbackAttributeSupportHint,
    FeedbackAttribute.calm => l10n.feedbackAttributeCalmHint,
    FeedbackAttribute.bottoming => l10n.feedbackAttributeBottomingHint,
  };
}

/// Comparison answers by outcome, ordered worse to better.
abstract final class FeedbackOutcomeLabels {
  static Map<int, String> overall(AppLocalizations l10n) => {
    -2: l10n.feedbackOutcomeWorse,
    -1: l10n.feedbackOutcomeSlightlyWorse,
    0: l10n.feedbackOutcomeSame,
    1: l10n.feedbackOutcomeSlightlyBetter,
    2: l10n.feedbackOutcomeBetter,
  };

  /// +1 means the aspect improved (a problem got smaller).
  static Map<int, String> aspect(AppLocalizations l10n) => {
    -1: l10n.feedbackOutcomeWorse,
    0: l10n.feedbackOutcomeSame,
    1: l10n.feedbackOutcomeBetter,
  };
}

/// Error texts of the services, which report a kind and an optional technical
/// detail instead of a sentence. The detail is shown as is.
extension DataErrorMessage on DataError {
  String message(AppLocalizations l10n) => switch (kind) {
    DataErrorKind.getLocalBackups => l10n.dataErrorGetLocalBackups(detail ?? ''),
    DataErrorKind.readLocalBackup => l10n.dataErrorReadLocalBackup(detail ?? ''),
    DataErrorKind.importFile => l10n.dataErrorImportFile(detail ?? ''),
    DataErrorKind.noFileSelected => l10n.dataErrorNoFileSelected,
    DataErrorKind.bundleWithoutData => l10n.dataErrorBundleWithoutData,
    DataErrorKind.driveNoInternet => l10n.dataErrorDriveNoInternet,
    DataErrorKind.driveApi => l10n.dataErrorDriveApi(detail ?? ''),
    DataErrorKind.driveUnexpected => l10n.dataErrorDriveUnexpected,
    DataErrorKind.readDriveBackup => l10n.dataErrorReadDriveBackup(detail ?? ''),
  };
}

extension StepAdjustmentDialColorLabel on StepAdjustmentDialColor {
  String label(AppLocalizations l10n) => switch (this) {
    StepAdjustmentDialColor.blue => l10n.dialColorBlue,
    StepAdjustmentDialColor.red => l10n.dialColorRed,
    StepAdjustmentDialColor.green => l10n.dialColorGreen,
    StepAdjustmentDialColor.brown => l10n.dialColorBrown,
    StepAdjustmentDialColor.orange => l10n.dialColorOrange,
    StepAdjustmentDialColor.purple => l10n.dialColorPurple,
    StepAdjustmentDialColor.grey => l10n.dialColorGrey,
  };
}

extension StepAdjustmentDialSizeLabel on StepAdjustmentDialSize {
  String label(AppLocalizations l10n) => switch (this) {
    StepAdjustmentDialSize.normal => l10n.dialSizeNormal,
    StepAdjustmentDialSize.small => l10n.dialSizeSmall,
  };
}

extension SuggestionNoteText on SuggestionNote {
  String text(AppLocalizations l10n) {
    final filled = [for (final arg in args) _argText(arg, l10n)];
    return switch (kind) {
      SuggestionNoteKind.recordRunFirst => l10n.suggestionRecordRunFirst,
      SuggestionNoteKind.addFeedbackFirst => l10n.suggestionAddFeedbackFirst(filled[0]),
      SuggestionNoteKind.adjustmentGone => l10n.suggestionAdjustmentGone,
      SuggestionNoteKind.noValue => l10n.suggestionNoValue(filled[0], filled[1]),
      SuggestionNoteKind.outOfRange => l10n.suggestionOutOfRange(filled[0], filled[1]),
      SuggestionNoteKind.allLocked => l10n.suggestionAllLocked,
      SuggestionNoteKind.notCompare => l10n.suggestionNotCompare,
      SuggestionNoteKind.setupRemoved => l10n.suggestionSetupRemoved,
      SuggestionNoteKind.patternStep => l10n.suggestionPatternStep(filled[0], filled[1], filled[2], filled[3]),
      SuggestionNoteKind.estimatedBest => l10n.suggestionEstimatedBest(filled[0], filled[1]),
      SuggestionNoteKind.rideAgainConfirm => l10n.suggestionRideAgainConfirm(filled[0]),
      SuggestionNoteKind.keepGoing => l10n.suggestionKeepGoing(filled[0], filled[1]),
      SuggestionNoteKind.tryFromBest => l10n.suggestionTryFromBest(filled[0], filled[1]),
      SuggestionNoteKind.rideAgainCheck => l10n.suggestionRideAgainCheck(filled[0]),
      SuggestionNoteKind.rideAndCompare => l10n.suggestionRideAndCompare(filled[0], filled[1]),
      SuggestionNoteKind.levelRideAgain => l10n.suggestionLevelRideAgain(filled[0], filled[1]),
    };
  }
}

String _argText(NoteArg arg, AppLocalizations l10n) => switch (arg) {
  TextArg(:final text) => text,
  SetupArg(:final name) => name ?? l10n.setupUnnamed,
  MoveArg(:final changes) => changes.map((change) => _changeText(change, l10n)).join(', '),
};

/// "Rebound +2", "Lockout On", "Mode Firm".
String _changeText(KnobChange change, AppLocalizations l10n) {
  final (:adjustment, :from, :to) = change;
  final delta = formatValueDelta(from, to, l10n);
  return '${adjustment.name} ${delta ?? to.displayText(l10n)}${delta != null ? adjustment.unitSuffix() : ''}';
}

extension WeatherErrorMessage on WeatherError {
  String message(AppLocalizations l10n) => switch (kind) {
    WeatherErrorKind.noInternet => l10n.weatherErrorNoInternet,
    WeatherErrorKind.timeout => l10n.weatherErrorTimeout,
    WeatherErrorKind.rateLimit => l10n.weatherErrorRateLimit(WeatherService.maxRequestsPerHour, resetTime ?? ''),
    WeatherErrorKind.failed => l10n.weatherErrorFailed,
  };
}

extension GoogleDriveErrorMessage on GoogleDriveError {
  String message(AppLocalizations l10n) => switch (kind) {
    GoogleDriveErrorKind.setupFailed => l10n.driveErrorSetupFailed(detail ?? ''),
    GoogleDriveErrorKind.unknown => l10n.driveErrorUnknown(detail ?? ''),
    GoogleDriveErrorKind.signInCanceled => l10n.driveErrorSignInCanceled,
    GoogleDriveErrorKind.signInInterrupted => l10n.driveErrorSignInInterrupted,
    GoogleDriveErrorKind.signInFailed => l10n.driveErrorSignInFailed(detail ?? ''),
    GoogleDriveErrorKind.platformUnsupported => l10n.driveErrorPlatformUnsupported,
    GoogleDriveErrorKind.reauthRequired => l10n.driveErrorReauthRequired,
    GoogleDriveErrorKind.reauthFailed => l10n.driveErrorReauthFailed(detail ?? ''),
    GoogleDriveErrorKind.api => l10n.driveErrorApi(detail ?? ''),
    GoogleDriveErrorKind.noInternet => l10n.driveErrorNoInternet,
    GoogleDriveErrorKind.syncFailed => l10n.driveErrorSyncFailed(detail ?? ''),
    GoogleDriveErrorKind.authExpired => l10n.driveErrorAuthExpired,
    GoogleDriveErrorKind.backupFailed => l10n.driveErrorBackupFailed(detail ?? ''),
  };
}

extension StravaFailureMessage on StravaFailure {
  String message(AppLocalizations l10n) => switch (kind) {
    StravaErrorKind.serverMessage => detail ?? l10n.stravaErrorSyncFailed,
    StravaErrorKind.syncFailed => detail == null ? l10n.stravaErrorSyncFailed : l10n.stravaErrorSyncFailedDetail(detail!),
    StravaErrorKind.connectionVerifyFailed => l10n.stravaErrorConnectionVerifyFailed,
    StravaErrorKind.backgroundSyncFailed => l10n.stravaErrorBackgroundSyncFailed,
    StravaErrorKind.serverUnreachable => l10n.stravaErrorServerUnreachable,
    StravaErrorKind.noBrowser => l10n.stravaErrorNoBrowser,
    StravaErrorKind.loginFailed => l10n.stravaErrorLoginFailed(detail ?? ''),
    StravaErrorKind.subscriptionRequired => l10n.stravaErrorSubscriptionRequired,
    StravaErrorKind.signInFailed => l10n.stravaErrorSignInFailed(detail ?? ''),
    StravaErrorKind.signInFailedGeneric => l10n.stravaErrorSignInFailedGeneric,
    StravaErrorKind.disconnectFailed => l10n.stravaErrorDisconnectFailed(detail ?? ''),
    StravaErrorKind.fullSyncFailed => l10n.stravaErrorFullSyncFailed(detail ?? ''),
    StravaErrorKind.noInternet => l10n.errorNoInternetRetry,
    StravaErrorKind.authentication => l10n.stravaErrorAuthentication,
    StravaErrorKind.rateLimited => l10n.stravaErrorRateLimited,
  };
}

extension SubscriptionFailureMessage on SubscriptionFailure {
  String message(AppLocalizations l10n) => switch (kind) {
    SubscriptionErrorKind.noPreviousPurchase => l10n.subscriptionErrorNoPreviousPurchase,
    SubscriptionErrorKind.streamFailed => l10n.storeErrorStreamFailed(detail ?? ''),
    SubscriptionErrorKind.initFailed => l10n.subscriptionErrorInitFailed(detail ?? ''),
    SubscriptionErrorKind.entitlementStreamFailed => l10n.subscriptionErrorEntitlementStreamFailed(detail ?? ''),
    SubscriptionErrorKind.plansLoadFailed => l10n.subscriptionErrorPlansLoadFailed(detail ?? ''),
    SubscriptionErrorKind.plansUnavailable => l10n.subscriptionErrorPlansUnavailable,
    SubscriptionErrorKind.storeUnavailable => l10n.storeErrorUnavailable,
    SubscriptionErrorKind.planNotLoaded => l10n.subscriptionErrorPlanNotLoaded,
    SubscriptionErrorKind.purchaseFailed => l10n.subscriptionErrorPurchaseFailed(detail ?? ''),
    SubscriptionErrorKind.restoreFailed => l10n.subscriptionErrorRestoreFailed(detail ?? ''),
    SubscriptionErrorKind.missingTransactionId => l10n.subscriptionErrorMissingTransactionId,
    SubscriptionErrorKind.subscriptionInactive => l10n.subscriptionErrorInactive,
    SubscriptionErrorKind.verifyFailed => l10n.subscriptionErrorVerifyFailed(detail ?? ''),
    SubscriptionErrorKind.noInternet => l10n.errorNoInternetRetry,
    SubscriptionErrorKind.authentication => l10n.subscriptionErrorAuthentication,
  };
}

extension TipFailureMessage on TipFailure {
  String message(AppLocalizations l10n) => switch (kind) {
    TipErrorKind.streamFailed => l10n.storeErrorStreamFailed(detail ?? ''),
    TipErrorKind.storeUnavailable => l10n.storeErrorUnavailable,
    TipErrorKind.initFailed => l10n.tipErrorInitFailed(detail ?? ''),
    TipErrorKind.loadFailed => l10n.tipErrorLoadFailed(detail ?? ''),
    TipErrorKind.tipsUnavailable => l10n.tipErrorTipsUnavailable,
    TipErrorKind.tipNotLoaded => l10n.tipErrorTipNotLoaded,
    TipErrorKind.purchaseFailed => l10n.tipErrorPurchaseFailed(detail ?? ''),
  };
}
