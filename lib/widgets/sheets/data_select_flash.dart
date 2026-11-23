import 'dart:async';

import 'package:flutter/material.dart';

/// Tints [child] with `primaryContainer` and fades it out, [pulses] times,
/// each time [flash] changes to a new non-null value, to point at items that
/// were ticked automatically or that Show points at.
///
/// Doesn't flash on its first build, so a group that is expanded after the
/// tick shows its rows plain. The [builder] is always in the tree, also at
/// rest (with a transparent tint), so the child keeps its state.
class DataSelectFlash extends StatefulWidget {
  final Object? flash;
  final int pulses;
  final Widget Function(BuildContext context, Color tint, Widget child) builder;
  final Widget child;

  const DataSelectFlash({
    super.key,
    required this.flash,
    this.pulses = 1,
    required this.builder,
    required this.child,
  });

  /// Flashes the background of a [Card] below.
  const DataSelectFlash.card({super.key, required this.flash, this.pulses = 1, required this.child})
    : builder = _cardBuilder;

  static Widget _cardBuilder(BuildContext context, Color tint, Widget child) {
    final cardTheme = CardTheme.of(context);
    final base = cardTheme.color ?? Theme.of(context).colorScheme.surfaceContainerLow;
    return CardTheme(
      data: cardTheme.copyWith(color: tint.a == 0 ? null : Color.alphaBlend(tint, base)),
      child: child,
    );
  }

  @override
  State<DataSelectFlash> createState() => _DataSelectFlashState();
}

class _DataSelectFlashState extends State<DataSelectFlash> with SingleTickerProviderStateMixin {
  static const _pulse = Duration(milliseconds: 800);

  late final AnimationController _controller = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(covariant DataSelectFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flash != null && widget.flash != oldWidget.flash) {
      _controller.duration = _pulse * widget.pulses;
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Each pulse fades from full tint to none; at rest (value 1) it's none.
        final t = _controller.value * widget.pulses;
        final phase = _controller.value == 1 ? 1.0 : t - t.floor();
        return widget.builder(context, color.withValues(alpha: 1 - Curves.easeOut.transform(phase)), child!);
      },
    );
  }
}
