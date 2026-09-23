import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../utils/map_actions.dart';
import '../utils/map_empty_state.dart';
import '../utils/setup_actions.dart';

/// Tells the user why the map has no pins, floating above the map itself.
///
/// It collapses to a pill so it can never hide a corner of the map for good.
class MapEmptyStateCard extends StatelessWidget {
  static const _switchDuration = Duration(milliseconds: 200);

  final MapPinState state;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onRetry;

  const MapEmptyStateCard({
    super.key,
    required this.state,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(context);
    return AnimatedSwitcher(
      duration: _switchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // The card and the pill differ in size: pin them to the same corner so
      // the smaller one doesn't drift while they cross-fade.
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.bottomLeft,
        children: [...previousChildren, ?currentChild],
      ),
      child: collapsed ? _pill(context, copy) : _card(context, copy),
    );
  }

  Widget _card(BuildContext context, _MapEmptyCopy copy) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = copy.isError ? scheme.error : scheme.onSurfaceVariant;

    return Container(
      key: copy.key,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(copy.icon, size: 20, color: accent),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: copy.isError ? scheme.error : scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  copy.subtitle,
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => copy.onAction(context),
                  icon: Icon(copy.actionIcon, size: 18),
                  label: Text(copy.actionLabel, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('map-empty-collapse'),
            onPressed: onToggleCollapsed,
            icon: const Icon(Icons.close, size: 18),
            color: scheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            tooltip: 'Collapse',
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, _MapEmptyCopy copy) {
    final scheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      key: const Key('map-empty-pill'),
      style: TextButton.styleFrom(
        backgroundColor: scheme.surface,
        foregroundColor: copy.isError ? scheme.error : scheme.onSurfaceVariant,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 40),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onToggleCollapsed,
      icon: const Icon(Icons.expand_less, size: 18),
      label: Text(copy.pillLabel, overflow: TextOverflow.ellipsis),
    );
  }

  _MapEmptyCopy _copyFor(BuildContext context) => switch (state) {
    MapPinState.error => _MapEmptyCopy(
      key: const Key('map-empty-error'),
      icon: Icons.cloud_off,
      title: "Couldn't load activities",
      subtitle: 'Setups and rating entries are still shown.',
      pillLabel: 'Activities failed',
      actionLabel: 'Retry',
      actionIcon: Icons.refresh,
      isError: true,
      onAction: (_) => onRetry(),
    ),
    MapPinState.filtered => _MapEmptyCopy(
      key: const Key('map-empty-filtered'),
      icon: Icons.filter_alt_off,
      title: 'Nothing on the map in this view',
      subtitle: 'Your current filters hide every pin.',
      pillLabel: 'No pins',
      actionLabel: 'Clear filters',
      actionIcon: Icons.filter_alt_off,
      onAction: (context) {
        unawaited(HapticFeedback.selectionClick());
        MapActions.clearFilters(context);
      },
    ),
    // The map hides the card while pins are loading, so this is the `none` copy.
    _ => _MapEmptyCopy(
      key: const Key('map-empty-none'),
      icon: Icons.place_outlined,
      title: 'No locations yet',
      subtitle: _noneSubtitle(context),
      pillLabel: 'No pins',
      actionLabel: 'Add setup',
      actionIcon: Icons.add,
      onAction: (context) => unawaited(SetupActions.addSetup(context)),
    ),
  };

  /// Names the other pin sources only while they can actually produce a pin.
  static String _noneSubtitle(BuildContext context) {
    const setups = 'Setups appear here once one is saved with a location.';
    final others = [
      if (MapActions.stravaActive(context)) 'Strava activities',
      if (context.read<AppSettings>().enableRating) 'rating entries',
    ];
    return others.isEmpty ? setups : '$setups\nSame for ${others.join(' and ')}.';
  }
}

class _MapEmptyCopy {
  final Key key;
  final IconData icon;
  final String title;
  final String subtitle;
  final String pillLabel;
  final String actionLabel;
  final IconData actionIcon;
  final bool isError;
  final void Function(BuildContext context) onAction;

  const _MapEmptyCopy({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pillLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.isError = false,
  });
}
