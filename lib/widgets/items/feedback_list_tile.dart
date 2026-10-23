import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../utils/feedback_actions.dart';

class FeedbackListTile extends StatelessWidget {
  final RideFeedback feedback;

  const FeedbackListTile({super.key, required this.feedback});

  /// "Slightly better than S5", from the overall comparison.
  static String? verdict(RideFeedback feedback, Map<String, Setup> setups) {
    final comparison = feedback.comparisons.firstWhereOrNull((c) => c.aspect is OverallAspect && c.isValid);
    if (comparison == null) return null;
    final reference = setups[comparison.referenceSetupId]?.displayName ?? 'a deleted setup';
    final label = FeedbackVocabulary.overallOutcomeLabels[comparison.outcome]!;
    return comparison.outcome == 0 ? '$label as $reference' : '$label than $reference';
  }

  /// "Front: Harsh · Rear: Low grip", or "Dialled in".
  static String? issuesSummary(RideFeedback feedback) {
    if (feedback.nothingStoodOut) return FeedbackVocabulary.dialledIn;
    final flagged = feedback.issues.map((key) => key.aspect).toSet();
    final issues = EndAspect.values.where(flagged.contains);
    if (issues.isEmpty) return null;
    return issues.map((aspect) => '${aspect.end.label}: ${aspect.attribute.problemLabel}').join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final setups = context.select<AppRepository, Map<String, Setup>>((r) => r.setups);
    final lines = [?verdict(feedback, setups), ?issuesSummary(feedback), ?feedback.notes];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: const Icon(RideFeedback.iconData),
      title: Text(
        '${DateFormat(appSettings.dateFormat).format(feedback.dateTimeLocal)} • '
        '${DateFormat(appSettings.timeFormat).format(feedback.dateTimeLocal)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: lines.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines) Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
      onTap: () => FeedbackActions.editFeedback(context, feedback: feedback),
      trailing: PopupMenuButton<_FeedbackOption>(
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
