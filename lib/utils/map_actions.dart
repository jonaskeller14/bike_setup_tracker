import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../services/subscription_service.dart';

class MapActions {
  /// Whether the map filters currently narrow what the map can show.
  ///
  /// Shared by the map's filter chip and its empty-state placeholder so the
  /// chip's reset and the placeholder's "Clear filters" can't drift apart.
  static bool isFiltered({
    required AppRepository appRepository,
    required AppSettings appSettings,
    required bool stravaActive,
  }) {
    final visibilityFiltered =
        _showsVisibility(appSettings, stravaActive: stravaActive) &&
        (!appSettings.displayShowSetups ||
            (stravaActive && !appSettings.displayShowActivities) ||
            (appSettings.enableRating && !appSettings.displayShowRatingEntries));

    return appRepository.selectedBike != null ||
        (appSettings.enableSetupTags && appRepository.selectedSetupTags.isNotEmpty) ||
        (appSettings.enableSetupBookmark && appRepository.showBookmarkedSetupsOnly) ||
        visibilityFiltered;
  }

  /// Resets every filter [isFiltered] reports on.
  static void clearFilters(BuildContext context) {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();

    appRepository.onBikeTap(null);
    if (appSettings.enableSetupTags) appRepository.deselectAllSetupTags();
    if (appSettings.enableSetupBookmark) appRepository.setShowBookmarkedSetupsOnly(false);

    if (_showsVisibility(appSettings, stravaActive: stravaActive(context))) {
      appSettings.displayShowSetups = true;
      appSettings.displayShowActivities = true;
      appSettings.displayShowRatingEntries = true;
    }
  }

  /// Whether Strava activities can appear on the map at all.
  static bool stravaActive(BuildContext context) =>
      context.read<AppSettings>().enableStrava && context.read<SubscriptionService>().hasStravaEntitlement;

  /// The map filter sheet only offers the layer toggles when a layer other than
  /// setups can be shown at all.
  static bool _showsVisibility(AppSettings appSettings, {required bool stravaActive}) =>
      appSettings.enableRating || stravaActive;
}
