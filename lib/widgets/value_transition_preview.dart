import 'package:flutter/material.dart';

/// Recorded value -> migrated value card. A cleared value ([afterValue] `null`)
/// shows in the error color.
class ValueTransitionPreview extends StatelessWidget {
  final IconData icon;
  final String beforeValue;
  final String beforeCaption;
  final String? afterValue;
  final String afterCaption;

  const ValueTransitionPreview({
    super.key,
    required this.icon,
    required this.beforeValue,
    required this.beforeCaption,
    required this.afterValue,
    required this.afterCaption,
  });

  static const String clearedLabel = 'No value';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Side(icon: icon, value: beforeValue, caption: beforeCaption),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: _Side(
              icon: icon,
              value: afterValue ?? clearedLabel,
              caption: afterCaption,
              isError: afterValue == null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final IconData icon;
  final String value;
  final String caption;
  final bool isError;

  const _Side({required this.icon, required this.value, required this.caption, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
