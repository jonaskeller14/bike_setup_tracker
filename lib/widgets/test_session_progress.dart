import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/test_session/session_progress.dart';

/// How far a running test session is from its result: one segment per run and
/// a line that says how many are left.
///
/// Ridden runs are filled, the run that waits for its feedback half, the runs
/// still planned empty, and runs that may or may not come dashed. Where the
/// segments would get too thin, one continuous bar takes over.
///
/// A change plays once the bar is in view again, so the rider sees what the
/// feedback or the run just added did; the latest run breathes while the
/// session goes on. Everything holds still with reduced motion.
class TestSessionProgress extends StatefulWidget {
  static const double height = 8;
  static const double gap = 3;

  /// The narrowest segment whose dashes still read; below it the bar takes over.
  static const double minSegmentWidth = 10;

  /// Fading segments behind the estimate of a session without an upper end.
  static const int openTailSegments = 3;

  /// Room above and below the bar for the glow of the latest run.
  static const double _glowInset = 4;

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
  State<TestSessionProgress> createState() => _TestSessionProgressState();
}

class _TestSessionProgressState extends State<TestSessionProgress> with TickerProviderStateMixin {
  /// A page that leaves takes about this long to uncover the bar.
  static const Duration _uncover = Duration(milliseconds: 350);

  late final AnimationController _change = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..addStatusListener(_onChangeStatus);

  /// A short rest first, so the eye is on the bar when it moves.
  late final Animation<double> _changeCurve = CurvedAnimation(
    parent: _change,
    curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
  );

  /// The rhythm of `RunningBadge`.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _pulseCurve = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final AnimationController _uncovering = AnimationController(vsync: this, duration: _uncover)
    ..addStatusListener(_onRouteStatus);

  /// What the bar showed before the change that plays; null until the fill-in
  /// on first show has played.
  SessionProgress? _from;

  /// What the bar and the label show, or are changing to.
  late SessionProgress _shown = widget.progress;

  ModalRoute<dynamic>? _route;
  bool _wasCurrent = true;
  bool _reduceMotion = false;

  /// On top, with its own entrance and the exit of whatever covered it over.
  bool get _inView {
    final route = _route;
    if (route == null) return true;
    return route.isCurrent && (route.animation?.isCompleted ?? true) && !_uncovering.isAnimating;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.animation?.removeStatusListener(_onRouteStatus);
      _route = route;
      route?.animation?.addStatusListener(_onRouteStatus);
      _wasCurrent = route?.isCurrent ?? true;
    }
    final current = route?.isCurrent ?? true;
    if (current && !_wasCurrent && !_reduceMotion) unawaited(_uncovering.forward(from: 0));
    _wasCurrent = current;
    _playNext();
  }

  @override
  void didUpdateWidget(covariant TestSessionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _playNext();
  }

  @override
  void dispose() {
    _route?.animation?.removeStatusListener(_onRouteStatus);
    _change.dispose();
    _pulse.dispose();
    _shine.dispose();
    _uncovering.dispose();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status.isCompleted && mounted) setState(_playNext);
  }

  void _onChangeStatus(AnimationStatus status) {
    if (!status.isCompleted || !mounted) return;
    final finished = _shown.isDone && !(_from?.isDone ?? true);
    setState(() {
      _from = _shown;
      // A change that came in meanwhile plays after this one.
      _playNext();
    });
    if (finished) unawaited(_shine.forward(from: 0));
  }

  /// Starts the change to the widget's progress, unless one is playing or the
  /// bar is out of view. Only changes state that the next build picks up.
  void _playNext() {
    final target = widget.progress;
    if (_reduceMotion) {
      _from = _shown = target;
      _change.value = 1;
      _shine.value = 0;
    } else if (!_change.isAnimating && _from != target) {
      // Until the fill-in has played, the label is simply up to date.
      if (_from == null) _shown = target;
      if (_inView) {
        _shown = target;
        unawaited(_change.forward(from: 0));
      }
    }

    if (_reduceMotion || _shown.isDone) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = TestSessionProgress.label(_shown, context.l10n);

    return Semantics(
      label:
          '${context.l10n.testSessionRunsCount(widget.progress.ridden)}, '
          '${TestSessionProgress.label(widget.progress, context.l10n)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            SizedBox(
              height: TestSessionProgress.height,
              // The glow of the latest run reaches past the bar, into the gaps
              // above and below it.
              child: OverflowBox(
                minHeight: TestSessionProgress.height + 2 * TestSessionProgress._glowInset,
                maxHeight: TestSessionProgress.height + 2 * TestSessionProgress._glowInset,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RunBarPainter(
                      from: _from,
                      to: _shown,
                      change: _changeCurve,
                      pulse: _pulseCurve,
                      shine: _shine,
                      fillColor: theme.colorScheme.primary,
                      trackColor: theme.colorScheme.surfaceContainerHighest,
                      outlineColor: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
              layoutBuilder: (current, previous) =>
                  Stack(alignment: AlignmentDirectional.topStart, children: [...previous, ?current]),
              child: Text(
                text,
                key: ValueKey(text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One run of the bar. [start] and [extent] are shares of the bar's width plus
/// one gap, so they don't depend on the width.
class _Segment {
  final double start;
  final double extent;

  /// 1 for a ridden run, 0.5 for the one that waits for its feedback.
  final double fill;
  final double track;
  final double dash;
  final double opacity;

  const _Segment({
    required this.start,
    required this.extent,
    required this.fill,
    required this.track,
    required this.dash,
    this.opacity = 1,
  });
}

/// What the painter draws: the segments, and how much of the continuous bar
/// shows instead of them ([barMix]).
class _BarVisual {
  final List<_Segment> segments;
  final double barMix;
  final double barShare;

  /// The latest run, which breathes.
  final int head;

  const _BarVisual({required this.segments, required this.barMix, required this.barShare, required this.head});

  /// [empty] leaves out the fill: the bar before the fill-in on first show.
  factory _BarVisual.of(SessionProgress progress, double width, {bool empty = false}) {
    final filled = progress.ridden - (progress.pending ? 1 : 0);
    final planned = progress.ridden + progress.left;
    final possible = planned + ((progress.maxLeft ?? progress.left) - progress.left);
    final count = possible + (progress.isOpenEnded ? TestSessionProgress.openTailSegments : 0);
    return _BarVisual(
      segments: [
        for (var i = 0; i < count; i++)
          _Segment(
            start: i / count,
            extent: 1 / count,
            fill: empty || i >= progress.ridden ? 0 : (i < filled ? 1 : 0.5),
            track: i < planned ? 1 : 0,
            // The open tail fades out: more runs, nobody knows how many.
            dash: i < planned
                ? 0
                : (i < possible ? 1 : 1 - (i - possible + 1) / (TestSessionProgress.openTailSegments + 1)),
          ),
      ],
      barMix: TestSessionProgress.fitsSegments(width, count) ? 0 : 1,
      barShare: empty ? 0 : (filled + (progress.pending ? 0.5 : 0)) / planned,
      head: progress.isDone ? -1 : progress.ridden - 1,
    );
  }

  /// Segment i is run i + 1 on both sides. A run only one side has slides in
  /// from (or out to) where it would sit on the other side, past the end of
  /// the bar. Fills that change play one after the other, left to right.
  static _BarVisual lerp(_BarVisual a, _BarVisual b, double t) {
    final (countA, countB) = (a.segments.length, b.segments.length);
    final count = math.max(countA, countB);
    _Segment sideA(int i) => i < countA ? a.segments[i] : b.segments[i];
    _Segment sideB(int i) => i < countB ? b.segments[i] : a.segments[i];
    final changing = [
      for (var i = 0; i < count; i++)
        if (sideA(i).fill != sideB(i).fill) i,
    ];
    double fillAt(int i) {
      final order = changing.indexOf(i);
      if (order < 0) return sideB(i).fill;
      return lerpDouble(sideA(i).fill, sideB(i).fill, (t * changing.length - order).clamp(0, 1))!;
    }

    return _BarVisual(
      segments: [
        for (var i = 0; i < count; i++)
          _Segment(
            start: lerpDouble(i / countA, i / countB, t)!,
            extent: lerpDouble(1 / countA, 1 / countB, t)!,
            fill: fillAt(i),
            track: lerpDouble(sideA(i).track, sideB(i).track, t)!,
            dash: lerpDouble(sideA(i).dash, sideB(i).dash, t)!,
            opacity: lerpDouble(i < countA ? 1 : 0, i < countB ? 1 : 0, t)!,
          ),
      ],
      barMix: lerpDouble(a.barMix, b.barMix, t)!,
      barShare: lerpDouble(a.barShare, b.barShare, t)!,
      head: b.head,
    );
  }
}

class _RunBarPainter extends CustomPainter {
  static const Radius _radius = Radius.circular(3);
  static const double _dash = 3;
  static const double _dashGap = 2;

  /// How far the latest run dims at the low point of its breath.
  static const double _pulseDim = 0.4;
  static const double _glowAlpha = 0.45;
  static const double _glowBlur = 3;

  /// The stretch at the end of the continuous bar that breathes.
  static const double _barHead = 12;

  final SessionProgress? from;
  final SessionProgress to;
  final Animation<double> change;
  final Animation<double> pulse;
  final Animation<double> shine;
  final Color fillColor;
  final Color trackColor;
  final Color outlineColor;

  /// The dashes of the last frame, kept while only the pulse repaints.
  (double width, double t)? _dashesFor;
  List<(Path, double)> _dashes = const [];

  _RunBarPainter({
    required this.from,
    required this.to,
    required this.change,
    required this.pulse,
    required this.shine,
    required this.fillColor,
    required this.trackColor,
    required this.outlineColor,
  }) : super(repaint: Listenable.merge([change, pulse, shine]));

  static Color _faded(Color color, double opacity) => color.withValues(alpha: color.a * opacity);

  @override
  void paint(Canvas canvas, Size size) {
    const height = TestSessionProgress.height;
    final inset = (size.height - height) / 2;
    final width = size.width;
    canvas.translate(0, inset);
    // Runs that slide in or out pass the end of the bar.
    canvas.clipRect(Rect.fromLTRB(0, -inset, width, height + inset));

    final t = change.value;
    final target = _BarVisual.of(to, width);
    final before = from;
    final visual = before == to || t >= 1
        ? target
        : _BarVisual.lerp(
            before == null ? _BarVisual.of(to, width, empty: true) : _BarVisual.of(before, width),
            target,
            t,
          );
    final breath = pulse.value < 0.001 ? 0.0 : pulse.value;
    final headOpacity = 1 - _pulseDim * breath;
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glowBlur);

    Rect rectOf(_Segment segment) => Rect.fromLTWH(
      segment.start * (width + TestSessionProgress.gap),
      0,
      segment.extent * (width + TestSessionProgress.gap) - TestSessionProgress.gap,
      height,
    );

    final segmentsOpacity = 1 - visual.barMix;
    if (segmentsOpacity > 0) {
      for (final (i, segment) in visual.segments.indexed) {
        final opacity = segment.opacity * segmentsOpacity;
        final rect = rectOf(segment);
        if (opacity <= 0 || rect.left >= width) continue;
        final shape = RRect.fromRectAndRadius(rect, _radius);
        if (segment.track > 0 && segment.fill < 1) {
          canvas.drawRRect(shape, Paint()..color = _faded(trackColor, segment.track * opacity));
        }
        if (segment.fill <= 0) continue;

        final isHead = i == visual.head;
        final filled = Rect.fromLTWH(rect.left, 0, rect.width * segment.fill, height);
        if (isHead && breath > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(filled, _radius),
            glow..color = _faded(fillColor, _glowAlpha * breath * opacity),
          );
        }
        final paint = Paint()..color = _faded(fillColor, opacity * (isHead ? headOpacity : 1));
        if (segment.fill >= 1) {
          canvas.drawRRect(shape, paint);
        } else {
          canvas.save();
          canvas.clipRRect(shape);
          canvas.drawRect(filled, paint);
          canvas.restore();
        }
      }
      for (final (dash, opacity) in _dashesOf(visual, width, t, rectOf)) {
        canvas.drawPath(
          dash,
          Paint()
            ..color = _faded(outlineColor, opacity * segmentsOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    final bar = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), const Radius.circular(height / 2));
    if (visual.barMix > 0) {
      final fill = Rect.fromLTWH(0, 0, width * visual.barShare, height);
      final solid = _faded(fillColor, visual.barMix);
      final breathes = visual.head >= 0 && breath > 0 && !fill.isEmpty;
      final headStart = math.max(0.0, fill.width - _barHead);
      if (breathes) {
        canvas.drawRect(
          Rect.fromLTRB(headStart, 0, fill.width, height),
          glow..color = _faded(fillColor, _glowAlpha * breath * visual.barMix),
        );
      }
      canvas.save();
      canvas.clipRRect(bar);
      canvas.drawRect(bar.outerRect, Paint()..color = _faded(trackColor, visual.barMix));
      // One rect, so the stretch that breathes fades in without a seam.
      canvas.drawRect(
        fill,
        breathes
            ? (Paint()
                ..shader = LinearGradient(
                  colors: [solid, solid, _faded(solid, headOpacity)],
                  stops: [0, headStart / fill.width, 1],
                ).createShader(fill))
            : (Paint()..color = solid),
      );
      canvas.restore();
    }

    if (shine.value > 0 && shine.value < 1) {
      final band = width * 0.35;
      final rect = Rect.fromLTWH(lerpDouble(-band, width, shine.value)!, 0, band, height);
      final shapes = Path();
      if (visual.barMix >= 0.5) {
        shapes.addRRect(bar);
      } else {
        for (final segment in visual.segments) {
          shapes.addRRect(RRect.fromRectAndRadius(rectOf(segment), _radius));
        }
      }
      canvas.save();
      canvas.clipPath(shapes);
      // The fill's own colour added on top: lighter in both themes.
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = LinearGradient(
            colors: [_faded(fillColor, 0), _faded(fillColor, 0.6), _faded(fillColor, 0)],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  List<(Path, double)> _dashesOf(_BarVisual visual, double width, double t, Rect Function(_Segment) rectOf) {
    if (_dashesFor == (width, t)) return _dashes;
    _dashesFor = (width, t);
    return _dashes = [
      for (final segment in visual.segments)
        if (segment.dash * segment.opacity > 0 && rectOf(segment).left < width)
          (_dashed(RRect.fromRectAndRadius(rectOf(segment), _radius)), segment.dash * segment.opacity),
    ];
  }

  static Path _dashed(RRect segment) {
    final dashes = Path();
    final outline = Path()..addRRect(segment.deflate(0.5));
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _dashGap) {
        dashes.addPath(metric.extractPath(start, math.min(start + _dash, metric.length)), Offset.zero);
      }
    }
    return dashes;
  }

  @override
  bool shouldRepaint(covariant _RunBarPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}
