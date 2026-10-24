import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/feedback_summary.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../repositories/app_repository.dart';
import '../../utils/feedback_actions.dart';
import '../feedback/open_issues_chips.dart';
import '../notes_text.dart';
import '../sheets/feedback_details.dart';
import 'tile_meta_row.dart';
import 'timeline_selection_fill.dart';

class FeedbackListTile extends StatelessWidget {
  final RideFeedback feedback;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionChanged;
  final bool showDate;
  final bool showBike;

  const FeedbackListTile({
    super.key,
    required this.feedback,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.showDate = true,
    this.showBike = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bike = appRepository.bikes[feedback.bike];
    final activity = feedback.stravaActivityId == null
        ? null
        : appRepository.stravaActivities[feedback.stravaActivityId];
    final resolved = appRepository.resolvedSetupFor(feedback);
    final hasDrift = appRepository.hasSetupDrift(feedback);
    final issues = feedback.orderedIssues;
    final showIssues = feedback.nothingStoodOut || issues.isNotEmpty;
    final hasNotes = feedback.notes?.isNotEmpty ?? false;
    final hasBottomBlock = hasDrift || showIssues || hasNotes;

    final dateText = DateFormat(appSettings.dateFormat).format(feedback.dateTimeLocal);
    final timeText = DateFormat(appSettings.timeFormat).format(feedback.dateTimeLocal);
    final notesColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return TimelineSelectionFill(
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selectionMode
              ? onSelectionChanged
              : () => showFeedbackDetailsSheet(context: context, feedbackId: feedback.id),
          onLongPress: onSelectionChanged,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                selected: selected,
                dense: true,
                visualDensity: VisualDensity.compact,
                titleAlignment: ListTileTitleAlignment.top,
                minLeadingWidth: 0,
                horizontalTitleGap: 8,
                minTileHeight: 0,
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: hasBottomBlock ? 4 : 8),
                leading: const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(RideFeedback.iconData),
                ),
                title: _Verdicts(feedback.verdicts(appRepository.setups)),
                subtitle: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      showDate ? "$dateText • $timeText" : timeText,
                      style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    if (showBike)
                      TileMetaRow(icon: Bike.iconData, text: bike?.name ?? "BIKE NOT FOUND", isError: bike == null),
                    if (activity != null) TileMetaRow(icon: SimpleIcons.strava, text: activity.name),
                  ],
                ),
                trailing: selectionMode
                    ? null
                    : PopupMenuButton<_FeedbackOption>(
                        tooltip: 'Feedback actions',
                        onSelected: (option) => switch (option) {
                          _FeedbackOption.edit => FeedbackActions.editFeedback(context, feedback: feedback),
                          _FeedbackOption.remove => FeedbackActions.removeFeedback(context, feedback: feedback),
                        },
                        itemBuilder: (context) => [
                          for (final option in _FeedbackOption.values)
                            PopupMenuItem(
                              value: option,
                              child: Row(
                                spacing: 10,
                                children: [
                                  Icon(option.iconData, size: 20),
                                  Text(option.label),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              if (hasBottomBlock)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      if (hasDrift)
                        TileMetaRow(
                          icon: Icons.warning_amber_rounded,
                          text:
                              "Originally '${appRepository.setups[feedback.setupId]?.displayName ?? 'a deleted setup'}', "
                              "now '${resolved?.displayName}'",
                          isError: true,
                        ),
                      if (showIssues) OpenIssuesChips(issues: issues),
                      if (hasNotes)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(Icons.notes, size: 12, color: notesColor),
                            ),
                            const SizedBox(width: 2),
                            Expanded(child: NotesText(feedback.notes!, fontSize: 12, color: notesColor)),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line per comparison, each ellipsized on its own; beyond [_maxLines]
/// the rest is counted.
class _Verdicts extends StatelessWidget {
  static const _maxLines = 3;

  final List<String> verdicts;

  const _Verdicts(this.verdicts);

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.bold);
    if (verdicts.isEmpty) return const Text('Feedback', style: style);
    final hidden = verdicts.length - _maxLines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final verdict in verdicts.take(_maxLines))
          Text(verdict, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (hidden > 0)
          Text(
            '+$hidden more',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
      ],
    );
  }
}

enum _FeedbackOption {
  edit('Edit', Icons.edit),
  remove('Remove', Icons.delete);

  final String label;
  final IconData iconData;

  const _FeedbackOption(this.label, this.iconData);
}
