import 'dart:async';

import 'package:flutter/material.dart';

/// Tints [child] with `primaryContainer` and fades it out each time [flash]
/// changes to a new non-null value, to point at items that were ticked
/// automatically.
///
/// Doesn't flash on its first build, so a group that is expanded after the
/// tick shows its rows plain. The [builder] is always in the tree, also at
/// rest (with a transparent tint), so the child keeps its state.
class DataSelectFlash extends StatefulWidget {
  final Object? flash;
  final Widget Function(BuildContext context, Color tint, Widget child) builder;
  final Widget child;

  const DataSelectFlash({
    super.key,
    required this.flash,
    required this.builder,
    required this.child,
  });

  /// Flashes the background of a [Card] below.
  const DataSelectFlash.card({super.key, required this.flash, required this.child}) : builder = _cardBuilder;

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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant DataSelectFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flash != null && widget.flash != oldWidget.flash) {
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
      builder: (context, child) => widget.builder(
        context,
        color.withValues(alpha: 1 - Curves.easeOut.transform(_controller.value)),
        child!,
      ),
    );
  }
}
