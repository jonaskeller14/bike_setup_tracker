import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// A row of a single-choice picker sheet. Each [depth] level moves the icon
/// one step to the right; [showArrow] marks a sub-component by putting the arrow
/// in the last of those steps.
class PickerTile extends StatelessWidget {
  static const double _indent = 18;
  static const double _arrowSize = 14;

  final IconData icon;
  final String label;
  final Color? color;
  final Widget? subtitle;
  final bool enabled;
  final bool selected;

  /// Tint for a picked row that differs from the saved value; `null` leaves the
  /// plain selected look.
  final Color? highlightColor;

  /// The saved value, currently not picked: stays tappable, just marked.
  final bool isPrevious;
  final VoidCallback? onTap;
  final int depth;
  final bool showArrow;

  /// A row below a heading row: smaller title, and only as tall as its content
  /// instead of ListTile's generous two-line minimum.
  final bool compact;

  const PickerTile({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.subtitle,
    this.enabled = true,
    this.selected = false,
    this.highlightColor,
    this.isPrevious = false,
    this.onTap,
    this.depth = 0,
    this.showArrow = false,
    this.compact = false,
  }) : assert(!showArrow || depth > 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final leading = Icon(icon, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      // ListTile paints its tile color on the nearest Material; the sheet's own
      // sits outside the scroll view, so the color would scroll over the header.
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minTileHeight: compact ? 0 : null,
          minVerticalPadding: compact ? 6 : null,
          titleTextStyle: compact ? theme.textTheme.bodyMedium : null,
          contentPadding: EdgeInsetsDirectional.only(start: 8 + (showArrow ? depth - 1 : depth) * _indent, end: 16),
          leading: showArrow
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.subdirectory_arrow_right, size: _arrowSize, color: scheme.onSurfaceVariant),
                    const SizedBox(width: _indent - _arrowSize),
                    leading,
                  ],
                )
              : leading,
          title: Text(
            label,
            style: TextStyle(color: color, fontWeight: selected ? FontWeight.w600 : null),
          ),
          subtitle: subtitle,
          enabled: enabled,
          selected: selected,
          selectedColor: highlightColor == null ? scheme.onSecondaryContainer : scheme.onSurface,
          selectedTileColor: highlightColor?.withValues(alpha: 0.18) ?? scheme.secondaryContainer,
          trailing: selected
              ? Icon(Icons.check, color: highlightColor)
              : isPrevious
                  ? Tooltip(
                      message: context.l10n.previousValueTooltip,
                      child: Icon(Icons.history, color: scheme.onSurfaceVariant),
                    )
                  : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
