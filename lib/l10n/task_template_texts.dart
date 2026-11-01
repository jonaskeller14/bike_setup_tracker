import 'app_localizations.dart';

/// The name and note of a generic task template (`lib/utils/task_presets.dart`)
/// in the language of [l10n], by its key. The template keeps the English text
/// as the fallback; a rule created from it stores the translation as written.
/// `null` for a key without a translation, such as a brand-only template.
({String name, String? notes})? taskTemplateTexts(String key, AppLocalizations l10n) => switch (key) {
  'wheel:spoke_tension' => (
    name: l10n.taskTemplateWheelSpokeTensionName,
    notes: l10n.taskTemplateWheelSpokeTensionNotes,
  ),
  'wheel:hub_bearing' => (name: l10n.taskTemplateWheelHubBearingName, notes: l10n.taskTemplateWheelHubBearingNotes),
  'chain:wear_check' => (name: l10n.taskTemplateChainWearCheckName, notes: l10n.taskTemplateChainWearCheckNotes),
  'chain:replace' => (name: l10n.taskTemplateChainReplaceName, notes: null),
  'chain:lube' => (name: l10n.taskTemplateChainLubeName, notes: null),
  'cassette:wear_check' => (
    name: l10n.taskTemplateCassetteWearCheckName,
    notes: l10n.taskTemplateCassetteWearCheckNotes,
  ),
  'fork:lower_leg_service' => (
    name: l10n.taskTemplateForkLowerLegServiceName,
    notes: l10n.taskTemplateForkLowerLegServiceNotes,
  ),
  'fork:full_service' => (name: l10n.taskTemplateForkFullServiceName, notes: l10n.taskTemplateForkFullServiceNotes),
  'shock:air_can_service' => (
    name: l10n.taskTemplateShockAirCanServiceName,
    notes: l10n.taskTemplateShockAirCanServiceNotes,
  ),
  'shock:full_service' => (name: l10n.taskTemplateShockFullServiceName, notes: l10n.taskTemplateShockFullServiceNotes),
  'brake_pad:wear_check' => (
    name: l10n.taskTemplateBrakePadWearCheckName,
    notes: l10n.taskTemplateBrakePadWearCheckNotes,
  ),
  'brake:bleed' => (name: l10n.taskTemplateBrakeBleedName, notes: l10n.taskTemplateBrakeBleedNotes),
  'tire:sealant' => (name: l10n.taskTemplateTireSealantName, notes: l10n.taskTemplateTireSealantNotes),
  'headset:service' => (name: l10n.taskTemplateHeadsetServiceName, notes: null),
  'bb:play_check' => (name: l10n.taskTemplateBbPlayCheckName, notes: l10n.taskTemplateBbPlayCheckNotes),
  'seatpost:service' => (name: l10n.taskTemplateSeatpostServiceName, notes: null),
  'frame:pivot_bearings' => (
    name: l10n.taskTemplateFramePivotBearingsName,
    notes: l10n.taskTemplateFramePivotBearingsNotes,
  ),
  'frame:bolt_torque' => (name: l10n.taskTemplateFrameBoltTorqueName, notes: l10n.taskTemplateFrameBoltTorqueNotes),
  'shift_cable:replace' => (name: l10n.taskTemplateShiftCableReplaceName, notes: null),
  _ => null,
};
