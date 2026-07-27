import 'package:flutter/material.dart';

/// Marks the setup that is currently mounted on its bike.
class CurrentSetupBadge extends StatelessWidget {
  const CurrentSetupBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        'Current',
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
