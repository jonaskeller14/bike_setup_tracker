import '../models/adjustment/adjustment.dart';

/// Whether [preset] has already been turned into one of [existingAdjustments].
///
/// Matched by name rather than by [Adjustment.presetKey] alone: a preset-derived
/// adjustment that the user renamed carries different semantics, so its preset
/// stays on offer. A non-null `presetKey` must agree too, so a same-named
/// adjustment from another preset does not consume this one.
bool isAdjustmentPresetConsumed(Adjustment preset, Iterable<Adjustment> existingAdjustments) {
  final presetName = preset.name.trim().toLowerCase();
  return existingAdjustments.any((adjustment) =>
      adjustment.name.trim().toLowerCase() == presetName &&
      (adjustment.presetKey == null || adjustment.presetKey == preset.presetKey));
}
