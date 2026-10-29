import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../current_setup_badge.dart';
import '../items/setup_tile_header.dart';
import '../items/tile_meta_row.dart';
import '../sticky_section.dart';
import '../timeline_day_header.dart';

/// Setups of a pick sheet, newest first, each day under a sticky day header.
class SetupDayList extends StatelessWidget {
  final List<Setup> setups;
  final Widget Function(Setup setup) tileBuilder;
  final EdgeInsetsGeometry? padding;

  const SetupDayList({super.key, required this.setups, required this.tileBuilder, this.padding});

  @override
  Widget build(BuildContext context) {
    final sorted = [...setups]..sort((a, b) => b.datetimeLocal.compareTo(a.datetimeLocal));
    final sections = <({DateTime day, List<Setup> setups})>[];
    for (final setup in sorted) {
      final local = setup.datetimeLocal;
      final day = DateTime(local.year, local.month, local.day);
      if (sections.isEmpty || sections.last.day != day) {
        sections.add((day: day, setups: []));
      }
      sections.last.setups.add(setup);
    }

    return ListView(
      shrinkWrap: true,
      padding: padding,
      children: [
        for (final section in sections)
          StickySection(
            header: TimelineDayHeader(day: section.day, margin: EdgeInsets.zero),
            content: Column(
              children: [
                for (var index = 0; index < section.setups.length; index++) ...[
                  tileBuilder(section.setups[index]),
                  if (index + 1 < section.setups.length) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// A setup row of a pick sheet: the time of day, the bike name on request and
/// the "Current" badge, with [trailing] at the end. [onTap] is null if the
/// tile is disabled.
class SetupPickTile extends StatelessWidget {
  final Setup setup;
  final List<Widget> badges;
  final bool showBikeName;
  final bool selected;
  final Widget trailing;
  final String? semanticsIdentifier;
  final VoidCallback? onTap;

  const SetupPickTile({
    super.key,
    required this.setup,
    required this.trailing,
    required this.onTap,
    this.badges = const [],
    this.showBikeName = false,
    this.selected = false,
    this.semanticsIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final timeText = DateFormat(appSettings.timeFormat).format(setup.datetimeLocal);
    final isCurrent = appRepository.setupHistory.isCurrent(setup.id);
    final bike = appRepository.bikes[setup.bike];

    // The ripple paints on the nearest Material; the sheet's own sits outside
    // the scroll view, so it would draw over the header while scrolling.
    final tile = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SetupTileHeader(
                  setup: setup,
                  dateTimeText: timeText,
                  metadata: SetupTileHeader.metadataOf(setup, appSettings),
                  badge: badges.isNotEmpty || isCurrent
                      ? Wrap(spacing: 4, children: [...badges, if (isCurrent) const CurrentSetupBadge()])
                      : null,
                  showSetupIcon: true,
                  selected: selected,
                  secondaryMetadata: showBikeName
                      ? TileMetaRow(icon: Bike.iconData, text: bike?.name ?? 'Unknown bike', isError: bike == null)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );

    return Semantics(
      identifier: semanticsIdentifier,
      child: onTap == null ? Opacity(opacity: 0.38, child: tile) : tile,
    );
  }
}
