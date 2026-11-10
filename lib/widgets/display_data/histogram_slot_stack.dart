import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../l10n/histogram_text.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment_activity_histogram.dart';

/// Fill patterns that tell the slots of a stacked bar apart, in slot order;
/// they repeat beyond the last one.
enum SlotPattern { solid, diagonal, horizontal, vertical, grid, dots, backDiagonal, crosshatch }

SlotPattern slotPatternAt(int index) => SlotPattern.values[index % SlotPattern.values.length];

/// Fills with [fill] and draws [pattern] over it in [stroke], repeating from
/// the canvas origin so neighbouring parts and legend swatches line up.
///
/// A [Gradient] because that is the only non-solid fill fl_chart stack items
/// and [BoxDecoration] accept.
class SlotPatternFill extends Gradient {
  final SlotPattern pattern;
  final Color fill;
  final Color stroke;

  SlotPatternFill(this.pattern, {required this.fill, required this.stroke}) : super(colors: [fill, stroke]);

  static const double _tileSize = 6;
  static const double _resolution = 4;
  static final Map<(SlotPattern, Color, Color), ui.Image> _tiles = {};
  static final Float64List _tileTransform = Matrix4.diagonal3Values(1 / _resolution, 1 / _resolution, 1).storage;

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final tile = _tiles.putIfAbsent((pattern, fill, stroke), _drawTile);
    return ImageShader(tile, TileMode.repeated, TileMode.repeated, _tileTransform);
  }

  ui.Image _drawTile() {
    const size = _tileSize * _resolution;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = fill);
    final line = Paint()
      ..color = stroke
      ..strokeWidth = _resolution;
    void diagonals({required bool rising}) {
      // Three copies, so the stroke continues across the tile's corners.
      for (final shift in const [-size, 0.0, size]) {
        canvas.drawLine(Offset(shift, rising ? size : 0), Offset(shift + size, rising ? 0 : size), line);
      }
    }

    switch (pattern) {
      case SlotPattern.solid:
        break;
      case SlotPattern.diagonal:
        diagonals(rising: true);
      case SlotPattern.backDiagonal:
        diagonals(rising: false);
      case SlotPattern.crosshatch:
        diagonals(rising: true);
        diagonals(rising: false);
      case SlotPattern.horizontal:
        canvas.drawLine(const Offset(0, size / 2), const Offset(size, size / 2), line);
      case SlotPattern.vertical:
        canvas.drawLine(const Offset(size / 2, 0), const Offset(size / 2, size), line);
      case SlotPattern.grid:
        canvas
          ..drawLine(const Offset(0, size / 2), const Offset(size, size / 2), line)
          ..drawLine(const Offset(size / 2, 0), const Offset(size / 2, size), line);
      case SlotPattern.dots:
        canvas.drawCircle(const Offset(size / 2, size / 2), 1.3 * _resolution, Paint()..color = stroke);
    }
    final picture = recorder.endRecording();
    final tile = picture.toImageSync(size.toInt(), size.toInt());
    picture.dispose();
    return tile;
  }

  /// Patterns switch rather than fade, so an animation does not draw a new
  /// tile for every frame.
  @override
  Gradient? lerpFrom(Gradient? a, double t) => a is SlotPatternFill ? (t < 0.5 ? a : this) : null;

  @override
  Gradient? lerpTo(Gradient? b, double t) => b is SlotPatternFill ? (t < 0.5 ? this : b) : null;

  @override
  Gradient scale(double factor) => this;

  @override
  Gradient withOpacity(double opacity) => SlotPatternFill(
    pattern,
    fill: fill.withValues(alpha: fill.a * opacity),
    stroke: stroke.withValues(alpha: stroke.a * opacity),
  );

  @override
  bool operator ==(Object other) =>
      other is SlotPatternFill && other.pattern == pattern && other.fill == fill && other.stroke == stroke;

  @override
  int get hashCode => Object.hash(pattern, fill, stroke);
}

/// The parts of [bar], one per slot, each in its slot's pattern of [color]
/// with [stroke] lines.
///
/// fl_chart paints the rod's own color underneath, so a stacked rod must be
/// transparent for these to show as given.
List<BarChartRodStackItem> histogramStackItems(
  AdjustmentActivityHistogram histogram,
  AdjustmentActivityHistogramBar bar, {
  required Color color,
  required Color stroke,
}) {
  final items = <BarChartRodStackItem>[];
  var fromY = 0.0;
  for (final segment in bar.segments) {
    final toY = fromY + segment.activityCount;
    final pattern = slotPatternAt(histogram.slots.indexOf(segment.slot));
    items.add(
      BarChartRodStackItem(
        fromY,
        toY,
        null,
        gradient: SlotPatternFill(pattern, fill: color, stroke: stroke),
      ),
    );
    fromY = toY;
  }
  return items;
}

/// Names the slots a stacked histogram is split by, each with its pattern.
class HistogramSlotLegend extends StatelessWidget {
  final AdjustmentActivityHistogram histogram;
  final Color color;
  final Color stroke;
  final TextStyle? style;

  const HistogramSlotLegend({
    super.key,
    required this.histogram,
    required this.color,
    required this.stroke,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final (index, slot) in histogram.slots.indexed)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: SlotPatternFill(slotPatternAt(index), fill: color, stroke: stroke),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: Text(
                  histogram.slotLabel(slot, context.l10n),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
