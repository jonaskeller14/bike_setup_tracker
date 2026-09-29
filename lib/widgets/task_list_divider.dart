import 'package:flutter/material.dart';

class TaskListDivider extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  final double height;

  const TaskListDivider({super.key, required this.title, required this.count, required this.onTap, required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = '$title ($count)';
    return Semantics(
      button: true,
      header: true,
      label: '$label. Scroll to section',
      excludeSemantics: true,
      onTap: onTap,
      // The color sits on the Material so the ripple paints above it.
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
