import 'dart:convert';

/// Safely extracts a numerical (double) value from a stored [raw] string,
/// returning null for non-numeric/unparseable rows (which callers leave
/// untouched). Handles both the JSON encoding and legacy plain-number strings,
/// and never throws on a type mismatch (unlike `AdjustmentValue.decode`).
double? decodeNumericalValueOrNull(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is num) return decoded.toDouble();
  } on FormatException {
    // Non-JSON legacy value — fall through to a plain parse.
  }
  return double.tryParse(raw);
}
