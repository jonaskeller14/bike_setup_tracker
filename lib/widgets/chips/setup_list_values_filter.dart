import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/subscription_service.dart';
import '../sheets/setup_list_values_filter.dart';

class SetupListDisplayFilterChip extends StatelessWidget {
  const SetupListDisplayFilterChip({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();
    final stravaActive = appSettings.enableStrava && subscriptionService.hasStravaEntitlement;

    final bool isFilterActive = appSettings.setupListOnlyChanges ||
        !appSettings.setupListBikeAdjustmentValues ||
        !appSettings.setupListPersonAdjustmentValues ||
        !appSettings.setupListRatingAdjustmentValues ||
        !appSettings.displayShowSetups ||
        (stravaActive && !appSettings.displayShowActivities) ||
        (appSettings.enableInstallationTimeline && !appSettings.displayShowInstallations) ||
        (appSettings.enableTask && !appSettings.displayShowTasks);

    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      avatar: const Icon(Icons.tune),
      label: const Text("Display"),
      showCheckmark: false,
      selected: isFilterActive,
      onSelected: (bool value) async {
        await showSetupListDisplayFilterSheet(context: context);
      },
      onDeleted: isFilterActive
          ? () {
              appSettings.setupListOnlyChanges = false;
              appSettings.setupListBikeAdjustmentValues = true;
              appSettings.setupListPersonAdjustmentValues = true;
              appSettings.setupListRatingAdjustmentValues = true;
              appSettings.displayShowSetups = true;
              appSettings.displayShowActivities = true;
              appSettings.displayShowInstallations = true;
              appSettings.displayShowTasks = true;
            }
          : null,
    );
  }
}