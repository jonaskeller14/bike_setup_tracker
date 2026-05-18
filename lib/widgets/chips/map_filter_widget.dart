import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/subscription_service.dart';
import 'bike_and_tags_filter.dart';
import 'map_display_filter_chip.dart';

class MapFilterWidget extends StatelessWidget {
  const MapFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final subscriptionService = context.watch<SubscriptionService>();
    final stravaActive = appSettings.enableStrava && subscriptionService.hasStravaEntitlement;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          BikeAndTagsFilterChip(enableSetupTagFilter: appSettings.enableSetupTags),
          if (stravaActive) const MapDisplayFilterChip(),
        ],
      ),
    );
  }
}
