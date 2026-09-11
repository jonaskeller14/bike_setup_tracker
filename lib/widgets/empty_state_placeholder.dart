import 'package:flutter/material.dart';

class EmptyStatePlaceholder extends StatelessWidget {
  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final bool compact;
  final bool isError;

  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.compact = false,
  }) : isError = false;

  const EmptyStatePlaceholder.error({
    super.key,
    this.icon = Icons.error_outline,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh,
    this.compact = false,
  }) : isError = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Color iconColor = isError ? colors.error : colors.onSurfaceVariant.withValues(alpha: 0.35);
    final Color titleColor = isError ? colors.error : colors.onSurfaceVariant.withValues(alpha: 0.7);
    final Color subtitleColor = isError
        ? colors.error.withValues(alpha: 0.7)
        : colors.onSurfaceVariant.withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 32,
          vertical: compact ? 20 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ??
                Icon(
                  icon,
                  size: compact ? 24 : 40,
                  color: iconColor,
                ),
            SizedBox(height: compact ? 8 : 16),
            Text(
              title,
              style: (compact ? textTheme.bodyMedium : textTheme.titleMedium)?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: compact ? 4 : 6),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: compact ? 12 : 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
