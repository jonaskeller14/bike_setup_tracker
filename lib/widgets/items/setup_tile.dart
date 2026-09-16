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
import '../bookmark_ribbon.dart';
import '../current_setup_badge.dart';
import '../current_setup_highlight.dart';
import '../lists/adjustment_compact_display/adjustment_compact_display_list.dart';
import 'setup_options_menu.dart';
import 'setup_tile_header.dart';
import 'tile_meta_row.dart';

class SetupTile extends StatefulWidget {
  final String setupId;
  final VoidCallback? onTap;
  final bool showDate;
  final bool hidePlace;

  final double currentBarLeft;

  /// Extra outer inset the tile absorbs itself: for the current setup it is
  /// painted over by the highlight, so the tile grows instead of leaving a gap
  /// between its fill and whatever sits above/below it (e.g. a day header).
  final EdgeInsets edgeInset;
  final bool showCurrentBadge;

  const SetupTile({
    super.key,
    required this.setupId,
    required this.onTap,
    this.showDate = true,
    this.hidePlace = false,
    this.currentBarLeft = 0,
    this.edgeInset = EdgeInsets.zero,
    this.showCurrentBadge = false,
  });

  @override
  State<SetupTile> createState() => _SetupTileState();
}

class _SetupTileState extends State<SetupTile> {
  static const double _bookmarkRight = kMinInteractiveDimension + 8 - BookmarkRibbon.width;

  bool _displayOnlyChanges = true;

  Widget _bookmarkRibbon({required bool visible}) {
    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        child: const BookmarkRibbon(),
      ),
    );
  }

  Widget _scoreBadge(BuildContext context, double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF9A825),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          const Icon(RatingEntry.iconData, size: 13, color: Colors.white),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _setupListTile(BuildContext context, Setup setup, AdjustmentCompactSummary summary) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final double? score = appSettings.enableRating ? appRepository.scoreForSetup(setup.id) : null;
    final bool showInlineExpandIcon = summary.collapsedHidesSomething;

    final dateText = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
    final timeText = DateFormat(appSettings.timeFormat).format(setup.datetimeLocal);

    final metadataRows = <Widget>[
      if (setup.place != null && !widget.hidePlace)
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
      if (appSettings.enableSetupImages && setup.images.isNotEmpty)
        TileMetaRow(
          icon: Icons.photo_library_outlined,
          text: '${setup.images.length}',
          muted: true,
        ),
    ];
    final Widget? badge = score != null
        ? _scoreBadge(context, score)
        : widget.showCurrentBadge
        ? setup.isCurrent
              ? const CurrentSetupBadge()
              : null
        : null;

    return Padding(
      // Horizontal only. The popup menu and chevron need the row's full height
      // for their touch targets, so a vertical inset here would just push the
      // stacked buttons — and with them the row's minimum height — further
      // apart, opening dead space above the values. The content carries its own
      // vertical inset instead.
      //
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ConstrainedBox(
            // Content must be at least as tall as the trailing buttons,
            constraints: BoxConstraints(
              minHeight: showInlineExpandIcon ? 2 * kMinInteractiveDimension : kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                right: kMinInteractiveDimension + 8,
              ),
              child: SetupTileHeader(
                setup: setup,
                dateTimeText: widget.showDate
                    ? "$dateText • $timeText"
                    : timeText,
                metadata: metadataRows,
                badge: badge,
                showSetupIcon: true,
                secondaryMetadata: TileMetaRow(
                  icon: Bike.iconData,
                  text: bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
                  isError: !bikes.containsKey(setup.bike),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SetupOptionsMenu(setup: setup),
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

    final summary = AdjustmentCompactDisplayList.summarize(
      components: breakdown.components,
      persons: breakdown.person != null ? [breakdown.person!] : const [],
      danglingComponents: breakdown.danglingComponents,
      danglingPersons: breakdown.danglingPersons,
      adjustmentValues: adjustmentValues,
      previousAdjustmentValues: previousAdjustmentValues,
      displayPersonAdjustmentValues: appSettings.enablePerson,
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
      displayPersonAdjustmentValues: appSettings.enablePerson,
      contentInset: null,
    );

    // Whether the list renders anything in its current state — its padding
    // would otherwise add height to a row with no values.
    final bool hasValues = _displayOnlyChanges ? summary.collapsedHasContent : summary.hasContent;

    final Widget content = InkWell(
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

    final Widget row = setup.isCurrent
        ? CurrentSetupHighlight(
            barLeft: widget.currentBarLeft,
            padding: widget.edgeInset,
            child: content,
          )
        : Padding(padding: widget.edgeInset, child: content);

    return Stack(
      children: [
        row,
        Positioned(
          top: 0,
          right: widget.edgeInset.right + 16 + _bookmarkRight,
          child: _bookmarkRibbon(
            visible: appSettings.enableSetupBookmark && setup.isBookmarked,
          ),
        ),
      ],
    );
  }
}
