import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/filter_actions.dart';
import '../sheets/filter.dart';

class FilterSheetChip extends StatelessWidget {
  static const garageList = FilterSheetChip._({FilterSection.bike});
  static const setupList = FilterSheetChip._({
    FilterSection.bike,
    FilterSection.dateRange,
    FilterSection.setups,
    FilterSection.activity,
    FilterSection.timelineLayers,
  });
  static const personList = FilterSheetChip._({FilterSection.bike});
  static const ratingList = FilterSheetChip._({FilterSection.bike});
  static const taskList = FilterSheetChip._({FilterSection.bike, FilterSection.taskPriority, FilterSection.taskTags});
  static const map = FilterSheetChip._({
    FilterSection.bike,
    FilterSection.dateRange,
    FilterSection.setups,
    FilterSection.activity,
    FilterSection.mapLayers,
  });
  static const calendar = FilterSheetChip._({
    FilterSection.bike,
    FilterSection.dateRange,
    FilterSection.setups,
    FilterSection.activity,
    FilterSection.timelineLayers,
  });
  static const componentDetailsPage = FilterSheetChip._({
    FilterSection.bike,
    FilterSection.dateRange,
    FilterSection.setups,
  });
  static const bikeDetailsPage = FilterSheetChip._({FilterSection.setups});

  final Set<FilterSection> sections;

  const FilterSheetChip._(this.sections);

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final stravaActive = appSettings.enableStrava &&
        context.watch<SubscriptionService>().hasStravaEntitlement;

    final enabled = FilterActions.enabledSections(sections, appSettings: appSettings, stravaActive: stravaActive);
    final showBikeOnly = enabled.length == 1 && enabled.contains(FilterSection.bike);

    final labels = FilterActions.activeLabels(
      sections,
      appRepository: appRepository,
      appSettings: appSettings,
      stravaActive: stravaActive,
    );
    final selected = labels.isNotEmpty;

    String labelText;
    if (selected) {
      labelText = labels.join(" + ");
    } else {
      labelText = showBikeOnly ? "All Bikes" : "Filter";
    }

    return FilterChip(
      avatar: showBikeOnly
          ? const Icon(Bike.iconData)
          : const Icon(Icons.filter_alt_outlined),
      label: Text(
        labelText,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(context: context, sections: sections);
      },
      onDeleted: selected ? () => FilterActions.clear(context, sections) : null,
    );
  }
}
