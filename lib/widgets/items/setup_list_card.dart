import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_weather.dart';
import '../../models/rating_entry.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/dangling_adjustment_service.dart';
import '../../utils/setup_actions.dart';
import '../lists/adjustment_compact_display_list.dart';
import '../notes_text.dart';

class SetupListCard extends StatefulWidget {
  final String setupId;
  final void Function()? onTap;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool showDate;

  /// Rendered as a member of a SetupGroupCard: no Card wrapper; collapsed to
  /// just the changed adjustment values. The always-visible expand chevron
  /// reveals title, time, metadata, the editing menu and the full value list.
  final bool embedded;
  final bool hidePlace;

  const SetupListCard({
    super.key,
    required this.setupId,
    required this.onTap,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    this.showDate = true,
    this.embedded = false,
    this.hidePlace = false,
  });

  @override
  State<SetupListCard> createState() => _SetupListCardState();
}

class _SetupListCardState extends State<SetupListCard> {
  bool _displayOnlyChanges = true;

  Widget _setupCardCurrentLabel(BuildContext context) {
    return Positioned(
      top: -1,
      right: -1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12 / 2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          'Current',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _scoreBadge(BuildContext context, double score) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(RatingEntry.iconData, size: 13, color: colorScheme.onPrimaryContainer),
          Text(
            "${score.toStringAsFixed(1)} / 10",
            style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _optionsMenu(BuildContext context, Setup setup, AppSettings appSettings) {
    return PopupMenuButton<_SetupOptions>(
      onSelected: (_SetupOptions value) async {
        switch (value) {
          case _SetupOptions.edit:
            await SetupActions.editSetup(context, setup: setup);
          case _SetupOptions.share:
            await SetupActions.shareSetup(context, setup: setup);
          case _SetupOptions.restore:
            await SetupActions.duplicateSetup(context, setup: setup);
          case _SetupOptions.addRating:
            await SetupActions.addRatingEntryForSetup(context, setup: setup);
          case _SetupOptions.remove:
            await SetupActions.removeSetup(context, setup: setup);
        }
      },
      itemBuilder: (BuildContext context) {
        return _SetupOptions.values.where((option) {
          if (!appSettings.enableRating && (option == _SetupOptions.addRating)) return false;
          return true;
        }).map((option) {
          return PopupMenuItem<_SetupOptions>(
            value: option,
            child: Row(
              spacing: 10,
              children: [
                Icon(option.iconData, size: 20),
                Text(option.label),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _subtitleRow(BuildContext context, IconData icon, String text, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(icon, size: 13, color: isError ? scheme.error : scheme.onSurfaceVariant),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: isError ? scheme.error : scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Secondary metadata below the tile: more muted than the subtitle line.
  Widget _metadataRow(BuildContext context, IconData icon, String text, {Color? iconColor}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Icon(icon, size: 13, color: (iconColor ?? scheme.onSurfaceVariant).withValues(alpha: 0.6)),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _setupListTile(BuildContext context, Setup setup, AdjustmentCompactSummary summary) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final double? score = appSettings.enableRating
        ? appRepository.scoreForSetup(setup.id)
        : null;
    // Embedded members get their chevron from the embedded wrapper instead.
    final bool showInlineExpandIcon = !widget.embedded && summary.collapsedHidesSomething;

    final dateText = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
    final timeText = DateFormat(appSettings.timeFormat).format(setup.datetimeLocal);

    final metadataRows = <Widget>[
      if (setup.place != null && !widget.hidePlace)
        _metadataRow(
          context,
          Icons.location_pin,
          "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
        ),
      if (!widget.embedded && setup.weather?.currentTemperature != null)
        _metadataRow(
          context,
          ContextWeather.currentTemperatureIconData,
          "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
        ),
      if (!widget.embedded && setup.weather?.condition != null)
        _metadataRow(
          context,
          setup.weather?.condition?.iconData ?? Icons.question_mark,
          setup.weather?.condition?.value ?? "-",
          iconColor: setup.weather?.condition?.color,
        ),
      if (appSettings.enableSetupTags)
        ...setup.tags.map((tag) => _metadataRow(context, Icons.tag, tag)),
      if (appSettings.enableSetupImages && setup.images.isNotEmpty)
        _metadataRow(context, Icons.photo_library_outlined, '${setup.images.length}'),
    ];
    final bool hasNotes = setup.notes != null && setup.notes!.isNotEmpty;

    return Padding(
      // Embedded (group member): pull the trailing edge in to 4 so the popup
      // menu lines up with the expand chevron below it instead of sitting
      // inset with empty space to its right.
      padding: EdgeInsets.fromLTRB(16, 12, widget.embedded ? 4 : 16, 0),
      child: Stack(
        children: [
          ConstrainedBox(
            // Content must be at least as tall as the trailing buttons,
            constraints: BoxConstraints(
              minHeight: showInlineExpandIcon
                  ? 2 * kMinInteractiveDimension
                  : kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: kMinInteractiveDimension + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Setup.iconData),
                      ),
                      const SizedBox(width: 8),
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
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                                if (score != null)
                                  _scoreBadge(context, score),
                              ],
                            ),
                            Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  widget.showDate ? "$dateText • $timeText" : timeText,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                if (!widget.embedded)
                                  _subtitleRow(
                                    context,
                                    Bike.iconData,
                                    bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
                                    isError: !bikes.containsKey(setup.bike),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (metadataRows.isNotEmpty || hasNotes)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (metadataRows.isNotEmpty)
                            Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: metadataRows,
                            ),
                          if (hasNotes)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Icon(
                                    Icons.notes,
                                    size: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: NotesText(
                                    setup.notes!,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _optionsMenu(context, setup, appSettings),
          ),
          if (showInlineExpandIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: ExpandIcon(
                isExpanded: !_displayOnlyChanges,
                color: PopupMenuTheme.of(context).iconColor ?? IconTheme.of(context).color,
                expandedColor: Theme.of(context).colorScheme.primary,
                onPressed: (bool expanded) {
                  setState(() {
                    _displayOnlyChanges = expanded;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _noChangesHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        'No changes',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Group-member layout: collapsed it is just the changed adjustment values;
  /// the chevron expands to the full card content (title, time, metadata,
  /// menu, all values).
  Widget _buildEmbedded(
    BuildContext context,
    Setup setup,
    AdjustmentCompactSummary summary,
    AdjustmentCompactDisplayList adjustmentList,
  ) {
    final bool expanded = !_displayOnlyChanges;

    return InkWell(
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Force the stack to the full card width so the right-anchored
          // chevron lands at the card edge and aligns across members,
          // regardless of how wide each member's value list is.
          const SizedBox(width: double.infinity),
          ConstrainedBox(
            // Keep room for the chevron even when the value list is short.
            constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expanded) _setupListTile(context, setup, summary),
                  Padding(
                    padding: EdgeInsets.only(
                      top: expanded ? 0 : 8,
                      bottom: 8,
                      // Keep the last value row clear of the chevron.
                      right: kMinInteractiveDimension,
                    ),
                    child: !expanded && !summary.collapsedHasContent
                        ? _noChangesHint(context)
                        : adjustmentList,
                  ),
                ],
              ),
            ),
          ),
          // Bottom-anchored so it stays with the last line when the collapsed
          // value list wraps to multiple lines. The bottom padding matches the
          // content's own bottom padding so the chevron lines up with the last
          // row rather than sitting below it.
          Positioned(
            bottom: 0,
            right: 4,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6), //FIXME was 8
              child: ExpandIcon(
                isExpanded: expanded,
                color: PopupMenuTheme.of(context).iconColor ?? IconTheme.of(context).color,
                expandedColor: Theme.of(context).colorScheme.primary,
                onPressed: (bool expanded) {
                  setState(() {
                    _displayOnlyChanges = expanded;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final setups = appRepository.setups;
    final setup = setups[widget.setupId];
    if (setup == null) return const SizedBox.shrink();

    final breakdown = DanglingAdjustmentService.analyzeSetup(
      setup: setup,
      components: appRepository.components.values,
      persons: appRepository.persons.values,
    );
    final adjustmentValues = {
      ...setup.bikeAdjustmentValues,
      ...setup.personAdjustmentValues,
    };
    final previousAdjustmentValues = {
      ...setup.previousBikeAdjustmentValues,
      ...setup.previousPersonAdjustmentValues,
    };
    final displayPerson = widget.displayPersonAdjustmentValues && appSettings.enablePerson;

    final summary = AdjustmentCompactDisplayList.summarize(
      components: breakdown.components,
      persons: breakdown.person != null ? [breakdown.person!] : const [],
      danglingComponents: breakdown.danglingComponents,
      danglingPersons: breakdown.danglingPersons,
      adjustmentValues: adjustmentValues,
      previousAdjustmentValues: previousAdjustmentValues,
      displayBikeAdjustmentValues: widget.displayBikeAdjustmentValues,
      displayPersonAdjustmentValues: displayPerson,
    );

    final adjustmentList = AdjustmentCompactDisplayList(
      components: breakdown.components,
      persons: breakdown.person != null ? [breakdown.person!] : const [],
      danglingComponents: breakdown.danglingComponents,
      danglingPersons: breakdown.danglingPersons,
      adjustmentValues: adjustmentValues,
      previousAdjustmentValues: previousAdjustmentValues,
      showRowIcons: true,
      highlightInitialValues: true,
      displayOnlyChanges: _displayOnlyChanges,
      displayBikeAdjustmentValues: widget.displayBikeAdjustmentValues,
      displayPersonAdjustmentValues: displayPerson,
    );

    if (widget.embedded) {
      return _buildEmbedded(context, setup, summary, adjustmentList);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: setup.isCurrent
          ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ))
          : null,
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _setupListTile(context, setup, summary),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: adjustmentList,
                  ),
                ),
              ],
            ),
            if (setup.isCurrent)
              _setupCardCurrentLabel(context),
          ],
        ),
      ),
    );
  }
}

enum _SetupOptions {
  edit("Edit", Icons.edit),
  share("Share", Icons.share),
  restore("Restore", Icons.restore),
  addRating("Add Rating", RatingEntry.iconData),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _SetupOptions(this.label, this.iconData);
}
