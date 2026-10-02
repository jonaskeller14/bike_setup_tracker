import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../models/filters/numeric_range.dart';
import '../../../repositories/app_repository.dart';
import '../../../utils/filter_actions.dart';
import '../../text/sheet_section_title.dart';

class ActivityFilterSection extends StatelessWidget {
  const ActivityFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<AppRepository>().filters;
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
          sliderMax: distanceUnit == 'mi' ? 100 : 150,
          step: 5,
          fromMeters: AppSettings.convertDistanceFromMeters,
          toMeters: AppSettings.convertDistanceToMeters,
          onChanged: (range) => filters.activity = filters.activity.copyWith(distance: range),
        ),
        _RangeFilter(
          label: "Elevation Gain",
          range: filters.activity.elevationGain,
          unit: altitudeUnit,
          sliderMax: altitudeUnit == 'ft' ? 10000 : 3000,
          step: altitudeUnit == 'ft' ? 500 : 100,
          fromMeters: AppSettings.convertElevationFromMeters,
          toMeters: AppSettings.convertElevationToMeters,
          onChanged: (range) => filters.activity = filters.activity.copyWith(elevationGain: range),
        ),
      ],
    );
  }
}

/// A range slider over 0..[sliderMax] in the user's [unit], for a [range] held
/// in metres. Either end of the slider leaves that side of the range open.
class _RangeFilter extends StatefulWidget {
  final String label;
  final NumericRange range;
  final String unit;
  final double sliderMax;
  final double step;
  final double? Function(double? meters, String unit) fromMeters;
  final double? Function(double? value, String unit) toMeters;
  final ValueChanged<NumericRange> onChanged;

  const _RangeFilter({
    required this.label,
    required this.range,
    required this.unit,
    required this.sliderMax,
    required this.step,
    required this.fromMeters,
    required this.toMeters,
    required this.onChanged,
  });

  @override
  State<_RangeFilter> createState() => _RangeFilterState();
}

class _RangeFilterState extends State<_RangeFilter> {
  /// The thumbs during a drag. The filter is written on release only, because
  /// every change re-pages the activities from the database.
  RangeValues? _dragging;

  double _thumb(double? meters, {required double open}) {
    final value = widget.fromMeters(meters, widget.unit);
    if (value == null) return open;
    return ((value / widget.step).round() * widget.step).clamp(0, widget.sliderMax).toDouble();
  }

  NumericRange _toRange(RangeValues values) => NumericRange(
    min: values.start <= 0 ? null : widget.toMeters(values.start, widget.unit),
    max: values.end >= widget.sliderMax ? null : widget.toMeters(values.end, widget.unit),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dragging = _dragging;
    final range = dragging == null ? widget.range : _toRange(dragging);
    final rangeLabel = FilterActions.rangeLabel(range, unit: widget.unit, fromMeters: widget.fromMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                rangeLabel ?? "Any",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        RangeSlider(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          values:
              dragging ??
              RangeValues(_thumb(widget.range.min, open: 0), _thumb(widget.range.max, open: widget.sliderMax)),
          max: widget.sliderMax,
          divisions: (widget.sliderMax / widget.step).round(),
          onChanged: (values) => setState(() => _dragging = values),
          onChangeEnd: (values) {
            setState(() => _dragging = null);
            widget.onChanged(_toRange(values));
          },
        ),
      ],
    );
  }
}
