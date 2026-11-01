import 'package:intl/intl.dart';

final Map<String, NumberFormat> _plainFormats = {};

/// Every adjustment value in a list comes through here, and building a
/// [NumberFormat] parses its pattern.
NumberFormat _plainFormat(String locale) => _plainFormats[locale] ??= NumberFormat('0.#####', locale);

/// [number], a machine-formatted number, with the decimal separator of [locale].
String localizeDecimalSeparator(String number, {required String locale}) =>
    number.replaceFirst('.', _plainFormat(locale).symbols.DECIMAL_SEP);

/// [value] as text in [locale].
///
/// With [fractionDigits] the digits are fixed, like `toStringAsFixed`. Otherwise
/// there are up to five, without trailing zeros.
///
/// Never groups thousands, because this text can end up in a number field and
/// `parseLocalizedDouble` rejects a second separator. Display text that wants
/// grouping uses `NumberFormat.decimalPattern(locale)`.
String formatLocalizedDouble(double value, {int? fractionDigits, required String locale}) => fractionDigits == null
    ? _plainFormat(locale).format(value)
    : localizeDecimalSeparator(value.toStringAsFixed(fractionDigits), locale: locale);

/// The text of a number field holding [value], empty for `null`.
///
/// Keeps every digit, so saving a field the user didn't touch writes the same
/// number back.
String formatEditableDouble(double? value, {required String locale}) =>
    value == null ? '' : localizeDecimalSeparator(value.toString(), locale: locale);
