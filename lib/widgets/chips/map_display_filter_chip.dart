import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../sheets/map_display_filter.dart';

class MapDisplayFilterChip extends StatelessWidget {
  const MapDisplayFilterChip({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    
    // Check if any visible display setting is not in its default state
    final bool isFilterActive = !appSettings.displayShowSetups || 
        (appSettings.enableStrava && !appSettings.displayShowActivities);

    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      avatar: const Icon(Icons.tune),
      label: const Text("Display"),
      showCheckmark: false,
      selected: isFilterActive,
      onSelected: (bool value) async {
        await showMapDisplayFilterSheet(context: context);
      },
      onDeleted: isFilterActive
          ? () {
              appSettings.displayShowSetups = true;
              appSettings.displayShowActivities = true;
            }
          : null,
    );
  }
}
