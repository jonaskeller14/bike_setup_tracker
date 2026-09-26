import 'package:flutter/material.dart';

/// The tint a timeline row carries while it is part of a bulk selection.
/// Translucent so a row that paints its own background — the current setup's
/// highlight — still reads as such underneath.
class TimelineSelectionFill extends StatelessWidget {
  final bool selected;
  final Widget child;

  const TimelineSelectionFill({
    super.key,
    required this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
      ),
      child: child,
    );
  }
}
