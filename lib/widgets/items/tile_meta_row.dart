import 'package:flutter/material.dart';

class TileMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isError;
  final Color? iconColor;
  final bool muted;

  const TileMetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.isError = false,
    this.iconColor,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color textColor = isError
        ? scheme.error
        : scheme.onSurfaceVariant.withValues(alpha: muted ? 0.6 : 0.8);
    final Color glyphColor = isError
        ? scheme.error
        : muted
        ? (iconColor ?? scheme.onSurfaceVariant).withValues(alpha: 0.6)
        : scheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(icon, size: 12, color: glyphColor),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: textColor, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
