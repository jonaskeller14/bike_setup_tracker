import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/adjustment/adjustment.dart';
import 'adjustment_table_shared.dart';

/// Horizontal padding applied on either side of a cell's content; kept here
/// so the layout pass and [AdjustmentTableCell] always agree on cell width.
const double cellHorizontalPadding = 8;

/// Spacing between the value/change/unit segments inside a cell's value row.
const double cellValueRowSpacing = 4;

/// The text/decoration a cell's value row renders, computed once so both the
/// real widget (AdjustmentTableCell) and the width-measurement pass
/// (measureCellNaturalWidth) always use identical content.
class CellDisplayText {
  final String value;
  final String? change;
  final TextDecoration changeDecoration;

  const CellDisplayText({required this.value, this.change, this.changeDecoration = TextDecoration.none});

  bool get hasChange => change != null;
}

CellDisplayText cellDisplayText(Adjustment adjustment, dynamic value, dynamic previousValue) {
  final bool valueHasChanged = previousValue == null ? false : !adjustmentValuesEqual(value, previousValue);
  String normalize(String s) => s.replaceAll(RegExp(r'\n|\r'), ' ');

  final String valueText = normalize(Adjustment.formatValue(value));
  if (!valueHasChanged) return CellDisplayText(value: valueText);

  String changeText = "";
  TextDecoration changeDecoration = TextDecoration.none;
  switch (adjustment) {
    case BooleanAdjustment():
    case TextAdjustment():
    case CategoricalAdjustment():
      changeDecoration = TextDecoration.lineThrough;
      changeText = Adjustment.formatValue(previousValue);
    case NumericalAdjustment():
    case DurationAdjustment():
    case StepAdjustment():
      if ((value is num && previousValue is num) || (value is Duration && previousValue is Duration)) {
        final dynamic changeValue = value - previousValue;
        changeText = (changeValue is num ? changeValue > 0 : !(changeValue as Duration).isNegative)
            ? "+${Adjustment.formatValue(changeValue)}"
            : Adjustment.formatValue(changeValue);
      } else {
        changeDecoration = TextDecoration.lineThrough;
        changeText = Adjustment.formatValue(previousValue);
      }
  }
  return CellDisplayText(value: valueText, change: normalize(changeText), changeDecoration: changeDecoration);
}

// Keyed by content (role + text + scale), not by adjustment identity — an
// edited adjustment name/value is a different string, so it's automatically
// a cache miss (freshly measured), never a stale hit. Do not key this by
// adjustment.id instead; that would go stale on rename/edit.
final Map<String, double> _textWidthCache = {};

TextStyle _resolveTextStyle(BuildContext context, TextStyle? style) {
  final ambient = DefaultTextStyle.of(context).style;
  return style == null ? ambient : ambient.merge(style);
}

double measureTextWidth({
  required BuildContext context,
  required String role, // disambiguates e.g. "5" as a label vs. as a value
  required String text,
  required TextStyle style,
  required TextDirection textDirection,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final key = '$role|$text|${scaler.scale(100).toStringAsFixed(2)}';
  final cached = _textWidthCache[key];
  if (cached != null) return cached;

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: scaler,
    maxLines: 1,
  )..layout();

  // Simple unbounded-growth safeguard; in practice the number of distinct
  // adjustment values ever displayed in one app session stays small.
  if (_textWidthCache.length > 2000) _textWidthCache.clear();
  return _textWidthCache[key] = painter.width;
}

double measureCellNaturalWidth({
  required BuildContext context,
  required Adjustment adjustment,
  required dynamic value,
  required dynamic previousValue,
  required TextDirection textDirection,
}) {
  final display = cellDisplayText(adjustment, value, previousValue);

  final labelStyle = _resolveTextStyle(
    context, Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0));
  final labelWidth = measureTextWidth(
    context: context, role: 'label', text: adjustment.name, style: labelStyle, textDirection: textDirection);

  final valueStyle = _resolveTextStyle(context,
    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFeatures: [FontFeature.tabularFigures()]));
  var valueRowWidth = measureTextWidth(
    context: context, role: 'value', text: display.value, style: valueStyle, textDirection: textDirection);

  if (display.hasChange) {
    final changeStyle = _resolveTextStyle(context,
      const TextStyle(fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]));
    valueRowWidth += cellValueRowSpacing +
      measureTextWidth(context: context, role: 'change', text: display.change!, style: changeStyle, textDirection: textDirection);
  }
  if (adjustment.unit != null) {
    final unitStyle = _resolveTextStyle(context, null);
    valueRowWidth += cellValueRowSpacing +
      measureTextWidth(context: context, role: 'unit', text: adjustment.unit!.label, style: unitStyle, textDirection: textDirection);
  }

  return math.max(labelWidth, valueRowWidth) + 2 * cellHorizontalPadding;
}

/// One entry positioned within a computed visual line, with its final
/// render-time maxWidth already resolved.
class LaidOutCell {
  final MapEntry<Adjustment, dynamic> entry;
  final double maxWidth;
  const LaidOutCell({required this.entry, required this.maxWidth});
}

/// A small safety margin subtracted from the available row width before
/// computing the 50% per-cell cap, so cells never render flush against the
/// row's edge.
const double _rowWidthSafetyMargin = 2;

/// Packs [entries] into order-preserving visual lines that fit within
/// [availableWidth], applying the "50% cap, except the last cell in its own
/// line may use leftover space" rule. Pure & synchronous — safe to call
/// directly from LayoutBuilder's builder.
List<List<LaidOutCell>> layoutAdjustmentCells({
  required BuildContext context,
  required List<MapEntry<Adjustment, dynamic>> entries,
  required Map<Adjustment, dynamic> previousAdjustmentValues,
  required double availableWidth,
}) {
  if (entries.isEmpty) return const [];

  final textDirection = Directionality.of(context);
  final naturalWidths = [
    for (final e in entries)
      measureCellNaturalWidth(
        context: context,
        adjustment: e.key,
        value: e.value,
        previousValue: previousAdjustmentValues[e.key],
        textDirection: textDirection,
      ),
  ];

  // "generally 50%" — a flat cap on the *full row's* available width, not a
  // per-line 1/N share.
  final halfCap = math.max(0.0, availableWidth - _rowWidthSafetyMargin) / 2;

  // 1) Greedy, order-preserving line packing using capped provisional widths.
  final lineIndices = <List<int>>[];
  var current = <int>[];
  var currentWidth = 0.0;
  for (var i = 0; i < entries.length; i++) {
    final provisional = math.min(naturalWidths[i], halfCap);
    final extra = current.isEmpty ? provisional : AdjustmentTableDivider.width + provisional;
    if (current.isNotEmpty && currentWidth + extra > availableWidth) {
      lineIndices.add(current);
      current = [i];
      currentWidth = provisional;
    } else {
      current.add(i);
      currentWidth += extra;
    }
  }
  if (current.isNotEmpty) lineIndices.add(current);

  // 2) Per-line width assignment: every cell but the line's last gets the
  //    50% cap; the last cell gets the line's leftover slack, never more
  //    than it actually needs.
  return [
    for (final line in lineIndices)
      [
        for (var pos = 0; pos < line.length; pos++)
          if (pos < line.length - 1)
            LaidOutCell(entry: entries[line[pos]], maxWidth: math.min(naturalWidths[line[pos]], halfCap))
          else
            LaidOutCell(
              entry: entries[line[pos]],
              maxWidth: math.max(0.0, math.min(
                naturalWidths[line[pos]],
                availableWidth -
                    [for (var p = 0; p < line.length - 1; p++) math.min(naturalWidths[line[p]], halfCap)]
                        .fold(0.0, (a, b) => a + b) -
                    (line.length - 1) * AdjustmentTableDivider.width,
              )),
            ),
      ],
  ];
}
