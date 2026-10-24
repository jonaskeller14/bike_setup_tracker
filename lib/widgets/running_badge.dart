import 'dart:async';

import 'package:flutter/material.dart';

/// "Running" with a pulsing red dot, so a live test session reads as live.
/// Holds still with reduced motion.
class RunningBadge extends StatefulWidget {
  const RunningBadge({super.key});

  @override
  State<RunningBadge> createState() => _RunningBadgeState();
}

class _RunningBadgeState extends State<RunningBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<double> _opacity = Tween<double>(begin: 0.2, end: 1).animate(_curve);
  late final Animation<double> _scale = Tween<double>(begin: 0.6, end: 1.15).animate(_curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _opacity,
              child: Icon(Icons.circle, size: 9, color: scheme.error),
            ),
          ),
          Text('Running', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
