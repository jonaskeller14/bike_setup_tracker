import '../models/adjustment/adjustment.dart';
import '../models/adjustment_activity_histogram.dart';
import '../services/component_slot.dart';
import 'adjustment_value_text.dart';
import 'app_localizations.dart';

extension AdjustmentActivityHistogramText on AdjustmentActivityHistogram {
  /// "25 %" for an exact bar, "0 s–15 s" for a range.
  String barLabel(AdjustmentActivityHistogramBar bar, AppLocalizations l10n) {
    if (bar.isRange) return '${_boundary(bar.lowerBound!, l10n)}–${_boundary(bar.upperBound!, l10n)}';
    return _withUnit(bar.exactValue!.displayText(l10n));
  }

  /// [value] is on the [AdjustmentValue.asNum] scale, i.e. seconds for durations.
  String _boundary(num value, AppLocalizations l10n) {
    final AdjustmentValue shown = hasDurationBounds
        ? DurationValue(Duration(microseconds: (value * Duration.microsecondsPerSecond).round()))
        : NumericalValue(value.toDouble());
    return _withUnit(shown.displayText(l10n));
  }

  String _withUnit(String label) => unitLabel == null ? label : '$label $unitLabel';

  /// Where the component of a stacked bar part was mounted.
  String slotLabel(ComponentSlot? slot, AppLocalizations l10n) => slot?.label(l10n) ?? l10n.timelineNotInstalled;

  /// "Tire (Rear wheel): 12 activities" for each stacked part of [bar].
  List<String> segmentLines(AdjustmentActivityHistogramBar bar, AppLocalizations l10n) => [
    for (final segment in bar.segments) l10n.chartHistogramSegment(slotLabel(segment.slot, l10n), segment.activityCount),
  ];
}
