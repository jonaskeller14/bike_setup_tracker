import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:intl/intl.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../repositories/app_repository.dart';
import '../models/app_settings.dart';

class DisplayInstallationTimeline extends StatelessWidget {
  final Component component;
  
  const DisplayInstallationTimeline({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    
    final installations = List<Installation>.from(component.installations)
      ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        indicatorTheme: IndicatorThemeData(
          size: 15.0,
          color: colorScheme.primary,
        ),
        connectorTheme: ConnectorThemeData(
          thickness: 3.0,
          color: colorScheme.outline,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.after,
        itemCount: installations.length,
        contentsBuilder: (context, index) {
          final assignment = installations[index];
          final bikeName = assignment.parent != null
              ? bikes[assignment.parent]?.name ?? 'BIKE NOT FOUND'
              : 'Deinstalled';
          final dateStr = assignment.dateTimeUTC.millisecondsSinceEpoch == 0
              ? 'From beginning'
              : "${DateFormat(appSettings.dateFormat).format(assignment.dateTimeLocal)} ${DateFormat(appSettings.timeFormat).format(assignment.dateTimeLocal)}";

          return Container(
            padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bikeName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: assignment.parent != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: assignment.parent != null
                        ? bikes[assignment.parent]?.name == null ? colorScheme.error : colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  dateStr,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          );
        },
        indicatorBuilder: (context, index) {
          final assignment = installations[index];
          return OutlinedDotIndicator(
            borderWidth: 2.5,
            color: assignment.parent != null
                ? colorScheme.primary
                : colorScheme.outline,
            child: assignment.parent == null
                ? Icon(Icons.close, size: 10, color: colorScheme.outline)
                : null,
          );
        },
        connectorBuilder: (context, index, type) {
          final assignment = installations[index];
          if (assignment.parent == null) {
            return DashedLineConnector(

              color: colorScheme.outline,
            );
          }
          return SolidLineConnector(
            color: colorScheme.primary.withValues(alpha: 0.6),
          );
        },
      ),
    );
  }
}
