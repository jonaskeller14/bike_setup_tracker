import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/rating_entry.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_entry_actions.dart';
import '../notes_text.dart';
import '../sheets/rating_entry_details.dart';

class RatingEntryListTile extends StatelessWidget {
  final RatingEntry ratingEntry;

  const RatingEntryListTile({super.key, required this.ratingEntry});

  Widget _buildStatItem(BuildContext context, String iconText, String text, {bool secondary = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Text(
          iconText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: secondary 
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: secondary 
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final appSettings = context.watch<AppSettings>();
    final score = appRepository.entryScore(ratingEntry);

    final avgText = score == null ? "–" : "${score.weightedAvg.toStringAsFixed(1)} / 10";
    final sumText = score == null ? "–" : score.weightedSum.toStringAsFixed(1);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      titleAlignment: ListTileTitleAlignment.titleHeight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(ratingEntry.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.calendar_month, size: 12, color: colorScheme.onSurfaceVariant),
                  Text(
                    DateFormat(appSettings.dateFormat).format(ratingEntry.dateTimeLocal),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.access_time, size: 12, color: colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      DateFormat(appSettings.timeFormat).format(ratingEntry.dateTimeLocal),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 2,
            children: [
              Icon(
                Bike.iconData,
                size: 12, 
                color: bikes.containsKey(ratingEntry.bike) 
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.error,
              ),
              Flexible(
                child: Text(
                  bikes[ratingEntry.bike]?.name ?? "BIKE NOT FOUND",
                  style: TextStyle(
                    color: bikes.containsKey(ratingEntry.bike)
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error, 
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (ratingEntry.place != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 2,
              children: [
                Icon(Icons.location_pin, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                Flexible(
                  child: Text(
                    "${ratingEntry.place?.locality}, ${ratingEntry.place?.isoCountryCode}",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (ratingEntry.notes != null && ratingEntry.notes!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                  child: Icon(
                    Icons.notes,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: NotesText(
                    ratingEntry.notes!,
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatItem(context, "Ø", avgText),
                _buildStatItem(context, "Σ", sumText, secondary: true),
              ],
            ),
          ),
        ],
      ),
      onTap: () => showRatingEntryDetailsSheet(context: context, ratingEntry: ratingEntry),
      trailing: PopupMenuButton<_RatingEntryOption>(
        onSelected: (option) async {
          switch (option) {
            case _RatingEntryOption.edit:
              await RatingEntryActions.editRatingEntry(context, ratingEntry: ratingEntry);
            case _RatingEntryOption.duplicate:
              await RatingEntryActions.duplicateRatingEntry(context, ratingEntry: ratingEntry);
            case _RatingEntryOption.remove:
              await RatingEntryActions.removeRatingEntry(context, ratingEntry: ratingEntry);
          }
        },
        itemBuilder: (BuildContext context) => _RatingEntryOption.values.map((option) {
          return PopupMenuItem<_RatingEntryOption>(
            value: option,
            child: Row(
              spacing: 10,
              children: [
                Icon(option.iconData, size: 20),
                Text(option.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _RatingEntryOption {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);

  final String label;
  final IconData iconData;
  const _RatingEntryOption(this.label, this.iconData);
}
