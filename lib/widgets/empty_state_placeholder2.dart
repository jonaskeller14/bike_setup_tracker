import 'package:flutter/material.dart';

import 'dashed_border_painter.dart';

class EmptyStatePlaceholder2 extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String? subtitle;
  final String? errorTitle;
  final String? errorSubtitle;
  final void Function()? onTap;

  const EmptyStatePlaceholder2({
    super.key,
    this.iconData = Icons.add_circle_outline,
    required this.title,
    this.subtitle,
    this.errorTitle,
    this.errorSubtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: errorTitle != null 
              ? Theme.of(context).colorScheme.error 
              : Theme.of(context).colorScheme.outlineVariant,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: 12,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                errorTitle != null ? Icons.warning_amber_rounded : iconData, 
                size: 32, 
                color: errorTitle != null 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
              ),
              const SizedBox(height: 12),
              Text(
                errorTitle ?? title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: errorTitle != null 
                      ? Theme.of(context).colorScheme.error 
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  errorTitle != null 
                      ? errorSubtitle ?? subtitle!
                      : subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: errorTitle != null 
                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.7) 
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}