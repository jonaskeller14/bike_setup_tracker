import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Draws a dot under every touch and fades it out on release, so preview
/// recordings show where the flow taps and drags. The simulator's own "Show
/// Single Touches" only follows the mouse in the Simulator window: it isn't
/// part of the recorded framebuffer and ignores Maestro's synthesized touches.
class TouchIndicator extends StatefulWidget {
  const TouchIndicator({super.key, required this.child, this.jitter = defaultJitter});

  final Widget child;

  /// Maximum distance in each axis between a touch and its dot. Maestro taps
  /// the exact centre of an element; a slightly off-centre dot looks like a
  /// finger. Only the drawing moves, the tap itself stays where the flow put it.
  final double jitter;

  /// In the app's documents directory; its presence turns the dots on.
  static const markerFile = 'screenshot_show_touches';

  static const radius = 22.0;
  static const defaultJitter = 6.0;

  /// Synthesized taps last a few milliseconds, too short to show in a
  /// recording, so every dot stays at least this long and a ring expands from
  /// it meanwhile.
  static const minVisible = Duration(milliseconds: 450);
  static const ringMaxRadius = radius * 2.2;
  static const fadeOut = Duration(milliseconds: 350);

  @override
  State<TouchIndicator> createState() => _TouchIndicatorState();
}

class _TouchIndicatorState extends State<TouchIndicator> with TickerProviderStateMixin {
  final _touches = <int, _Touch>{};
  // Seeded, so every recording of a flow draws its dots at the same offsets.
  final _random = Random(0);

  void _repaint() => setState(() {});

  double _jitter() => (_random.nextDouble() * 2 - 1) * widget.jitter;

  void _onDown(PointerDownEvent event) {
    _touches.remove(event.pointer)?.dispose();
    final ring = AnimationController(vsync: this, duration: TouchIndicator.minVisible)..addListener(_repaint);
    final opacity = AnimationController(vsync: this, value: 1, reverseDuration: TouchIndicator.fadeOut)
      ..addListener(_repaint);
    _touches[event.pointer] = _Touch(event.localPosition, Offset(_jitter(), _jitter()), ring, opacity);
    unawaited(ring.forward());
    _repaint();
  }

  void _onMove(PointerMoveEvent event) {
    _touches[event.pointer]?.position = event.localPosition;
    _repaint();
  }

  Future<void> _onRelease(PointerEvent event) async {
    final touch = _touches[event.pointer];
    if (touch == null) return;
    // Running out the ring keeps a quick tap on screen for minVisible.
    await touch.ring.forward().orCancel.catchError((_) {});
    if (!mounted || _touches[event.pointer] != touch) return;
    await touch.opacity.reverse().orCancel.catchError((_) {});
    if (!mounted || _touches[event.pointer] != touch) return;
    _touches.remove(event.pointer)?.dispose();
    _repaint();
  }

  @override
  void dispose() {
    for (final touch in _touches.values) {
      touch.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onRelease,
      onPointerCancel: _onRelease,
      child: CustomPaint(
        foregroundPainter: _TouchPainter(_touches),
        child: widget.child,
      ),
    );
  }
}

class _Touch {
  _Touch(this.position, this.jitter, this.ring, this.opacity);

  Offset position;
  final Offset jitter;
  final AnimationController ring;
  final AnimationController opacity;

  Offset get center => position + jitter;

  void dispose() {
    ring.dispose();
    opacity.dispose();
  }
}

class _TouchPainter extends CustomPainter {
  _TouchPainter(this.touches);

  final Map<int, _Touch> touches;

  @override
  void paint(Canvas canvas, Size size) {
    for (final touch in touches.values) {
      final opacity = touch.opacity.value;
      final progress = Curves.easeOut.transform(touch.ring.value);
      // Sits above the app's theme; a grey fill with a light rim reads on both
      // light and dark content, like the system touch indicator.
      if (progress < 1) {
        canvas.drawCircle(
          touch.center,
          TouchIndicator.radius + (TouchIndicator.ringMaxRadius - TouchIndicator.radius) * progress,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.black.withValues(alpha: 0.4 * (1 - progress) * opacity),
        );
      }
      canvas.drawCircle(
        touch.center,
        TouchIndicator.radius,
        Paint()..color = Colors.black.withValues(alpha: 0.35 * opacity),
      );
      canvas.drawCircle(
        touch.center,
        TouchIndicator.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.8 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_TouchPainter oldDelegate) => true;
}
