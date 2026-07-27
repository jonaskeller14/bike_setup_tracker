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
import '../current_setup_badge.dart';
import '../current_setup_highlight.dart';
import '../lists/adjustment_compact_display_list.dart';
import '../notes_text.dart';
import 'tile_meta_row.dart';

class SetupListTile extends StatefulWidget {
  final String setupId;
  final void Function()? onTap;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool showDate;

  /// Rendered as a member of a SetupGroupSection: collapsed to just the changed
  /// adjustment values. The always-visible expand chevron reveals title, time,
  /// metadata, the editing menu and the full value list.
  final bool embedded;
  final bool hidePlace;

  final double currentBarLeft;

  const SetupListTile({
    super.key,
    required this.setupId,
    required this.onTap,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    this.showDate = true,
    this.embedded = false,
    this.hidePlace = false,
    this.currentBarLeft = 0,
  });

  @override
  State<SetupListTile> createState() => _SetupListTileState();
}

class _SetupListTileState extends State<SetupListTile> {
  bool _displayOnlyChanges = true;

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
        TileMetaRow(
          icon: Icons.location_pin,
          text: "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
          muted: true,
        ),
      if (!widget.embedded && setup.weather?.currentTemperature != null)
        TileMetaRow(
          icon: ContextWeather.currentTemperatureIconData,
          text: "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
          muted: true,
        ),
      if (!widget.embedded && setup.weather?.condition != null)
        TileMetaRow(
          icon: setup.weather?.condition?.iconData ?? Icons.question_mark,
          text: setup.weather?.condition?.value ?? "-",
          iconColor: setup.weather?.condition?.color,
          muted: true,
        ),
      if (appSettings.enableSetupTags)
        ...setup.tags.map((tag) => TileMetaRow(icon: Icons.tag, text: tag, muted: true)),
      if (appSettings.enableSetupImages && setup.images.isNotEmpty)
        TileMetaRow(
          icon: Icons.photo_library_outlined,
          text: '${setup.images.length}',
          muted: true,
        ),
    ];
    final bool hasNotes = setup.notes != null && setup.notes!.isNotEmpty;

    // One badge only — stacking two pushed the subtitle down. The bar and tint
    // already mark the current setup, so its badge yields to the score.
    final Widget? badge = score != null
        ? _scoreBadge(context, score)
        : setup.isCurrent
        ? const CurrentSetupBadge()
        : null;

    return Padding(
      // Horizontal only. The popup menu and chevron need the row's full height
      // for their touch targets, so a vertical inset here would just push the
      // stacked buttons — and with them the row's minimum height — further
      // apart, opening dead space above the values. The content carries its own
      // vertical inset instead.
      //
      // Embedded (group member): the group's container already carries the row
      // inset, and the trailing edge pulls in to 4 so the popup menu lines up
      // with the expand chevron below it.
      padding: widget.embedded
          ? const EdgeInsets.only(left: 8, right: 4)
          : const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                right: kMinInteractiveDimension + 8,
              ),
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
                                ?badge,
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
                                    fontSize: 12,
                                  ),
                                ),
                                if (!widget.embedded)
                                  TileMetaRow(
                                    icon: Bike.iconData,
                                    text: bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
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
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: NotesText(
                                    setup.notes!,
                                    fontSize: 12,
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

  /// Embedded-only: lines up with the member's value rows.
  Widget _noChangesHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
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
  /// the chevron expands to the full content (title, time, metadata, menu,
  /// all values).
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
          // Force the stack to the full row width so the right-anchored
          // chevron lands at the row edge and aligns across members,
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
              padding: const EdgeInsets.only(bottom: 6),
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
      // Group members sit inside the group's container, which is already
      // inset — their values line up with the member title instead.
      contentInset: widget.embedded ? 8 : null,
    );

    // Whether the list renders anything in its current state — its padding
    // would otherwise add height to a row with no values.
    final bool hasValues = _displayOnlyChanges
        ? summary.collapsedHasContent
        : summary.hasContent;

    final Widget content = widget.embedded
        ? _buildEmbedded(context, setup, summary, adjustmentList)
        : InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _setupListTile(context, setup, summary),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: hasValues
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: adjustmentList,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );

    if (!setup.isCurrent) return content;
    return CurrentSetupHighlight(
      barLeft: widget.currentBarLeft,
      child: content,
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
