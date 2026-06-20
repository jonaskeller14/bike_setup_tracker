import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../sheets/filter.dart';

/// The chip that opens the filter/display bottom sheet. Always offers the bike
/// filter; the remaining sections are opt-in per call site via the flags below.
/// Each flag folds one optional sheet section in and makes the chip's highlight
/// + delete reflect (and reset) that section's settings too.
class FilterSheetChip extends StatelessWidget {
  final bool enableSetupTagFilter;
  final bool showMapVisibility;
  final bool showTimelineVisibility;
  final bool showOnlyChangesSection;
  final bool showByCategorySection;

  const FilterSheetChip({
    super.key,
    required this.enableSetupTagFilter,
    this.showMapVisibility = false,
    this.showTimelineVisibility = false,
    this.showOnlyChangesSection = false,
    this.showByCategorySection = false,
  });

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final stravaActive = appSettings.enableStrava &&
        context.watch<SubscriptionService>().hasStravaEntitlement;

    // Whether any folded-in display section differs from its defaults.
    final bool visibilityActive = (showMapVisibility || showTimelineVisibility) &&
        (!appSettings.displayShowSetups ||
            (stravaActive && !appSettings.displayShowActivities) ||
            (showTimelineVisibility && appSettings.enableTask && !appSettings.displayShowTasks) ||
            (showTimelineVisibility && appSettings.enableInstallationTimeline && !appSettings.displayShowInstallations) ||
            (showTimelineVisibility && appSettings.enableRating && !appSettings.displayShowRatingEntries));
    final bool onlyChangesActive = showOnlyChangesSection && appSettings.setupListOnlyChanges;
    final bool byCategoryActive = showByCategorySection &&
        (!appSettings.setupListBikeAdjustmentValues ||
            (appSettings.enablePerson && !appSettings.setupListPersonAdjustmentValues));
    final bool displayActive = visibilityActive || onlyChangesActive || byCategoryActive;

    void resetDisplay() {
      if (showMapVisibility || showTimelineVisibility) {
        appSettings.displayShowSetups = true;
        appSettings.displayShowActivities = true;
      }
      if (showTimelineVisibility) {
        appSettings.displayShowTasks = true;
        appSettings.displayShowInstallations = true;
        appSettings.displayShowRatingEntries = true;
      }
      if (showOnlyChangesSection) appSettings.setupListOnlyChanges = false;
      if (showByCategorySection) {
        appSettings.setupListBikeAdjustmentValues = true;
        appSettings.setupListPersonAdjustmentValues = true;
      }
    }

    final bool filterActive = enableSetupTagFilter
        ? appRepository.selectedBike != null || appRepository.selectedSetupTags.isNotEmpty
        : appRepository.selectedBike != null;

    final bool bikeOnly = !enableSetupTagFilter &&
        !showMapVisibility &&
        !showTimelineVisibility &&
        !showOnlyChangesSection &&
        !showByCategorySection;

    final bool bikeSelected = appRepository.selectedBike != null;
    final String bikeName = appRepository.bikes[appRepository.selectedBike]?.name ?? '';
    final int tagCount = appRepository.selectedSetupTags.length;
    final String tagLabel = "$tagCount ${tagCount > 1 ? 'Tags' : 'Tag'}";

    String labelText;
    if (bikeOnly) {
      labelText = bikeSelected ? bikeName : "All Bikes";
    } else if (enableSetupTagFilter) {
      if (bikeSelected && tagCount > 0) {
        labelText = "$bikeName + $tagLabel";
      } else if (bikeSelected) {
        labelText = bikeName;
      } else if (tagCount > 0) {
        labelText = tagLabel;
      } else {
        labelText = "Filter";
      }
    } else {
      labelText = bikeSelected ? bikeName : "Filter";
    }

    return FilterChip(
      avatar: bikeOnly
          ? const Icon(Bike.iconData)
          : const Icon(Icons.filter_alt_outlined),
      label: Text(
        labelText,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selected: filterActive || displayActive,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(
          context: context,
          enableSetupTagFilter: enableSetupTagFilter,
          enableTaskPriorityFilter: false,
          showMapVisibility: showMapVisibility,
          showTimelineVisibility: showTimelineVisibility,
          showOnlyChangesSection: showOnlyChangesSection,
          showByCategorySection: showByCategorySection,
        );
      },
      onDeleted: filterActive || displayActive
          ? () {
              appRepository.onBikeTap(null);
              if (enableSetupTagFilter) appRepository.deselectAllSetupTags();
              resetDisplay();
            }
          : null,
    );
  }
}
