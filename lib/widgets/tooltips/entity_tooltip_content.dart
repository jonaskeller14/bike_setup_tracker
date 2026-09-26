import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/component_stats.dart';
import '../../services/subscription_service.dart';
import '../notes_text.dart';
import 'tooltip_style.dart';

/// The name/notes/Strava-stats/error content shown inside a component or
/// person tooltip.
class EntityTooltipContent extends StatelessWidget {
  final TooltipStyle style;
  final String name;
  final String? notes;
  final ComponentStats? stats;
  final String? errorDescription;

  const EntityTooltipContent({
    super.key,
    required this.style,
    required this.name,
    this.notes,
    this.stats,
    this.errorDescription,
  });

  Widget _statItem(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(icon, size: 13, color: style.foreground),
        Text(
          label,
          style: TextStyle(color: style.foreground, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();
    final ComponentStats? stats = this.stats;
    final bool showStats = stats != null && appSettings.enableStrava && subscriptionService.hasStravaEntitlement;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          name,
          style: theme.textTheme.labelMedium?.copyWith(
            color: style.foreground,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (notes != null && notes!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3), // tweak to match font size
                child: Icon(Icons.notes, size: 13, color: style.foreground),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: NotesText(notes!, fontSize: 13, color: style.foreground, maxLines: 10),
              ),
            ],
          ),
        if (showStats)
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              _statItem(
                context,
                icon: Icons.route,
                label:
                    '${NumberFormat.decimalPattern().format(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit)!.round())} ${appSettings.distanceUnit}',
              ),
              _statItem(
                context,
                icon: Icons.terrain,
                label:
                    '${NumberFormat.decimalPattern().format(AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit)!.round())} ${appSettings.altitudeUnit}',
              ),
              _statItem(
                context,
                icon: Icons.timer_outlined,
                label: '${NumberFormat.decimalPattern().format(stats.movingTime.inHours)}h ${stats.movingTime.inMinutes.remainder(60)}m',
              ),
              _statItem(context, icon: Icons.repeat, label: '${stats.activityCount}'),
            ],
          ),
        if (errorDescription != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Icon(Icons.error_outline, size: 15, color: colorScheme.onErrorContainer),
                Flexible(
                  child: Text(
                    errorDescription!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
