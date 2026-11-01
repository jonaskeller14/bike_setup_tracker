import '../models/adjustment/adjustment.dart';
import '../utils/localized_number.dart';
import 'app_localizations.dart';

extension AdjustmentValueText on AdjustmentValue {
  /// The value as shown in the language of [l10n], without unit.
  String displayText(AppLocalizations l10n) => switch (this) {
    BooleanValue(:final value) => value ? l10n.valueOn : l10n.valueOff,
    StepValue(:final value) => value.toString(),
    NumericalValue(:final value) => formatLocalizedDouble(value, locale: l10n.localeName),
    TextValue(:final value) => value,
    CategoricalValue(:final options) => _categoricalText(options),
    DurationValue(:final value) => formatDuration(value),
    UnresolvedValue(:final raw) => raw,
  };
}

String _categoricalText(List<String> options) {
  if (options.isEmpty) return '-';
  final counts = <String, int>{};
  for (final option in options) {
    counts[option] = (counts[option] ?? 0) + 1;
  }
  return counts.entries
      .map((entry) => entry.value == 1 ? entry.key : '${entry.key} (${entry.value})')
      .join(Adjustment.multiValueSeparator);
}

/// `hh:mm:ss`, the same in every language.
String formatDuration(Duration value) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(value.inHours)}:${twoDigits(value.inMinutes.remainder(60))}:${twoDigits(value.inSeconds.remainder(60))}';
}
