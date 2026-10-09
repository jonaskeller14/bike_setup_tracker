import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../models/filters/numeric_range.dart';
import '../../../models/strava/activity_bounds.dart';
import '../../../repositories/app_repository.dart';
import '../../../utils/filter_actions.dart';
import '../../../utils/slider_bounds.dart';
import '../../text/sheet_section_title.dart';
import 'filter_range_slider.dart';

class ActivityFilterSection extends StatelessWidget {
  const ActivityFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<AppRepository>().filters;
    final bounds = context.select<AppRepository, ActivityBounds>((r) => r.activityBounds);
    final distanceUnit = context.select<AppSettings, String>((s) => s.distanceUnit);
    final altitudeUnit = context.select<AppSettings, String>((s) => s.altitudeUnit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetSectionTitle(title: "Activities"),
        _RangeFilter(
          label: "Distance",
          range: filters.activity.distance,
          unit: distanceUnit,
          track: sliderBounds(
            AppSettings.convertDistanceFromMeters(bounds.maxDistance, distanceUnit),
            fallbackMax: distanceUnit == 'mi' ? 100 : 150,
          ),
          fromMeters: AppSettings.convertDistanceFromMeters,
          toMeters: AppSettings.convertDistanceToMeters,
          onChanged: (range) => filters.activity = filters.activity.copyWith(distance: range),
        ),
        _RangeFilter(
          label: "Elevation Gain",
          range: filters.activity.elevationGain,
          unit: altitudeUnit,
          track: sliderBounds(
            AppSettings.convertElevationFromMeters(bounds.maxElevationGain, altitudeUnit),
            fallbackMax: altitudeUnit == 'ft' ? 10000 : 3000,
          ),
          fromMeters: AppSettings.convertElevationFromMeters,
          toMeters: AppSettings.convertElevationToMeters,
          onChanged: (range) => filters.activity = filters.activity.copyWith(elevationGain: range),
        ),
      ],
    );
  }
}

/// A range slider over 0..`track.max` in the user's [unit], for a [range] held
/// in metres. Either end of the slider leaves that side of the range open.
class _RangeFilter extends StatelessWidget {
  final String label;
  final NumericRange range;
  final String unit;
  final ({double max, double step}) track;
  final double? Function(double? meters, String unit) fromMeters;
  final double? Function(double? value, String unit) toMeters;
  final ValueChanged<NumericRange> onChanged;

  const _RangeFilter({
    required this.label,
    required this.range,
    required this.unit,
    required this.track,
    required this.fromMeters,
    required this.toMeters,
    required this.onChanged,
  });

  double _thumb(double? meters, {required double open}) {
    final value = fromMeters(meters, unit);
    if (value == null) return open;
    return ((value / track.step).round() * track.step).clamp(0, track.max).toDouble();
  }

  NumericRange _toRange(RangeValues values) => NumericRange(
    min: values.start <= 0 ? null : toMeters(values.start, unit),
    max: values.end >= track.max ? null : toMeters(values.end, unit),
  );

  @override
  Widget build(BuildContext context) {
    return FilterRangeSlider(
      title: label,
      values: RangeValues(_thumb(range.min, open: 0), _thumb(range.max, open: track.max)),
      max: track.max,
      divisions: (track.max / track.step).round(),
      valueLabel: (dragging) =>
          FilterActions.rangeLabel(dragging == null ? range : _toRange(dragging), unit: unit, fromMeters: fromMeters) ??
          "Any",
      onChangeEnd: (values) => onChanged(_toRange(values)),
    );
  }
}
