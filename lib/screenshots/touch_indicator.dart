import 'package:flutter/material.dart';

/// Draws a dot under every touch and fades it out on release, so preview
/// recordings show where the flow taps and drags. The simulator's own "Show
/// Single Touches" only follows the mouse in the Simulator window: it isn't
/// part of the recorded framebuffer and ignores Maestro's synthesized touches.
class TouchIndicator extends StatefulWidget {
  const TouchIndicator({super.key, required this.child});

  final Widget child;

  /// In the app's documents directory; its presence turns the dots on.
  static const markerFile = 'screenshot_show_touches';

  static const radius = 22.0;
  static const fadeOut = Duration(milliseconds: 350);

  @override
  State<TouchIndicator> createState() => _TouchIndicatorState();
}

class _TouchIndicatorState extends State<TouchIndicator> with TickerProviderStateMixin {
  final _touches = <int, _Touch>{};

  void _repaint() => setState(() {});

  void _onDown(PointerDownEvent event) {
    _touches.remove(event.pointer)?.dispose();
    final opacity = AnimationController(vsync: this, value: 1, reverseDuration: TouchIndicator.fadeOut)
      ..addListener(_repaint);
    _touches[event.pointer] = _Touch(event.localPosition, opacity);
    _repaint();
  }

  void _onMove(PointerMoveEvent event) {
    _touches[event.pointer]?.position = event.localPosition;
    _repaint();
  }

  void _onRelease(PointerEvent event) {
    final touch = _touches[event.pointer];
    if (touch == null) return;
    touch.opacity.reverse().whenCompleteOrCancel(() {
      if (!mounted || _touches[event.pointer] != touch) return;
      _touches.remove(event.pointer)?.dispose();
      _repaint();
    });
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
  _Touch(this.position, this.opacity);

  Offset position;
  final AnimationController opacity;

  void dispose() => opacity.dispose();
}

class _TouchPainter extends CustomPainter {
  _TouchPainter(this.touches);

  final Map<int, _Touch> touches;

  @override
  void paint(Canvas canvas, Size size) {
    for (final touch in touches.values) {
      final opacity = touch.opacity.value;
      // Sits above the app's theme; a grey fill with a light rim reads on both
      // light and dark content, like the system touch indicator.
      canvas.drawCircle(
        touch.position,
        TouchIndicator.radius,
        Paint()..color = Colors.black.withValues(alpha: 0.35 * opacity),
      );
      canvas.drawCircle(
        touch.position,
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
