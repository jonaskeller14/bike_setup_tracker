import '../../../models/adjustment/adjustment.dart';
import 'adjustment_display_item.dart';

/// One adjustment value as displayed in the compact adjustment view,
/// classified by how it relates to the previous setup.
sealed class AdjustmentCell {
  final Adjustment adjustment;
  final dynamic value;

  const AdjustmentCell(this.adjustment, this.value);

  factory AdjustmentCell.resolve({
    required Adjustment adjustment,
    required dynamic value,
    required dynamic previousValue,
    bool isError = false,
  }) {
    if (isError) return ErrorCell(adjustment, value);
    if (previousValue == null) return InitialCell(adjustment, value);
    if (adjustmentValuesEqual(value, previousValue)) return ConstantCell(adjustment, value);
    return ChangedCell(adjustment, value, previousValue);
  }

  /// Whether this value differs from the previous setup (kept when collapsed
  /// to changes only).
  bool get isChange => this is InitialCell || this is ChangedCell;

  CellDisplayText get displayText {
    final cell = this;
    if (cell is! ChangedCell) return CellDisplayText(value: _normalize(Adjustment.formatValue(value)));

    final previousValue = cell.previousValue;
    final (valueText, previousText) = value is Duration && previousValue is Duration
        ? _formatDurationPair(value as Duration, previousValue)
        : (Adjustment.formatValue(value), Adjustment.formatValue(previousValue));

    return CellDisplayText(
      value: _normalize(valueText),
      previous: _boundPreviousText(_normalize(previousText), previousValue),
    );
  }
}

/// The longest previous value a cell prints before it is head-truncated; the
/// arrow, the current value and the unit are not counted. Sized so a changed
/// cell carrying a unit still fits `cellWidthCap` at 360 dp: ~11 characters at
/// `CellTextStyles.change` plus the value at `CellTextStyles.value`, the
/// arrow at `CellTextStyles.arrow`, a unit label and the row spacing spend the
/// cap almost exactly.
const int _previousValueCharBudget = 10;

const String _ellipsis = '…';

String _normalize(String s) => s.replaceAll(RegExp(r'\n|\r'), ' ');

String _truncateChars(String text) => text.length <= _previousValueCharBudget
    ? text
    : '${text.substring(0, _previousValueCharBudget).trimRight()}$_ellipsis';

/// Bounds the previous segment to [_previousValueCharBudget] characters. A
/// multi-value list drops whole options at a time so every surviving option
/// stays readable, falling back to character truncation when a single option
/// already exceeds the budget.
String _boundPreviousText(String text, dynamic value) {
  if (text.length <= _previousValueCharBudget) return text;
  if (value is! List) return _truncateChars(text);

  // `formatValue` joins the counted options with `multiValueSeparator`, so
  // splitting on it recovers them; an option containing the separator itself
  // only truncates earlier, never at a wrong place.
  final options = text.split(Adjustment.multiValueSeparator);
  final kept = <String>[];
  var used = 0;
  for (final option in options) {
    final cost = kept.isEmpty ? option.length : Adjustment.multiValueSeparator.length + option.length;
    if (used + cost > _previousValueCharBudget) break;
    kept.add(option);
    used += cost;
  }
  if (kept.isEmpty) return _truncateChars(options.first);
  return '${kept.join(Adjustment.multiValueSeparator)}$_ellipsis';
}

/// Formats both sides of a Duration change, dropping the segments that are
/// zero on *both* sides so the two stay comparable digit for digit. The
/// `h:mm` shape additionally requires hours on both sides, so a leading `0:`
/// never reads as the minutes of an `m:ss`.
(String, String) _formatDurationPair(Duration value, Duration previousValue) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  bool both(bool Function(Duration) test) => test(value) && test(previousValue);

  if (both((d) => d.inHours == 0)) {
    String minutesSeconds(Duration d) => '${d.inMinutes}:${twoDigits(d.inSeconds.remainder(60))}';
    return (minutesSeconds(value), minutesSeconds(previousValue));
  }
  if (both((d) => d.inHours > 0) && both((d) => d.inSeconds.remainder(60) == 0)) {
    String hoursMinutes(Duration d) => '${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}';
    return (hoursMinutes(value), hoursMinutes(previousValue));
  }
  return (Adjustment.formatValue(value), Adjustment.formatValue(previousValue));
}

final class ConstantCell extends AdjustmentCell {
  const ConstantCell(super.adjustment, super.value);
}

final class InitialCell extends AdjustmentCell {
  const InitialCell(super.adjustment, super.value);
}

final class ChangedCell extends AdjustmentCell {
  final dynamic previousValue;

  const ChangedCell(super.adjustment, super.value, this.previousValue);
}

final class ErrorCell extends AdjustmentCell {
  const ErrorCell(super.adjustment, super.value);
}

/// The text a cell's value line renders, shared by the cell widget and the
/// width-measurement pass so both always agree.
class CellDisplayText {
  final String value;

  /// The previous value, shown ahead of [value] on a changed cell and
  /// separated from it by `cellChangeArrow`; null on every other cell.
  final String? previous;

  const CellDisplayText({required this.value, this.previous});

  bool get hasPrevious => previous != null;
}

class AdjustmentCellGroup {
  final AdjustmentDisplayItem owner;
  final List<AdjustmentCell> cells;

  const AdjustmentCellGroup({required this.owner, required this.cells});
}
