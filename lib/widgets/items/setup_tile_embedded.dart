import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/rating/rating_entry.dart';
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
import 'timeline_selection_fill.dart';

class SetupTileEmbedded extends StatefulWidget {
  final String setupId;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool selected;

  /// False when an enclosing group already paints the selection tint, so the
  /// translucent fills don't stack.
  final bool showSelectionFill;
  final VoidCallback? onSelectionChanged;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool showDate;
  final bool hidePlace;

  final double currentBarLeft;

  /// Extra outer inset the tile absorbs itself: for the current setup it is
  /// painted over by the highlight, so the tile grows instead of leaving a gap
  /// between its fill and whatever sits above/below it (e.g. a day header).
  final EdgeInsets edgeInset;
  final bool showCurrentBadge;

  const SetupTileEmbedded({
    super.key,
    required this.setupId,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.showSelectionFill = true,
    this.onSelectionChanged,
    this.displayBikeAdjustmentValues = true,
    this.displayPersonAdjustmentValues = true,
    this.showDate = true,
    this.hidePlace = false,
    this.currentBarLeft = 0,
    this.edgeInset = EdgeInsets.zero,
    this.showCurrentBadge = false,
  });

  @override
  State<SetupTileEmbedded> createState() => _SetupTileEmbeddedState();
}

class _SetupTileEmbeddedState extends State<SetupTileEmbedded> {
  static const double _embeddedContentInset = 16;
  static const double _collapsedChevronTop = 4;
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

  Widget _setupHeader(BuildContext context, Setup setup) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final double? score = appSettings.enableRating ? appRepository.scoreForSetup(setup.id) : null;

    final dateText = DateFormat(appSettings.dateFormat).format(setup.datetimeLocal);
    final timeText = DateFormat(appSettings.timeFormat).format(setup.datetimeLocal);

    final metadataRows = <Widget>[
      if (setup.place != null && !widget.hidePlace)
        TileMetaRow(
          icon: Icons.location_pin,
          text: "${setup.place?.locality}, ${setup.place?.isoCountryCode}",
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
      // Right inset keeps the header text clear of the trailing buttons.
      padding: const EdgeInsets.fromLTRB(_embeddedContentInset, 8, 8, 8),
      child: SetupTileHeader(
        setup: setup,
        dateTimeText: widget.showDate
            ? "$dateText • $timeText"
            : timeText,
        metadata: metadataRows,
        badge: badge,
        showSetupIcon: false,
        selected: widget.selected,
        secondaryMetadata: null,
      ),
    );
  }

  /// Embedded-only: lines up with the member's value rows.
  Widget _noValuesHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _embeddedContentInset,
        12,
        0,
        12,
      ),
      child: Text(
        _displayOnlyChanges ? 'No changes' : 'No values',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildEmbedded(
    BuildContext context,
    Setup setup,
    AdjustmentCompactSummary summary,
    AdjustmentCompactDisplayList adjustmentList,
  ) {
    final appSettings = context.watch<AppSettings>();
    final bool hasValues = !_displayOnlyChanges ? summary.hasContent : summary.collapsedHasContent;

    return InkWell(
      onTap: widget.selectionMode ? widget.onSelectionChanged : widget.onTap,
      onLongPress: widget.onSelectionChanged,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Stack(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_displayOnlyChanges) _setupHeader(context, setup),
                        Padding(
                          padding: EdgeInsets.only(top: !_displayOnlyChanges ? 0 : 8, bottom: 8),
                          child: hasValues ? adjustmentList : _noValuesHint(context),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_displayOnlyChanges && !widget.selectionMode) SetupOptionsMenu(setup: setup),
                      Padding(
                        padding: EdgeInsets.only(top: !_displayOnlyChanges ? 0 : _collapsedChevronTop),
                        child: ExpandIcon(
                          isExpanded: !_displayOnlyChanges,
                          color: PopupMenuTheme.of(context).iconColor ?? IconTheme.of(context).color,
                          expandedColor: Theme.of(context).colorScheme.primary,
                          onPressed: (bool isExpanded) {
                            setState(() {
                              _displayOnlyChanges = isExpanded;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: _bookmarkRight,
              child: _bookmarkRibbon(
                visible: !_displayOnlyChanges && appSettings.enableSetupBookmark && setup.isBookmarked,
              ),
            ),
          ],
        ),
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

    final Widget content = TimelineSelectionFill(
      selected: widget.selected && widget.showSelectionFill,
      child: _buildEmbedded(context, setup, summary, adjustmentList),
    );

    return setup.isCurrent
        ? CurrentSetupHighlight(
            barLeft: widget.currentBarLeft,
            padding: widget.edgeInset,
            child: content,
          )
        : Padding(padding: widget.edgeInset, child: content);
  }
}
