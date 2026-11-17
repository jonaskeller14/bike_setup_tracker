import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/setup.dart';
import '../models/strava/activity_timeline.dart';
import '../theme.dart';
import 'empty_state_placeholder2.dart';
import 'items/feedback_list_tile.dart';
import 'items/setup_tile.dart';

/// The ride as a timeline: a dashed line up to the start, the ride itself in
/// Strava orange, and a dashed line on to feedback written after the end.
class StravaActivityTimeline extends StatelessWidget {
  final ActivityTimeline timeline;
  final VoidCallback? onAddSetup;

  /// Replaces the missing-setup placeholder's hint, e.g. why no setup can be added.
  final String? addSetupHint;

  const StravaActivityTimeline({super.key, required this.timeline, this.onAddSetup, this.addSetupHint});

  static const double _nodeSize = 22;

  /// Where a row's node sits, level with the first line of its contents.
  static double _nodeCenterOf(ActivityTimelineItem item) => switch (item) {
    ActivitySetupItem() => 20,
    ActivityFeedbackItem() => 18,
    ActivityMissingSetupItem() || ActivityStartItem() || ActivityEndItem() => _nodeSize / 2,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = timeline.items;
    // Pre-blended: translucent dashes double up where neighbouring connectors' square caps overlap.
    final offRideColor = Color.alphaBlend(colorScheme.outline.withValues(alpha: 0.6), colorScheme.surface);
    final multiDay = !_sameLocalDay(timeline.activity.startDateLocal, timeline.activity.endDateLocal);

    Widget rideDot(IconData icon) => DotIndicator(
      size: _nodeSize,
      color: EntityColors.strava,
      child: Icon(icon, size: 13, color: EntityColors.onStrava),
    );

    Widget indicator(int index, ActivityTimelineItem item) => switch (item) {
      ActivityMissingSetupItem() => OutlinedDotIndicator(
        size: 14,
        borderWidth: 3,
        color: offRideColor,
        backgroundColor: colorScheme.surface,
      ),
      // Coloured like the line it sits on, which runs on behind it.
      ActivitySetupItem() || ActivityFeedbackItem() => DotIndicator(
        size: 14,
        color: timeline.isRideSegmentBelow(index) ? EntityColors.strava : offRideColor,
      ),
      ActivityStartItem() => rideDot(timeline.activity.sportType.getIconData()),
      ActivityEndItem() => rideDot(Icons.sports_score),
    };

    // The line between rows [index] and [index] + 1.
    Widget connector(int index) => timeline.isRideSegmentBelow(index)
        ? const SolidLineConnector(thickness: 4, color: EntityColors.strava)
        : const DashedLineConnector();

    return TimelineTheme(
      data: TimelineThemeData(connectorTheme: ConnectorThemeData(thickness: 3, color: offRideColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in items.indexed)
            // Not timelines_plus' tiles: they size the line with IntrinsicHeight,
            // which the LayoutBuilder inside SetupTile cannot answer. Here the
            // contents give the height and the line just fills it. Each row draws
            // the line into its node and out of it, so a line never starts above
            // the first node or leaves a gap before the next one.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: switch (item) {
                    ActivitySetupItem() || ActivityFeedbackItem() => const EdgeInsets.only(
                      left: _nodeSize + 8,
                      right: 16,
                      bottom: 8,
                    ),
                    _ => const EdgeInsets.only(left: _nodeSize + 12, right: 16, bottom: 16),
                  },
                  child: _contents(context, item, multiDay: multiDay),
                ),
                if (index > 0)
                  Positioned(
                    left: 0,
                    // Overlaps the row above by a pixel, so fractional row heights leave no seam.
                    top: -1,
                    height: _nodeCenterOf(item) + 1,
                    width: _nodeSize,
                    child: connector(index - 1),
                  ),
                if (index < items.length - 1)
                  Positioned(left: 0, top: _nodeCenterOf(item), bottom: 0, width: _nodeSize, child: connector(index)),
                Positioned(
                  left: 0,
                  top: _nodeCenterOf(item) - _nodeSize / 2,
                  // One width for all nodes keeps the line straight through them.
                  child: SizedBox.square(
                    dimension: _nodeSize,
                    child: Center(child: indicator(index, item)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _contents(BuildContext context, ActivityTimelineItem item, {required bool multiDay}) => switch (item) {
    ActivityMissingSetupItem() => EmptyStatePlaceholder2(
      iconData: Setup.iconData,
      title: context.l10n.stravaActivityNoSetupBeforeTitle,
      subtitle: addSetupHint ?? context.l10n.stravaActivityNoSetupsSubtitle,
      onTap: onAddSetup,
    ),
    ActivitySetupItem(:final setup) => _EntryCard(
      child: SetupTile(
        setupId: setup.id,
        onTap: null,
        stravaActivity: timeline.activity,
        showDate: !_sameLocalDay(setup.datetimeLocal, timeline.activity.startDateLocal),
      ),
    ),
    ActivityFeedbackItem(:final feedback) => _EntryCard(
      child: FeedbackListTile(
        feedback: feedback,
        showBike: false,
        showDate: !_sameLocalDay(feedback.dateTimeLocal, timeline.activity.startDateLocal),
      ),
    ),
    ActivityStartItem() => _RideMarkContents(
      title: context.l10n.stravaActivityTimelineStart,
      dateTimeLocal: timeline.activity.startDateLocal,
      showDate: multiDay,
    ),
    ActivityEndItem() => _RideMarkContents(
      title: context.l10n.stravaActivityTimelineEnd,
      dateTimeLocal: timeline.activity.endDateLocal,
      showDate: multiDay,
    ),
  };
}

bool _sameLocalDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Flat: the card's fill sets an entry apart without a shadow or outline.
class _EntryCard extends StatelessWidget {
  final Widget child;

  const _EntryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      // Rounds the InkWell and the current-setup bar.
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// The page header already shows the start date, so only a ride spanning days
/// repeats it here.
class _RideMarkContents extends StatelessWidget {
  final String title;
  final DateTime dateTimeLocal;
  final bool showDate;

  const _RideMarkContents({required this.title, required this.dateTimeLocal, required this.showDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appSettings = context.watch<AppSettings>();
    final localeName = context.l10n.localeName;
    final time = DateFormat(appSettings.timeFormat, localeName).format(dateTimeLocal);
    final when = showDate ? "${DateFormat(appSettings.dateFormat, localeName).format(dateTimeLocal)} • $time" : time;
    return Padding(
      // Centres the line on the node.
      padding: const EdgeInsets.only(top: 1),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: when,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
    );
  }
}
