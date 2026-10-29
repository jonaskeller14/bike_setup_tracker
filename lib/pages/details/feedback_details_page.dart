import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/custom_issue.dart';
import '../../models/feedback/feedback_comparison.dart';
import '../../models/feedback/feedback_key.dart';
import '../../models/feedback/feedback_summary.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/custom_issue_service.dart';
import '../../theme.dart';
import '../../utils/feedback_actions.dart';
import '../../utils/map_actions.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/feedback/open_issues_chips.dart';
import '../../widgets/items/context_location_weather_card.dart';
import '../../widgets/items/context_meta_card.dart';
import '../../widgets/map_pins.dart';
import '../../widgets/sheets/setup_details.dart';
import '../../widgets/sheets/sheet.dart';
import '../../widgets/sheets/strava_activity.dart';

/// Every answer of one feedback, with its setup and context. Shown in
/// [showFeedbackDetailsSheet]; nothing opens it as a page of its own.
class FeedbackDetailsContent extends StatelessWidget {
  final String feedbackId;
  final bool showEditButton;
  final bool showCloseButton;
  final bool showViewOnMap;

  const FeedbackDetailsContent({
    super.key,
    required this.feedbackId,
    this.showEditButton = false,
    this.showCloseButton = false,
    this.showViewOnMap = true,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final feedback = appRepository.feedbacks[feedbackId];

    if (feedback == null) {
      return const EmptyStatePlaceholder.error(
        title: "Feedback not found",
        subtitle: "This feedback was deleted or is no longer available.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context, feedback: feedback, appSettings: appSettings, setups: appRepository.setups),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _setupCard(context, feedback: feedback),
                ..._comparisonCards(context, feedback: feedback),
                _issuesCard(context, feedback: feedback),
                ContextMetaCard(notes: feedback.notes, tags: const {}, attachments: const []),
                ContextLocationWeatherCard(
                  position: feedback.position,
                  place: feedback.place,
                  displayName: 'Feedback',
                  mapPin: const FeedbackMapPin(),
                  weather: feedback.weather,
                  onViewOnMap: showViewOnMap ? () => MapActions.openFeedbackOnMap(context, feedback) : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(
    BuildContext context, {
    required RideFeedback feedback,
    required AppSettings appSettings,
    required Map<String, Setup> setups,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.verdict(setups) ?? 'Feedback',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${DateFormat(appSettings.dateFormat).format(feedback.dateTimeLocal)} • ${DateFormat(appSettings.timeFormat).format(feedback.dateTimeLocal)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (showEditButton) ...[
            const SizedBox(width: 12),
            sheetEditButton(context, onPressed: () => FeedbackActions.editFeedback(context, feedback: feedback)),
          ],
          if (showCloseButton) ...[
            const SizedBox(width: 8),
            sheetCloseButton(context),
          ],
        ],
      ),
    );
  }

  /// In the sheet, the setup replaces it rather than stacking a second sheet.
  Future<void> _openSetup(BuildContext context, Setup setup) async {
    if (!showCloseButton) {
      await showSetupDetailsSheet(context: context, setupId: setup.id, showViewOnMap: showViewOnMap);
      return;
    }
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);

    navigator.pop();
    await route?.popped;
    if (!navigator.mounted) return;

    await showSetupDetailsSheet(context: navigator.context, setupId: setup.id, showViewOnMap: showViewOnMap);
  }

  Widget _setupCard(BuildContext context, {required RideFeedback feedback}) {
    final appRepository = context.watch<AppRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    final bike = appRepository.bikes[feedback.bike];
    final resolved = appRepository.resolvedSetupFor(feedback);
    final storedName = appRepository.setups[feedback.setupId]?.displayName ?? 'a deleted setup';
    final activityId = feedback.stravaActivityId;
    final activity = activityId == null ? null : appRepository.stravaActivities[activityId];

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Bike.iconData, color: bike == null ? colorScheme.error : null),
            title: Text(
              bike?.name ?? "BIKE NOT FOUND",
              style: bike == null ? TextStyle(color: colorScheme.error) : null,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
          ),
          ListTile(
            leading: Icon(Setup.iconData, color: resolved == null ? colorScheme.error : null),
            title: Text(
              resolved?.displayName ?? "SETUP NOT FOUND",
              style: resolved == null ? TextStyle(color: colorScheme.error) : null,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: appRepository.hasSetupDrift(feedback)
                ? Text("Originally '$storedName'", style: TextStyle(color: colorScheme.error))
                : null,
            dense: true,
            trailing: resolved == null ? null : const Icon(Icons.chevron_right),
            onTap: resolved == null ? null : () => _openSetup(context, resolved),
          ),
          if (activityId != null)
            ListTile(
              leading: const Icon(SimpleIcons.strava),
              title: Text(activity?.name ?? "Strava ride not synced", overflow: TextOverflow.ellipsis),
              dense: true,
              trailing: activity == null ? null : const Icon(Icons.chevron_right),
              onTap: activity == null
                  ? null
                  : () => showStravaActivitySheet(context: context, stravaActivity: activity),
            ),
        ],
      ),
    );
  }

  /// One card per reference, newest reference first: the overall answer in the
  /// header, the follow-ups below. Comparisons this version can't read are left out.
  List<Widget> _comparisonCards(BuildContext context, {required RideFeedback feedback}) {
    final appRepository = context.watch<AppRepository>();
    final setups = appRepository.setups;
    final customIssues = appRepository.customIssues;
    final byReference = groupBy(
      feedback.comparisons.where((c) => c.isValid && c.aspect is! UnknownAspect),
      (FeedbackComparison c) => c.referenceSetupId,
    );
    final references = byReference.keys
        .sortedBy<DateTime>(
          (id) => setups[id]?.datetime ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        )
        .reversed;

    return [
      for (final referenceId in references)
        _compactCard(
          context,
          icon: Icons.compare_arrows,
          overline: 'Compared to',
          title: setups[referenceId]?.displayName ?? 'A deleted setup',
          trailing: switch (byReference[referenceId]!.firstWhereOrNull((c) => c.aspect is OverallAspect)) {
            final overall? => _outcomePill(
              context,
              FeedbackVocabulary.overallOutcomeLabels[overall.outcome]!,
              overall.outcome,
              large: true,
            ),
            null => null,
          },
          children: [
            for (final comparison in byReference[referenceId]!.sorted(
              (a, b) => _compareAspects(a.aspect, b.aspect, customIssues),
            ))
              if (_issueLabel(comparison.aspect, customIssues) case final label?)
                _row(
                  context,
                  label: label,
                  value: _outcomePill(
                    context,
                    FeedbackVocabulary.aspectOutcomeLabels[comparison.outcome]!,
                    comparison.outcome,
                  ),
                ),
          ],
        ),
    ];
  }

  /// The label of an issue aspect, null for the others.
  static String? _issueLabel(FeedbackAspect aspect, CustomIssueIndex customIssues) => switch (aspect) {
    final EndAspect aspect => FeedbackIssue.end(aspect).label,
    CustomAspect(:final slug) => customIssues.labelOf(slug),
    _ => null,
  };

  /// Built-in issues in vocabulary order, then custom ones by label.
  static int _compareAspects(FeedbackAspect a, FeedbackAspect b, CustomIssueIndex customIssues) {
    int order(FeedbackAspect aspect) => switch (aspect) {
      OverallAspect() => -1,
      final EndAspect aspect => EndAspect.values.indexOf(aspect),
      CustomAspect() => EndAspect.values.length,
      UnknownAspect() => EndAspect.values.length + 1,
    };
    final byOrder = order(a).compareTo(order(b));
    if (byOrder != 0) return byOrder;
    return (_issueLabel(a, customIssues) ?? '').toLowerCase().compareTo((_issueLabel(b, customIssues) ?? '').toLowerCase());
  }

  /// [large] for the overall answer, so it stands out from the follow-ups.
  Widget _outcomePill(BuildContext context, String label, int outcome, {bool large = false}) {
    final colors = Theme.of(context).extension<FeedbackOutcomeColors>()!;
    final color = switch (outcome.sign) {
      1 => colors.better,
      -1 => colors.worse,
      _ => colors.neutral,
    };
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: large ? FontWeight.bold : FontWeight.w600,
          fontSize: large ? 15 : 12,
        ),
      ),
    );
  }

  /// An answer row, indented under its card's title.
  Widget _row(BuildContext context, {required String label, required Widget value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
          value,
        ],
      ),
    );
  }

  /// Icon, title and an optional trailing answer, with [children] below the title.
  Widget _compactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? overline,
    Widget? trailing,
    List<Widget> children = const [],
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: muted),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (overline != null)
                              Text(overline, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (children.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issuesCard(BuildContext context, {required RideFeedback feedback}) {
    final issues = feedback.orderedIssues;
    final answered = feedback.nothingStoodOut || issues.isNotEmpty;

    return _compactCard(
      context,
      icon: Icons.flag_outlined,
      title: 'Anything stand out?',
      trailing: answered
          ? null
          : Text('Not answered', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      children: [if (answered) OpenIssuesChips(issues: issues)],
    );
  }
}
