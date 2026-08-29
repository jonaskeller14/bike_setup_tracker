import 'package:flutter/material.dart';

class TaskCaughtUpPlaceholder extends StatelessWidget {
  final String? bikeName;
  final String? nextTaskName;

  const TaskCaughtUpPlaceholder({
    super.key,
    this.bikeName,
    this.nextTaskName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scope = bikeName == null ? 'There are no tasks due right now.' : '$bikeName has no tasks due right now.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 48, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'All caught up',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scope,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (nextTaskName != null) ...[
              const SizedBox(height: 16),
              Text(
                'Next up',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nextTaskName!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
