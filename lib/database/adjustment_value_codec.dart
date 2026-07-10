import 'dart:convert';
import '../models/adjustment/adjustment.dart';

String encodeAdjustmentValue(dynamic value) {
  if (value is Duration) return jsonEncode(value.inMicroseconds);
  return jsonEncode(value);
}

/// Safely extracts a numerical (double) value from a stored [raw] string,
/// returning null for non-numeric/unparseable rows (which callers leave
/// untouched). Handles both the JSON encoding and legacy plain-number strings,
/// and never throws on a type mismatch (unlike [decodeAdjustmentValue]).
double? decodeNumericalValueOrNull(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is num) return decoded.toDouble();
  } on FormatException {
    // Non-JSON legacy value — fall through to a plain parse.
  }
  return double.tryParse(raw);
}

/// Inverse of [encodeAdjustmentValue]. The adjustment [type] is required because
/// JSON alone cannot distinguish a step (`int`) from a numerical (`double`), nor
/// a duration (stored as integer microseconds) from a plain number.
dynamic decodeAdjustmentValue(String raw, AdjustmentType type) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    // Non-JSON: a legacy plain value that escaped the v11 migration.
    return decodeLegacyAdjustmentValue(raw, type);
  }
  if (decoded == null) return null;
  switch (type) {
    case AdjustmentType.boolean:
      return decoded as bool;
    case AdjustmentType.numerical:
      return (decoded as num).toDouble();
    case AdjustmentType.step:
      return (decoded as num).toInt();
    case AdjustmentType.categorical:
      // Canonically List<String>. A scalar is a single-select value encoded as a
      // JSON string (multi-select never shipped) — wrap it. The adjustment
      // `type` is what tells this apart from a text value with the same storage.
      return decoded is List
          ? decoded.map((e) => e.toString()).toList()
          : <String>[decoded.toString()];
    case AdjustmentType.text:
      return decoded as String;
    case AdjustmentType.duration:
      return Duration(microseconds: (decoded as num).toInt());
  }
}

/// Reparses a raw value using the pre-v11 per-type format: scalars via
/// `.toString()`, durations via `Duration.toString()`, and **categoricals as a
/// single plain option string**
dynamic decodeLegacyAdjustmentValue(String raw, AdjustmentType type) {
  switch (type) {
    case AdjustmentType.boolean:
      return raw.toLowerCase() == 'true';
    case AdjustmentType.numerical:
      return double.tryParse(raw);
    case AdjustmentType.step:
      return int.tryParse(raw);
    case AdjustmentType.categorical:
      return <String>[raw];
    case AdjustmentType.text:
      return raw;
    case AdjustmentType.duration:
      return DurationAdjustment.tryParseDurationString(raw);
  }
}
