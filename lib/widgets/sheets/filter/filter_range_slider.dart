import 'package:flutter/material.dart';

/// A range slider under a header row of [title] and a [valueLabel]. The thumbs
/// follow a drag locally and [onChangeEnd] fires on release only, because every
/// filter change re-pages the activities from the database.
class FilterRangeSlider extends StatefulWidget {
  /// Without a title, the value label takes its place at the start of the row.
  final String? title;
  final RangeValues values;
  final double max;
  final int? divisions;

  /// Gets the thumbs during a drag, `null` otherwise, so the label can show the
  /// stored criterion exactly rather than its thumb positions.
  final String Function(RangeValues? dragging) valueLabel;
  final ValueChanged<RangeValues> onChangeEnd;

  /// Shown at the end of the header row.
  final Widget? trailing;

  const FilterRangeSlider({
    super.key,
    this.title,
    required this.values,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChangeEnd,
    this.trailing,
  });

  @override
  State<FilterRangeSlider> createState() => _FilterRangeSliderState();
}

class _FilterRangeSliderState extends State<FilterRangeSlider> {
  RangeValues? _dragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dragging = _dragging;
    final title = widget.title;
    final trailing = widget.trailing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (title != null) ...[
              Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.valueLabel(dragging),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: title == null
                    ? null
                    : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ?trailing,
          ],
        ),
        RangeSlider(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          values: dragging ?? widget.values,
          max: widget.max,
          divisions: widget.divisions,
          onChanged: (values) => setState(() => _dragging = values),
          onChangeEnd: (values) {
            setState(() => _dragging = null);
            widget.onChangeEnd(values);
          },
        ),
      ],
    );
  }
}
