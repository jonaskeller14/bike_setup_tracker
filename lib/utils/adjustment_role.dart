import '../models/adjustment/adjustment.dart';

/// The catalog-side id of what [adjustment] is, e.g. `pressure` or `lsr`, so a
/// setup guide rule can find its adjuster.
///
/// Resolved from the [Adjustment.presetKey] without its `<type>:` prefix, which
/// catalog-built (`fork:lsr`) and template-built (`fork:hsc`) adjusters both
/// carry and which survives renames, else from the slug of the name. `null`
/// when the name has no ASCII letters or digits.
String? adjustmentRole(Adjustment adjustment) {
  final presetKey = adjustment.presetKey;
  if (presetKey != null) {
    final role = presetKey.substring(presetKey.indexOf(':') + 1);
    if (role.isNotEmpty) return role;
  }

  final slug = adjustment.name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), '');
  return slug.isEmpty ? null : slug;
}
