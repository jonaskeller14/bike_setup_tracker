import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/component_stats.dart';

class ComponentStatsBar extends StatelessWidget {
  final ComponentStats stats;

  /// Shown before the first stat, e.g. a "Σ" / "+" marker.
  final Widget? leading;

  /// Defaults to a neutral grey tint of the surface.
  final Color? backgroundColor;

  /// Defaults to `onSurfaceVariant`; icons use it at reduced opacity.
  final Color? foregroundColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;

  const ComponentStatsBar({
    super.key,
    required this.stats,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize = 11,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = foregroundColor ?? colorScheme.onSurfaceVariant;
    final fmt = NumberFormat.decimalPattern();

    Widget item(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(icon, size: fontSize, color: foreground.withValues(alpha: 0.7)),
        Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: foreground),
        ),
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            ?leading,
            item(
              Icons.route,
              '${fmt.format(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit)!.round())} ${appSettings.distanceUnit}',
            ),
            item(
              Icons.terrain,
              '${fmt.format(AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit)!.round())} ${appSettings.altitudeUnit}',
            ),
            item(
              Icons.timer_outlined,
              '${fmt.format(stats.movingTime.inHours)}h ${stats.movingTime.inMinutes.remainder(60)}m',
            ),
            item(Icons.repeat, fmt.format(stats.activityCount)),
          ],
        ),
      ),
    );
  }
}
