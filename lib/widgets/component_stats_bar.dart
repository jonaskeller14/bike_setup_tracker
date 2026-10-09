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

  /// Minutes are dropped from 100 h on: they are noise at that magnitude and cost width.
  @visibleForTesting
  static String formatDuration(Duration duration, NumberFormat fmt) {
    final hours = '${fmt.format(duration.inHours)}h';
    if (duration.inHours >= 100) return hours;
    return '$hours ${duration.inMinutes.remainder(60)}m';
  }

  /// Switches to a compact form (e.g. 123K) from 100,000 on to keep the bar narrow.
  @visibleForTesting
  static String formatAmount(num value, NumberFormat fmt) {
    final rounded = value.round();
    return rounded.abs() >= 100000 ? NumberFormat.compact().format(rounded) : fmt.format(rounded);
  }

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
              '${formatAmount(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit)!, fmt)} ${appSettings.distanceUnit}',
            ),
            item(
              Icons.terrain,
              '${formatAmount(AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit)!, fmt)} ${appSettings.altitudeUnit}',
            ),
            item(Icons.timer_outlined, formatDuration(stats.movingTime, fmt)),
            item(Icons.repeat, fmt.format(stats.activityCount)),
          ],
        ),
      ),
    );
  }
}
