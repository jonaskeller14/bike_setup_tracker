import 'package:flutter/material.dart';

/// A selectable option drawn as an outlined card. Use [compact] for nested sub-options.
class RadioOptionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final bool compact;

  const RadioOptionCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // The selected border is 1px thicker; the padding gives that pixel back so the content never shifts.
    final padding = (compact ? 10.0 : 14.0) + (selected ? 0 : 1);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: cs.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: (compact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
