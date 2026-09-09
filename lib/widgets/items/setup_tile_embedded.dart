import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/rating_entry.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/dangling_adjustment_service.dart';
import '../bookmark_ribbon.dart';
import '../current_setup_badge.dart';
import '../current_setup_highlight.dart';
import '../lists/adjustment_compact_display_list.dart';
import 'setup_options_menu.dart';
import 'setup_tile_header.dart';
import 'tile_meta_row.dart';

class SetupTileEmbedded extends StatefulWidget {
  final String setupId;
  final VoidCallback? onTap;
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

  Widget _setupListTile(BuildContext context, Setup setup, AdjustmentCompactSummary summary) {
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
      // Horizontal only. The popup menu and chevron need the row's full height
      // for their touch targets, so a vertical inset here would just push the
      // stacked buttons — and with them the row's minimum height — further
      // apart, opening dead space above the values. The content carries its own
      // vertical inset instead.
      //
      padding: const EdgeInsets.only(left: _embeddedContentInset, right: 4),
      child: Stack(
        children: [
          ConstrainedBox(
            // Content must be at least as tall as the trailing buttons,
            constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
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
                showSetupIcon: false,
                secondaryMetadata: null,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: _bookmarkRight,
            child: _bookmarkRibbon(
              visible: appSettings.enableSetupBookmark && setup.isBookmarked,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SetupOptionsMenu(setup: setup),
          ),
        ],
      ),
    );
  }

  /// Embedded-only: lines up with the member's value rows.
  Widget _noChangesHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _embeddedContentInset,
        6,
        0,
        6,
      ),
      child: Text(
        'No changes',
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
                  if (!_displayOnlyChanges) _setupListTile(context, setup, summary),
                  Padding(
                    padding: EdgeInsets.only(
                      top: _displayOnlyChanges ? 8 : 0,
                      bottom: 8,
                      // Keep the last value row clear of the chevron.
                      right: kMinInteractiveDimension,
                    ),
                    child: _displayOnlyChanges && !summary.collapsedHasContent ? _noChangesHint(context) : adjustmentList,
                  ),
                ],
              ),
            ),
          ),
          // Keep the chevron at the top of the row. Once expanded, move it one
          // touch target down so it sits directly below the popup menu.
          Positioned(
            top: !_displayOnlyChanges
                ? kMinInteractiveDimension
                : _collapsedChevronTop,
            right: 4,
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
      contentInset: _embeddedContentInset,
    );

    final Widget content = _buildEmbedded(context, setup, summary, adjustmentList);

    return setup.isCurrent
        ? CurrentSetupHighlight(
            barLeft: widget.currentBarLeft,
            padding: widget.edgeInset,
            child: content,
          )
        : Padding(padding: widget.edgeInset, child: content);
  }
}
