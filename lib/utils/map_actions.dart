import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/rating/rating_entry.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../pages/map_page.dart';
import '../services/subscription_service.dart';
import 'url.dart';

typedef ExternalMapTarget = ({String label, double latitude, double longitude, String displayName});

class MapActions {
  static Future<void> openActivityOnMap(BuildContext context, StravaActivity activity) async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => MapPage(focusActivity: activity)));
  }

  static Future<void> openSetupsOnMap(BuildContext context, List<Setup> setups) async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => MapPage(focusSetups: setups)));
  }

  static Future<void> openRatingEntryOnMap(BuildContext context, RatingEntry ratingEntry) async {
    unawaited(HapticFeedback.selectionClick());
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => MapPage(focusRatingEntry: ratingEntry)),
    );
  }

  static Future<void> showOpenMapMenu(
    BuildContext context, {
    required Offset globalPosition,
    required VoidCallback? onViewOnMap,
    required List<ExternalMapTarget> externalTargets,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(globalPosition & Size.zero, Offset.zero & overlay.size),
      items: [
        if (onViewOnMap != null) _openMapMenuItem(icon: Icons.map, label: 'View on map', value: onViewOnMap),
        for (final target in externalTargets)
          _openMapMenuItem(
            icon: Icons.directions,
            label: target.label,
            value: () => launchLocationOnMap(context, target.latitude, target.longitude, target.displayName),
          ),
      ],
    );
    if (!context.mounted) return;
    selected?.call();
  }

  static PopupMenuItem<VoidCallback> _openMapMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback value,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        spacing: 10,
        children: [
          Icon(icon),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  /// Whether Strava activities can appear on the map at all.
  static bool stravaActive(BuildContext context) =>
      context.read<AppSettings>().enableStrava && context.read<SubscriptionService>().hasStravaEntitlement;
}
