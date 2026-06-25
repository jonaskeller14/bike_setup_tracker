import 'package:flutter/material.dart';
import '../dashed_border_painter.dart';

Text sheetTitle(BuildContext context, String title) {
  return Text(
    title, 
    style: Theme.of(context).textTheme.titleLarge,
    overflow: TextOverflow.ellipsis,
  );
}

IconButton sheetCloseButton(BuildContext context) {
  return IconButton.filled(
    iconSize: 20, 
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.close), 
  );
}

IconButton sheetEditButton(BuildContext context, {required VoidCallback onPressed}) {
  return IconButton.filled(
    iconSize: 20, 
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    icon: const Icon(Icons.edit), 
  );
}

IconButton sheetBackButton(BuildContext context, {required VoidCallback onPressed}) {
  return IconButton.filled(
    iconSize: 20, 
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    icon: const BackButtonIcon(), 
  );
}

class StravaSheetHeader extends StatelessWidget {
  const StravaSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          spacing: 6,
          children: [
            // Strava Brand Orange
            const Icon(Icons.cloud_off, color: Color(0xFFFC4C02)),
            sheetTitle(context, 'Strava'),
          ],
        ),
        sheetCloseButton(context),
      ],
    );
  }
}

class SheetFilterEmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;

  const SheetFilterEmptyHint({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: colors.outlineVariant,
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 24,
          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        title: Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        subtitle: hint != null
            ? Text(
                hint!,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              )
            : null,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
