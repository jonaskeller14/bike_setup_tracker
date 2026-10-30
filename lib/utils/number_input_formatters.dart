import 'package:flutter/services.dart';

final RegExp _minusVariants = RegExp('[−–—]');
final RegExp _decimalSeparators = RegExp('[.,]');

/// Replaces the minus glyphs a numeric keyboard can emit instead of the ASCII
/// hyphen-minus (U+2212 MINUS SIGN, U+2013 EN DASH, U+2014 EM DASH), which
/// `double.tryParse` doesn't recognize.
String normalizeMinusSign(String input) => input.replaceAll(_minusVariants, '-');

/// Parses a number typed by the user, with `,` or `.` as decimal separator.
///
/// Returns `null` for anything that isn't a number. More than one separator is
/// rejected instead of guessing at grouping, so `1.234,5` is not a number.
///
/// Only for user input: machine data (JSON, YAML, API responses) always uses
/// `.` and stays on `double.tryParse`.
double? parseLocalizedDouble(String input) {
  final normalized = normalizeMinusSign(input.trim());
  if (_decimalSeparators.allMatches(normalized).length > 1) return null;
  return double.tryParse(normalized.replaceFirst(',', '.'));
}

/// Lets a signed number through only while it still matches [_pattern].
///
/// Android's decimal+signed numeric keyboard can emit the "-" key as a
/// Unicode minus sign variant instead of the ASCII hyphen-minus. A plain `-?`
/// regex rejects those glyphs, so this formatter normalizes them to '-' before
/// filtering.
abstract class _SignedInputFormatter extends TextInputFormatter {
  const _SignedInputFormatter();

  RegExp get _pattern;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final normalized = normalizeMinusSign(newValue.text);
    if (!_pattern.hasMatch(normalized)) return oldValue;
    if (normalized == newValue.text) return newValue;
    return newValue.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(
        offset: newValue.selection.end.clamp(0, normalized.length),
      ),
    );
  }
}

/// Input formatter for signed decimal numbers (e.g. "-12.5" or "-12,5").
class SignedDecimalInputFormatter extends _SignedInputFormatter {
  const SignedDecimalInputFormatter();

  static final RegExp _decimalPattern = RegExp(r'^-?\d*[.,]?\d*$');

  @override
  RegExp get _pattern => _decimalPattern;
}

/// Input formatter for signed whole numbers (e.g. "-12").
class SignedIntegerInputFormatter extends _SignedInputFormatter {
  const SignedIntegerInputFormatter();

  static final RegExp _integerPattern = RegExp(r'^-?\d*$');

  @override
  RegExp get _pattern => _integerPattern;
}

/// Input formatter for unsigned decimal numbers (e.g. "12.5" or "12,5").
///
/// Rejects an edit that doesn't fit. `FilteringTextInputFormatter.allow` with
/// an anchored pattern would empty the whole field instead.
class UnsignedDecimalInputFormatter extends TextInputFormatter {
  const UnsignedDecimalInputFormatter();

  static final RegExp _pattern = RegExp(r'^\d*[.,]?\d*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
