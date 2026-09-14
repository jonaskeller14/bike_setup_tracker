import 'package:flutter/services.dart';

/// Input formatter for signed decimal numbers (e.g. "-12.5").
///
/// Android's decimal+signed numeric keyboard can emit the "-" key as a
/// Unicode minus sign variant (U+2212 MINUS SIGN, U+2013 EN DASH, or
/// U+2014 EM DASH) instead of the ASCII hyphen-minus. A plain `-?` regex
/// rejects those glyphs, and `double.tryParse` doesn't recognize them
/// either, so this formatter normalizes them to '-' before filtering.
class SignedDecimalInputFormatter extends TextInputFormatter {
  const SignedDecimalInputFormatter();

  static final RegExp _minusVariants = RegExp('[−–—]');
  static final RegExp _pattern = RegExp(r'^-?\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final normalized = newValue.text.replaceAll(_minusVariants, '-');
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
