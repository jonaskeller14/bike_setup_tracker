import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/rating_entry.dart';
import '../../repositories/app_repository.dart';
import '../../services/rating_score_service.dart';
import '../../utils/rating_entry_actions.dart';
import '../../widgets/items/context_location_card.dart';
import '../../widgets/items/context_weather_card.dart';
import '../../widgets/notes_text.dart';
import '../../widgets/sheets/sheet.dart';

class RatingEntryDetailsPage extends StatelessWidget {
  final String ratingEntryId;

  const RatingEntryDetailsPage({super.key, required this.ratingEntryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rating")),
      body: SafeArea(
        child: RatingEntryDetailsContent(ratingEntryId: ratingEntryId, showEditButton: true),
      ),
    );
  }
}

class RatingEntryDetailsContent extends StatelessWidget {
  final String ratingEntryId;
  final bool showEditButton;
  final bool showCloseButton;

  const RatingEntryDetailsContent({
    super.key,
    required this.ratingEntryId,
    this.showEditButton = false,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final ratingEntry = appRepository.ratingEntries[ratingEntryId];

    if (ratingEntry == null) {
      return const Center(
        heightFactor: 4,
        child: Text("Rating not found."),
      );
    }

    final breakdown = appRepository.entryBreakdown(ratingEntry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context, entry: ratingEntry, appSettings: appSettings),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _scoreCard(context, ratingEntry: ratingEntry, breakdown: breakdown),
                const SizedBox(height: 12),
                ..._contextSection(context, entry: ratingEntry),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, {required RatingEntry entry, required AppSettings appSettings}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  entry.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                ),
                Text(
                  "${DateFormat(appSettings.dateFormat).format(entry.dateTimeLocal)} • ${DateFormat(appSettings.timeFormat).format(entry.dateTimeLocal)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (showEditButton) ...[
            const SizedBox(width: 12),
            sheetEditButton(context, onPressed: () => RatingEntryActions.editRatingEntry(context, ratingEntry: entry)),
          ],
          if (showCloseButton) ...[
            const SizedBox(width: 8),
            sheetCloseButton(context),
          ],
        ],
      ),
    );
  }

  Widget _scoreCard(BuildContext context, {required RatingEntry ratingEntry, required EntryScoreBreakdown breakdown}) {
    final colorScheme = Theme.of(context).colorScheme;
    final score = breakdown.score;
    final avg = score?.weightedAvg;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headline: the 0–10 score.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: avg == null ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    avg == null ? "– / 10" : "${avg.toStringAsFixed(1)} / 10",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: avg == null ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    score == null
                        ? "No scored metrics answered"
                        : "Score · ${score.answeredScored} of ${score.totalScored} metrics rated",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 30),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 13, height: 1.4),
                  message: _calculationExplainer(breakdown),
                  child: Icon(Icons.info_outline, size: 18, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (breakdown.rows.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...breakdown.rows.map((row) => _breakdownRow(context, row)),
            ],
          ],
        ),
      ),
    );
  }

  String _calculationExplainer(EntryScoreBreakdown breakdown) {
    final score = breakdown.score;

    // Plain-language glossary, shared by both states.
    const intro =
        "The score sums up how good this setup felt, on a 0–10 scale.\n\n"
        "Goodness (0–10): for each metric, how good its answer is. The best "
        "possible answer scores 10, the worst scores 0. For metrics where lower "
        "is better (e.g. a lap time), a low value scores high.\n\n"
        "Importance (the ×number): how much a metric counts toward the score. "
        "A ×2 metric pulls twice as hard as a ×1 metric; ×0 doesn't count.\n\n"
        "The score is the average of every answered metric's goodness, weighted "
        "by its importance.";

    if (score == null) {
      return "$intro\n\nAnswer at least one scored metric to see a score.";
    }

    return "$intro\n\n"
        "This rating: ${breakdown.weightedTotal.toStringAsFixed(1)} of "
        "${breakdown.maxTotal.toStringAsFixed(1)} possible points "
        "(each metric's goodness × importance, added up)\n"
        "→ ${breakdown.weightedTotal.toStringAsFixed(1)} ÷ ${breakdown.maxTotal.toStringAsFixed(1)} × 10 "
        "= ${score.weightedAvg.toStringAsFixed(1)} / 10.";
  }

  Widget _breakdownRow(BuildContext context, MetricScoreBreakdown row) {
    final scheme = Theme.of(context).colorScheme;
    final lowerIsBetter = row.metric.weight < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.metric.adjustment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                row.subScore == null ? "–" : "${row.subScore!.toStringAsFixed(1)}/10",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: row.answered ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              _weightChip(context, row.absWeight),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: row.goodness ?? 0,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
          if (lowerIsBetter)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "lower is better",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weightChip(BuildContext context, double absWeight) {
    final scheme = Theme.of(context).colorScheme;
    // Trim trailing ".0" so ×1 / ×2 read cleanly, keep ×1.5 etc.
    final w = absWeight == absWeight.roundToDouble() ? absWeight.toStringAsFixed(0) : absWeight.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "×$w",
        style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _contextSection(BuildContext context, {required RatingEntry entry}) {
    final appRepository = context.watch<AppRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    final resolvedId = appRepository.resolveSetupId(bikeId: entry.bike, atUtc: entry.dateTimeUTC);
    final resolvedSetup = resolvedId == null ? null : appRepository.setups[resolvedId];
    final bike = appRepository.bikes[entry.bike];
    final drift = resolvedId != entry.setupId;
    final originalSetup = appRepository.setups[entry.setupId];

    return [
      if (entry.notes != null && entry.notes!.isNotEmpty)
        Card.outlined(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.notes),
            titleAlignment: ListTileTitleAlignment.titleHeight,
            title: NotesText(entry.notes!, maxLines: 10),
            dense: true,
          ),
        ),
      ContextLocationCard(position: entry.position, place: entry.place, displayName: entry.displayName),
      ContextWeatherCard(weather: entry.weather),
      Card.outlined(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Bike.iconData, color: bike == null ? colorScheme.error : null),
              title: Text(
                bike?.name ?? "BIKE NOT FOUND",
                style: bike == null ? TextStyle(color: colorScheme.error) : null,
              ),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.tune, color: resolvedSetup == null ? colorScheme.error : null),
              title: Text(
                resolvedSetup != null ? "Setup: ${resolvedSetup.displayName}" : "SETUP NOT FOUND",
                style: resolvedSetup == null ? TextStyle(color: colorScheme.error) : null,
              ),
              dense: true,
              subtitle: drift
                  ? Text(
                      "Originally linked to ${originalSetup?.displayName ?? 'SETUP NOT FOUND'}",
                      style: TextStyle(color: colorScheme.error),
                    )
                  : null,
            ),
          ],
        ),
      ),
    ];
  }
}
