import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';

/// What a map pin stands for; decides its colour in a cluster bubble.
enum MapPinKind { setup, activity, feedback }

/// A cluster marker that remembers its [kind], which the cluster builder only
/// sees as a plain [Marker].
class MapPinMarker extends Marker {
  final MapPinKind kind;

  /// Everything the pin shows besides [kind] and its point, compared by `==`.
  final Object look;

  const MapPinMarker({
    required this.kind,
    required this.look,
    required super.point,
    required super.child,
    required super.width,
    required super.height,
    required super.alignment,
  });

  /// Whether [a] and [b] draw the same pins in the same order, so [b] can stay
  /// on the map in place of [a].
  static bool showSame(List<Marker> a, List<Marker> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final (x, y) = (a[i], b[i]);
      if (x is! MapPinMarker || y is! MapPinMarker) return false;
      if (x.kind != y.kind || x.point != y.point || x.look != y.look) return false;
    }
    return true;
  }

  /// How many of [markers] there are of each kind; kinds without one are left out.
  static Map<MapPinKind, int> countByKind(List<Marker> markers) {
    final counts = <MapPinKind, int>{};
    for (final marker in markers) {
      if (marker is MapPinMarker) counts.update(marker.kind, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

/// Splits a full turn among [counts] in proportion, but never gives a positive
/// count less than [minSweep], so a single pin among many stays visible.
@visibleForTesting
List<double> donutSweeps(List<int> counts, {double minSweep = math.pi / 9}) {
  final sweeps = List<double>.filled(counts.length, 0);
  final clamped = <int>{};
  // Clamping one segment shrinks the others, which can push another one under
  // the minimum, so repeat until nothing new is clamped.
  var changed = true;
  while (changed) {
    changed = false;
    final free = 2 * math.pi - minSweep * clamped.length;
    var freeCount = 0;
    for (var i = 0; i < counts.length; i++) {
      if (!clamped.contains(i) && counts[i] > 0) freeCount += counts[i];
    }
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] <= 0) continue;
      if (clamped.contains(i)) {
        sweeps[i] = minSweep;
        continue;
      }
      sweeps[i] = free * counts[i] / freeCount;
      if (sweeps[i] < minSweep) {
        clamped.add(i);
        changed = true;
      }
    }
  }
  return sweeps;
}

/// Round badge showing how many pins a map cluster contains, ringed by one
/// segment per kind, sized by how many of its pins are of that kind.
class MapClusterBubble extends StatelessWidget {
  final Map<MapPinKind, int> counts;

  const MapClusterBubble({super.key, required this.counts});

  int get count => counts.values.fold(0, (sum, count) => sum + count);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kinds = [
      for (final kind in MapPinKind.values)
        if ((counts[kind] ?? 0) > 0) kind,
    ];
    final sweeps = donutSweeps([for (final kind in kinds) counts[kind]!]);
    return Semantics(
      label: context.l10n.mapClusterSemantics(count),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: scheme.shadow.withValues(alpha: 0.26),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _DonutPainter(
            segments: [for (var i = 0; i < kinds.length; i++) (sweeps[i], _colorOf(kinds[i], theme))],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(_DonutPainter.ringWidth + 1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count.toString(),
                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorOf(MapPinKind kind, ThemeData theme) => switch (kind) {
    MapPinKind.setup => EntityColors.of(theme).setup,
    MapPinKind.activity => EntityColors.strava,
    MapPinKind.feedback => EntityColors.of(theme).feedback,
  };
}

/// Draws the ring clockwise from the top, with a small gap between segments so
/// they stay apart without relying on colour alone.
class _DonutPainter extends CustomPainter {
  static const double ringWidth = 5;
  static const double _gap = math.pi / 45;

  final List<(double, Color)> segments;

  const _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(ringWidth / 2);
    final gap = segments.length > 1 ? _gap : 0.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;
    var start = -math.pi / 2;
    for (final (sweep, color) in segments) {
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => !listEquals(oldDelegate.segments, segments);
}
