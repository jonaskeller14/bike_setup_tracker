import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/strava/strava_gear.dart';
import '../items/strava_gear_link_tile.dart';
import '../text/sheet_section_title.dart';

class _GearLink {
  final StravaGear gear;
  final List<Bike> linkedBikes;

  const _GearLink({required this.gear, required this.linkedBikes});

  bool get isLinked => linkedBikes.isNotEmpty;
}

class StravaGearLinkList extends StatefulWidget {
  final Iterable<StravaGear> gears;
  final Iterable<Bike> bikes;

  /// Rendered between the section title and the gear rows.
  final Widget? hint;

  const StravaGearLinkList({
    super.key,
    required this.gears,
    required this.bikes,
    this.hint,
  });

  @override
  State<StravaGearLinkList> createState() => _StravaGearLinkListState();
}

class _StravaGearLinkListState extends State<StravaGearLinkList> {
  static const int _maxCollapsedGears = 3;
  static const Duration _expandDuration = Duration(milliseconds: 200);

  /// How long a freshly linked row stays in the collapsed list: long enough
  /// for its flash to play out before the list settles back.
  static const Duration _settleDelay = Duration(milliseconds: 1400);

  /// Gear linked from this sheet, flashed once and held in place until its
  /// settle timer fires, so a row never vanishes mid-animation.
  final Set<String> _linkedHere = {};
  final Map<String, Timer> _settleTimers = {};
  bool _expanded = false;

  /// Called after the link is written, so the sheet may already be gone.
  void _markLinkedHere(String gearId) {
    if (!mounted) return;
    setState(() => _linkedHere.add(gearId));

    _settleTimers.remove(gearId)?.cancel();
    _settleTimers[gearId] = Timer(_settleDelay, () {
      _settleTimers.remove(gearId);
      if (!mounted) return;
      setState(() => _linkedHere.remove(gearId));
    });
  }

  @override
  void dispose() {
    for (final timer in _settleTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikes = widget.bikes.toList();
    final unlinkedBikes = bikes.where((b) => b.stravaGear == null).toList();
    final links = widget.gears
        .map((g) => _GearLink(gear: g, linkedBikes: bikes.where((b) => b.stravaGear == g.id).toList()))
        .toList();

    // Collapsed shows at most three rows: the one being linked right now
    // first, then gear that still needs a bike, then the rest.
    final byPriority = [
      ...links.where((link) => _linkedHere.contains(link.gear.id)),
      ...links.where((link) => !link.isLinked && !_linkedHere.contains(link.gear.id)),
      ...links.where((link) => link.isLinked && !_linkedHere.contains(link.gear.id)),
    ];
    final collapsedIds = byPriority.take(_maxCollapsedGears).map((link) => link.gear.id).toSet();

    final collapsed = links.where((link) => collapsedIds.contains(link.gear.id)).toList();
    final visible = _expanded ? links : collapsed;
    final linkedCount = links.where((link) => link.isLinked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: SheetSectionTitle(title: "Strava Gear:")),
            if (linkedCount < links.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "$linkedCount of ${links.length} linked",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        if (widget.hint != null) widget.hint!,
        AnimatedSize(
          duration: _expandDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: visible.map((link) {
              return StravaGearLinkTile(
                key: ValueKey<String>(link.gear.id),
                gear: link.gear,
                linkedBikes: link.linkedBikes,
                unlinkedBikes: unlinkedBikes,
                highlighted: _linkedHere.contains(link.gear.id),
                onLinked: () => _markLinkedHere(link.gear.id),
              );
            }).toList(),
          ),
        ),
        if (collapsed.length < links.length)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
              label: Text(_expanded ? "Show less" : "Show all (${links.length})"),
            ),
          ),
      ],
    );
  }
}
