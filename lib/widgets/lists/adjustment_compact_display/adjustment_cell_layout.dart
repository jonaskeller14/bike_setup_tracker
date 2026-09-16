import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'adjustment_cell.dart';

/// Horizontal padding applied on either side of a cell's content; kept here
/// so the layout pass and the cell widget always agree on cell width.
const double cellHorizontalPadding = 8;

/// Spacing between the value/change/unit segments inside a cell's value row.
const double cellValueRowSpacing = 4;

/// Colour-less text styles of a cell, shared by the cell widget and the width
/// measurement so both always agree.
abstract final class CellTextStyles {
  static TextStyle label(BuildContext context) =>
      (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(fontSize: 10, height: 1.3, letterSpacing: 0);

  static const TextStyle value = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    height: 1.25,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle change = TextStyle(fontSize: 10, height: 1.25, fontFeatures: [FontFeature.tabularFigures()]);

  static const TextStyle unit = TextStyle(fontSize: 12, height: 1.25);
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

double _measureTextWidth({
  required BuildContext context,
  required String role, // disambiguates e.g. "5" as a label vs. as a value
  required String text,
  required TextStyle style,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final key = '$role|$text|${scaler.scale(100).toStringAsFixed(2)}';
  final cached = _textWidthCache[key];
  if (cached != null) return cached;

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    maxLines: 1,
  )..layout();

  // Simple unbounded-growth safeguard; in practice the number of distinct
  // adjustment values ever displayed in one app session stays small.
  if (_textWidthCache.length > 2000) _textWidthCache.clear();
  return _textWidthCache[key] = painter.width;
}

/// The width a cell needs to show its label and value line without scrolling.
double measureCellNaturalWidth(BuildContext context, AdjustmentCell cell) {
  final display = cell.displayText;

  final labelWidth = _measureTextWidth(
    context: context,
    role: 'label',
    text: cell.adjustment.name,
    style: _resolveTextStyle(context, CellTextStyles.label(context)),
  );

  var valueRowWidth = _measureTextWidth(
    context: context,
    role: 'value',
    text: display.value,
    style: _resolveTextStyle(context, CellTextStyles.value),
  );
  if (display.hasChange) {
    valueRowWidth += cellValueRowSpacing +
        _measureTextWidth(
          context: context,
          role: 'change',
          text: display.change!,
          style: _resolveTextStyle(context, CellTextStyles.change),
        );
  }
  final unit = cell.adjustment.unit;
  if (unit != null) {
    valueRowWidth += cellValueRowSpacing +
        _measureTextWidth(
          context: context,
          role: 'unit',
          text: unit.label,
          style: _resolveTextStyle(context, CellTextStyles.unit),
        );
  }

  return math.max(labelWidth, valueRowWidth) + 2 * cellHorizontalPadding;
}

/// The widest a cell may be while packing rows: half a row, so any two cells
/// can always share one. Rows are stretched afterwards, so a capped cell
/// regains width whenever its row has room.
double cellWidthCap({required double rowWidth, required double spacing}) =>
    math.max(0.0, (rowWidth - spacing) / 2);

/// Splits cells of the given [widths] into order-preserving rows that fit
/// [rowWidth]. Uses the fewest rows a greedy wrap would need, then picks the
/// break points that spread the leftover space most evenly, so a full first
/// row is never followed by a single lonely cell when a balanced split exists.
///
/// Returns the cell indices of each row. A cell wider than [rowWidth] gets a
/// row of its own.
List<List<int>> packCellRows({
  required List<double> widths,
  required double rowWidth,
  required double spacing,
}) {
  final n = widths.length;
  if (n == 0) return const [];

  const epsilon = 0.01;
  final prefix = List<double>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    prefix[i + 1] = prefix[i] + widths[i];
  }
  double usedWidth(int start, int end) => prefix[end] - prefix[start] + (end - start - 1) * spacing;
  bool fits(int start, int end) => end - start == 1 || usedWidth(start, end) <= rowWidth + epsilon;
  List<int> range(int start, int end) => [for (var i = start; i < end; i++) i];

  var rowCount = 1;
  for (var start = 0, end = 1; end <= n; end++) {
    if (!fits(start, end)) {
      rowCount++;
      start = end - 1;
    }
  }
  if (rowCount == 1) return [range(0, n)];

  // cost[r][j]: lowest sum of squared slack when the first j cells fill r rows.
  final cost = List.generate(rowCount + 1, (_) => List<double>.filled(n + 1, double.infinity));
  final breakAt = List.generate(rowCount + 1, (_) => List<int>.filled(n + 1, 0));
  cost[0][0] = 0;
  for (var r = 1; r <= rowCount; r++) {
    for (var end = r; end <= n; end++) {
      for (var start = end - 1; start >= r - 1 && fits(start, end); start--) {
        if (cost[r - 1][start] == double.infinity) continue;
        final slack = math.max(0.0, rowWidth - usedWidth(start, end));
        final candidate = cost[r - 1][start] + slack * slack;
        // Scanning from the latest start, `<` breaks ties towards fuller
        // earlier rows, like a regular wrap.
        if (candidate < cost[r][end] - epsilon) {
          cost[r][end] = candidate;
          breakAt[r][end] = start;
        }
      }
    }
  }

  final rows = <List<int>>[];
  for (var r = rowCount, end = n; r > 0; r--) {
    final start = breakAt[r][end];
    rows.insert(0, range(start, end));
    end = start;
  }
  return rows;
}
