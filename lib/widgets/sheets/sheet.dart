import 'package:flutter/material.dart';

import '../dashed_border_painter.dart';
import '../text/section_title.dart';
import '../tooltips/info_tooltip.dart';
import '../tooltips/tooltip_style.dart';

Text sheetTitle(BuildContext context, String title) {
  return Text(
    title, 
    style: Theme.of(context).textTheme.titleLarge,
    overflow: TextOverflow.ellipsis,
  );
}

/// Section label for sheet lists. Paints an opaque background so the section's
/// own rows scroll beneath it while a StickySection keeps it pinned.
Widget sheetSectionHeader(BuildContext context, String title) {
  return Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

/// Sub-header inside a sheet section. [info] is shown in a tap tooltip behind
/// an info icon on the right, styled like [SectionTitle]'s.
class SheetGroupTitle extends StatelessWidget {
  final String title;
  final Widget? info;

  const SheetGroupTitle({super.key, required this.title, this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TooltipStyle.inverse(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.labelLarge, overflow: TextOverflow.ellipsis),
          ),
          if (info case final info?)
            infoTooltip(
              context: context,
              style: style,
              triggerMode: TooltipTriggerMode.tap,
              message: DefaultTextStyle.merge(
                style: theme.textTheme.bodySmall?.copyWith(color: style.foreground),
                child: info,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
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

IconButton sheetActionButton(
  BuildContext context, {
  required IconData icon,
  required String tooltip,
  required VoidCallback? onPressed,
}) {
  return IconButton.filled(
    iconSize: 20,
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    icon: Icon(icon),
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

class SheetFilterEmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback? onTap;

  const SheetFilterEmptyHint({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actionable = onTap != null;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: colors.outlineVariant,
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        trailing: actionable ? const Icon(Icons.arrow_forward_ios, size: 16.0) : null,
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
