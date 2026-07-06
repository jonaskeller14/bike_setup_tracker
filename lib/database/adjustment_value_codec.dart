import 'dart:convert';

/// Serialises an in-memory adjustment / rating-metric value to the single TEXT
/// column used by `setup_adjustment_values` and `rating_entry_values`.
///
/// Categorical values are always `List<String>` (both single- and multi-select)
/// and are stored as a JSON array so they round-trip unambiguously (a plain
/// `.toString()` would yield `[a, b]`, which cannot be parsed back reliably).
/// Every other value type keeps its existing plain string form.
String encodeAdjustmentValue(dynamic value) =>
    value is List ? jsonEncode(value) : value.toString();

/// Inverse of [encodeAdjustmentValue] for categorical values. Returns the
/// canonical `List<String>`.
///
/// [multiSelect] disambiguates the (rare) case where a legacy single-select
/// value's text is itself valid JSON (e.g. an option literally named `[1,2]`):
/// * multiSelect: values are always written as a JSON array and never had a
///   legacy plain-string form, so a valid array is used directly (any other
///   shape is defensively wrapped).
/// * single-select: the value is exactly one option. The current format is a
///   one-element JSON array; a legacy value is a plain string that may coincide
///   with JSON. Only a single-element array is treated as encoded — every other
///   shape (including a multi-element array) is the one legacy value, verbatim.
List<String> decodeCategoricalValue(String raw, {required bool multiSelect}) {
  final list = _tryDecodeJsonStringList(raw);
  if (multiSelect) return list ?? [raw];
  if (list != null && list.length == 1) return list;
  return [raw];
}

/// Decodes [raw] as a JSON array of strings, or returns null if it is not a
/// JSON array (so the caller can treat it as a legacy plain value).
List<String>? _tryDecodeJsonStringList(String raw) {
  if (!raw.startsWith('[')) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
  } catch (_) {
    // Not valid JSON — treat as a legacy plain value.
  }
  return null;
}
