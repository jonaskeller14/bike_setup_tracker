import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps [child] and, when [highlighted] is true, plays a subtle *infinite*
/// pulse — the tint gently breathes in and out continuously to keep drawing
/// the eye to the row (e.g. when navigating to a specific task entry).
///
/// Drop-in alternative to [FlashHighlight]: same constructor shape, so you can
/// swap the widget name (and import) to compare the two effects. Unlike the
/// one-shot flash, this never settles while [highlighted] stays true.
///
/// When [highlighted] is false this is a transparent pass-through, so it is
/// safe to wrap every item in a list.
class PulseHighlight extends StatefulWidget {
  final bool highlighted;
  final Widget child;

  /// Tint colour of the pulse. Defaults to orange (matching the
  /// "unsaved change" accent used elsewhere in the app).
  final Color? color;

  /// Duration of a single breathe-in/breathe-out cycle.
  final Duration duration;

  /// Peak opacity of the tint at the top of each pulse. Kept low so the
  /// pulse reads as a soft glow rather than a solid orange block.
  final double maxOpacity;

  /// Corner radius of the highlight overlay.
  final double borderRadius;

  const PulseHighlight({
    super.key,
    required this.highlighted,
    required this.child,
    this.color,
    this.duration = const Duration(milliseconds: 1100),
    this.maxOpacity = 0.08,
    this.borderRadius = 8,
  });

  @override
  State<PulseHighlight> createState() => _PulseHighlightState();
}

class _PulseHighlightState extends State<PulseHighlight> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    final controller = AnimationController(vsync: this, duration: widget.duration);
    _controller = controller;

    // Smoothly breathe between transparent and the peak tint, forever.
    _opacity = Tween(begin: 0.0, end: widget.maxOpacity)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(controller);

    unawaited(controller.repeat(reverse: true));
  }

  @override
  void didUpdateWidget(covariant PulseHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted && _controller == null) {
      setState(_startAnimation);
    } else if (!widget.highlighted && oldWidget.highlighted) {
      setState(() {
        _controller?.dispose();
        _controller = null;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;

    final tint = widget.color ?? Colors.orange;

    return AnimatedBuilder(
      animation: _opacity,
      child: widget.child,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: _opacity.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: child,
        );
      },
    );
  }
}
