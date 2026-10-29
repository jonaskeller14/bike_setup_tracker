import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../feedback/open_issues_chips.dart';
import '../feedback/setup_rank_badge.dart';
import '../notes_text.dart';
import 'tile_meta_row.dart';

class SetupTileHeader extends StatelessWidget {
  final Setup setup;
  final String dateTimeText;
  final List<Widget> metadata;
  final Widget? badge;
  final Widget? secondaryMetadata;

  /// Shown below the notes.
  final Widget? footer;
  final bool showSetupIcon;
  final bool selected;

  const SetupTileHeader({
    super.key,
    required this.setup,
    required this.dateTimeText,
    required this.metadata,
    required this.showSetupIcon,
    this.badge,
    this.secondaryMetadata,
    this.footer,
    this.selected = false,
  });

  /// The [metadata] rows of a setup tile: place, weather, tags, attachments.
  static List<Widget> metadataOf(Setup setup, AppSettings appSettings, {bool hidePlace = false}) => [
    if (setup.place != null && !hidePlace)
      TileMetaRow(
        icon: Icons.location_pin,
        text: "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
        muted: true,
      ),
    if (setup.weather?.currentTemperature != null)
      TileMetaRow(
        icon: ContextWeather.currentTemperatureIconData,
        text:
            "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
        muted: true,
      ),
    if (setup.weather?.condition != null)
      TileMetaRow(
        icon: setup.weather?.condition?.iconData ?? Icons.question_mark,
        text: setup.weather?.condition?.value ?? "-",
        iconColor: setup.weather?.condition?.color,
        muted: true,
      ),
    if (appSettings.enableSetupTags) ...setup.tags.map((tag) => TileMetaRow(icon: Icons.tag, text: tag, muted: true)),
    if (appSettings.enableAttachments && setup.attachments.isNotEmpty)
      TileMetaRow(
        icon: Icons.attach_file,
        text: '${setup.attachments.length}',
        muted: true,
      ),
  ];

  /// The setup's rank for the [metadata] rows, once confident. Null while Feedback is off.
  static Widget? rankOf(Setup setup, AppSettings appSettings, AppRepository appRepository) => switch (
    appSettings.enableRating ? appRepository.rankFor(setup.id) : null
  ) {
    final rank? when rank.isConfident => SetupRankBadge(rank: rank),
    _ => null,
  };

  /// Whether setup tiles list the open issues from feedback. Off until it is
  /// clear they earn the space; setup details always show them.
  static const bool showOpenIssuesInTiles = false;

  /// The setup's open issues or "Dialled in", for the [footer]. Null while Feedback is off.
  static Widget? openIssuesOf(Setup setup, AppSettings appSettings, AppRepository appRepository) => switch (
    appSettings.enableRating ? appRepository.openIssuesFor(setup.id) : null
  ) {
    final openIssues? => OpenIssuesChips.of(openIssues),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final notesColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    final hasNotes = setup.notes?.isNotEmpty ?? false;
    final selectedColor = selected ? Theme.of(context).colorScheme.primary : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSetupIcon) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Setup.iconData, color: selectedColor),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          setup.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: selectedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                      ?badge,
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        dateTimeText,
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                      ?secondaryMetadata,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (metadata.isNotEmpty || hasNotes || footer != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: metadata,
                  ),
                if (hasNotes)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.notes, size: 12, color: notesColor),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: NotesText(
                          setup.notes!,
                          fontSize: 12,
                          color: notesColor,
                        ),
                      ),
                    ],
                  ),
                if (footer case final footer?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: footer,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
