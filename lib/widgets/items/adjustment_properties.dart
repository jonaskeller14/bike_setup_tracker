import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';

typedef _RangeParts = ({String? min, String? max, String? step, String? unit});

class AdjustmentProperties extends StatelessWidget {
  final Adjustment adjustment;
  final bool singleLine;
  final bool compact;
  final Color? color;

  const AdjustmentProperties(
    this.adjustment, {
    super.key,
    this.singleLine = false,
    this.compact = false,
    this.color,
  });

  static const double _font = 12;
  double get _icon => compact ? 12 : 13;
  double get _iconGap => compact ? 3 : 4;
  double get _boundsGap => compact ? 6 : 10;
  double get _spacing => compact ? 4 : 6;
  EdgeInsets get _pad => compact
      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5)
      : const EdgeInsets.symmetric(horizontal: 8, vertical: 3);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chips = _buildChips(
      fgColor: color ?? colorScheme.onSurfaceVariant,
      borderColor: color?.withValues(alpha: 0.4) ?? colorScheme.outlineVariant,
    );

    if (singleLine) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _spacing,
          children: chips,
        ),
      );
    }

    return Wrap(
      spacing: _spacing,
      runSpacing: _spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }

  List<Widget> _buildChips({required Color fgColor, required Color borderColor}) {
    final items = <Widget>[];

    switch (adjustment) {
      case NumericalAdjustment _ || StepAdjustment _ || DurationAdjustment _:
        final p = _rangeParts();
        if (p.step != null) {
          items.add(_iconChip(
            fgColor: fgColor,
            borderColor: borderColor,
            icon: Icons.stairs_outlined,
            text: 'Step ${p.step}',
          ));
        }
        items.add(_boundsChip(fgColor: fgColor, borderColor: borderColor, p: p));
      case final CategoricalAdjustment a:
        items.addAll(a.options.map((option) => _optionChip(
          fgColor: fgColor,
          borderColor: borderColor,
          label: option,
        )));
      case BooleanAdjustment _:
        items.add(_optionChip(fgColor: fgColor, borderColor: borderColor, label: 'On'));
        items.add(_optionChip(fgColor: fgColor, borderColor: borderColor, label: 'Off'));
      case TextAdjustment _:
        items.add(_iconChip(
          fgColor: fgColor,
          borderColor: borderColor,
          icon: Icons.text_fields,
          text: 'Free text',
        ));
    }

    if (adjustment.unit != null) {
      items.add(_iconChip(
        fgColor: fgColor,
        borderColor: borderColor,
        icon: Icons.straighten,
        text: adjustment.unit!,
      ));
    }

    return items;
  }

  /// Extracts formatted min/max/step/unit for the range-style types.
  _RangeParts _rangeParts() {
    switch (adjustment) {
      case final NumericalAdjustment a:
        return (
          min: a.min == double.negativeInfinity ? null : Adjustment.formatValue(a.min),
          max: a.max == double.infinity ? null : Adjustment.formatValue(a.max),
          step: null,
          unit: a.unit,
        );
      case final StepAdjustment a:
        return (
          min: Adjustment.formatValue(a.min),
          max: Adjustment.formatValue(a.max),
          step: a.step != 1 ? a.step.toString() : null,
          unit: a.unit,
        );
      case final DurationAdjustment a:
        return (
          min: a.min == null ? null : Adjustment.formatValue(a.min),
          max: a.max == null ? null : Adjustment.formatValue(a.max),
          step: null,
          unit: a.unit,
        );
      default:
        return (min: null, max: null, step: null, unit: adjustment.unit);
    }
  }

  /// Single chip holding whichever bounds are set: "[⤓ 0  ⤒ 100]", "[⤓ 0]",
  /// "[⤒ 100]", or "[∞ Any value]" when fully unbounded.
  Widget _boundsChip({required Color fgColor, required Color borderColor, required _RangeParts p}) {
    final children = <Widget>[];
    if (p.min != null) {
      children.addAll([
        Icon(Icons.vertical_align_bottom, size: _icon, color: fgColor),
        SizedBox(width: _iconGap),
        Text(p.min!, style: TextStyle(color: fgColor, fontSize: _font)),
      ]);
    }
    if (p.min != null && p.max != null) children.add(SizedBox(width: _boundsGap));
    if (p.max != null) {
      children.addAll([
        Icon(Icons.vertical_align_top, size: _icon, color: fgColor),
        SizedBox(width: _iconGap),
        Text(p.max!, style: TextStyle(color: fgColor, fontSize: _font)),
      ]);
    }
    if (children.isEmpty) {
      children.addAll([
        Icon(Icons.all_inclusive, size: _icon, color: fgColor),
        SizedBox(width: _iconGap),
        Text('Any value', style: TextStyle(color: fgColor, fontSize: _font)),
      ]);
    }
    return _chip(
      borderColor: borderColor,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  /// Bordered chip wrapping an icon + text (e.g. "[⤓ 0]" or "[📏 mm]").
  Widget _iconChip({
    required Color fgColor,
    required Color borderColor,
    required IconData icon,
    required String text,
  }) {
    return _chip(
      borderColor: borderColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _iconGap,
        children: [
          Icon(icon, size: _icon, color: fgColor),
          Text(text, style: TextStyle(color: fgColor, fontSize: _font)),
        ],
      ),
    );
  }

  /// Bordered chip wrapping a single text label (categorical options, ...).
  Widget _optionChip({required Color fgColor, required Color borderColor, required String label}) {
    return _chip(
      borderColor: borderColor,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fgColor, fontSize: _font),
      ),
    );
  }

  /// Shared bordered-chip container so every chip keeps the same height/shape.
  Widget _chip({required Color borderColor, required Widget child}) {
    return Container(
      padding: _pad,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
