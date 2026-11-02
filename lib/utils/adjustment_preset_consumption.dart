import '../models/adjustment/adjustment.dart';
import 'adjustment_presets.dart';

/// Whether [preset] has already been turned into one of [existingAdjustments].
///
/// Matched by name rather than by [Adjustment.presetKey] alone: a preset-derived
/// adjustment that the user renamed carries different semantics, so its preset
/// stays on offer. The name may be the preset's name in any supported language,
/// so an adjustment added before a language switch still counts. A non-null
/// `presetKey` must agree too, so a same-named adjustment from another preset
/// does not consume this one.
bool isAdjustmentPresetConsumed(Adjustment preset, Iterable<Adjustment> existingAdjustments) {
  final presetNames = adjustmentPresetNameVariants(preset);
  return existingAdjustments.any((adjustment) =>
      presetNames.contains(adjustment.name.trim().toLowerCase()) &&
      (adjustment.presetKey == null || adjustment.presetKey == preset.presetKey));
}
