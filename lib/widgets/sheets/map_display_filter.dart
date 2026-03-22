import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import 'sheet.dart';

Future<void> showMapDisplayFilterSheet({required BuildContext context}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) => const MapDisplayFilterSheetContent(),
  );
}

class MapDisplayFilterSheetContent extends StatelessWidget {
  const MapDisplayFilterSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sheetTitle(context, 'Display Options'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Visibility", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            FilterChip(
                              label: const Text("Setups"),
                              showCheckmark: false,
                              selected: appSettings.displayShowSetups,
                              onSelected: (bool selected) => appSettings.displayShowSetups = selected,
                              onDeleted: appSettings.displayShowSetups
                                  ? () => appSettings.displayShowSetups = false
                                  : null
                            ),
                            if (appSettings.enableStrava)
                              FilterChip(
                                label: const Text("Strava Activities"),
                                showCheckmark: false,
                                selected: appSettings.displayShowActivities,
                                onSelected: (bool selected) => appSettings.displayShowActivities = selected,
                                onDeleted: appSettings.displayShowActivities
                                    ? () => appSettings.displayShowActivities = false
                                    : null
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
