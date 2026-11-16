import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/test_session/session_progress.dart';

/// How far a running test session is from its result: one segment per run and
/// a line that says how many are left.
///
/// Ridden runs are filled, the run that waits for its feedback half, the runs
/// still planned empty, and runs that may or may not come dashed. Segments
/// keep their size while the count changes, so the filled part never moves
/// back. Where they would get too thin, one continuous bar takes over.
class TestSessionProgress extends StatelessWidget {
  static const double height = 8;
  static const double gap = 3;

  /// The narrowest segment whose dashes still read; below it the bar takes over.
  static const double minSegmentWidth = 10;
  static const double maxSegmentWidth = 28;

  /// Fading segments behind the estimate of a session without an upper end.
  static const int openTailSegments = 3;

  final SessionProgress progress;

  const TestSessionProgress({super.key, required this.progress});

  /// Whether [count] segments fit into [width] at [minSegmentWidth] or wider.
  static bool fitsSegments(double width, int count) =>
      count > 0 && (width - gap * (count - 1)) / count >= minSegmentWidth;

  static String label(SessionProgress progress, AppLocalizations l10n) {
    if (progress.isDone) return l10n.testSessionProgressDone;
    if (progress.confirming) return l10n.testSessionProgressConfirm;
    final left = progress.left;
    final max = progress.maxLeft;
    if (left == 0 && (max == null || max == 0)) return l10n.testSessionProgressLastRun;
    if (max == null) return l10n.testSessionProgressAbout(left);
    if (max == left) return l10n.testSessionProgressLeft(left);
    if (left == 0) return l10n.testSessionProgressUpTo(max);
    return l10n.testSessionProgressRange(left, max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = label(progress, context.l10n);

    return Semantics(
      label: '${context.l10n.testSessionRunsCount(progress.ridden)}, $text',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _RunBarPainter(
                  progress: progress,
                  fillColor: theme.colorScheme.primary,
                  trackColor: theme.colorScheme.surfaceContainerHighest,
                  outlineColor: theme.colorScheme.outline,
                ),
              ),
            ),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunBarPainter extends CustomPainter {
  static const Radius _radius = Radius.circular(3);
  static const double _dash = 3;
  static const double _dashGap = 2;

  final SessionProgress progress;
  final Color fillColor;
  final Color trackColor;
  final Color outlineColor;

  _RunBarPainter({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final filled = progress.ridden - (progress.pending ? 1 : 0);
    final planned = progress.ridden + progress.left;
    final possible = planned + ((progress.maxLeft ?? progress.left) - progress.left);
    final count = possible + (progress.isOpenEnded ? TestSessionProgress.openTailSegments : 0);

    if (!TestSessionProgress.fitsSegments(size.width, count)) {
      final share = (filled + (progress.pending ? 0.5 : 0)) / planned;
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)));
      canvas.drawRect(Offset.zero & size, Paint()..color = trackColor);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width * share, size.height), Paint()..color = fillColor);
      canvas.restore();
      return;
    }

    const gap = TestSessionProgress.gap;
    final width = math.min(TestSessionProgress.maxSegmentWidth, (size.width - gap * (count - 1)) / count);
    for (var i = 0; i < count; i++) {
      final segment = RRect.fromRectAndRadius(Rect.fromLTWH(i * (width + gap), 0, width, size.height), _radius);
      if (i < filled) {
        canvas.drawRRect(segment, Paint()..color = fillColor);
      } else if (i < progress.ridden) {
        canvas.save();
        canvas.clipRRect(segment);
        canvas.drawRect(segment.outerRect, Paint()..color = trackColor);
        canvas.drawRect(
          Rect.fromLTWH(segment.left, 0, width / 2, size.height),
          Paint()..color = fillColor,
        );
        canvas.restore();
      } else if (i < planned) {
        canvas.drawRRect(segment, Paint()..color = trackColor);
      } else {
        // The open tail fades out: more runs, nobody knows how many.
        final fade = i < possible ? 1.0 : 1 - (i - possible + 1) / (TestSessionProgress.openTailSegments + 1);
        _drawDashed(canvas, segment, outlineColor.withValues(alpha: outlineColor.a * fade));
      }
    }
  }

  void _drawDashed(Canvas canvas, RRect segment, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()..addRRect(segment.deflate(0.5));
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _dashGap) {
        canvas.drawPath(metric.extractPath(start, math.min(start + _dash, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RunBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}
