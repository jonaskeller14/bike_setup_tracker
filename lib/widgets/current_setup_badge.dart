import 'package:flutter/material.dart';

/// Marks the setup that is currently mounted on its bike.
class CurrentSetupBadge extends StatelessWidget {
  final bool compact;

  const CurrentSetupBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 1 : 2),
      child: Text(
        'Current',
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10 : 12,
        ),
      ),
    );
  }
}
