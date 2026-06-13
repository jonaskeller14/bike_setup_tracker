import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps [child] and, when [highlighted] is true, plays a one-shot
/// "flash & fade" pulse on first build to draw the eye to the row
/// (e.g. when navigating to a specific task entry). After the pulse
/// settles the child renders in its normal state, so it is not mistaken
/// for a persistent selection.
///
/// When [highlighted] is false this is a transparent pass-through, so it
/// is safe to wrap every item in a list.
class FlashHighlight extends StatefulWidget {
  final bool highlighted;
  final Widget child;

  /// Tint colour of the flash. Defaults to orange (matching the
  /// "unsaved change" accent used elsewhere in the app).
  final Color? color;

  /// Total duration of the pulse animation.
  final Duration duration;

  /// Number of flashes before settling.
  final int pulseCount;

  /// Peak opacity of the tint at each flash. Kept low so the flash reads
  /// as a soft glow rather than a solid orange block.
  final double maxOpacity;

  /// Corner radius of the highlight overlay.
  final double borderRadius;

  const FlashHighlight({
    super.key,
    required this.highlighted,
    required this.child,
    this.color,
    this.duration = const Duration(milliseconds: 1200),
    this.pulseCount = 3,
    this.maxOpacity = 0.08,
    this.borderRadius = 8,
  });

  @override
  State<FlashHighlight> createState() => _FlashHighlightState();
}

class _FlashHighlightState extends State<FlashHighlight> with SingleTickerProviderStateMixin {
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

    // Build a sequence of fade-in/fade-out pulses (0 -> max -> 0, repeated).
    final items = <TweenSequenceItem<double>>[];
    for (var i = 0; i < widget.pulseCount; i++) {
      items.add(TweenSequenceItem(
        tween: Tween(begin: 0.0, end: widget.maxOpacity).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ));
      items.add(TweenSequenceItem(
        tween: Tween(begin: widget.maxOpacity, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ));
    }
    _opacity = TweenSequence(items).animate(controller);

    unawaited(controller.forward());
  }

  @override
  void didUpdateWidget(covariant FlashHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted && _controller == null) {
      setState(_startAnimation);
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
