import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../sheets/setup_list_values_filter.dart';

class SetupListValuesFilter extends StatelessWidget {
  const SetupListValuesFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      avatar: const Icon(Icons.list_alt),
      label: const Text("Values"),
      showCheckmark: false,
      selected: appSettings.setupListOnlyChanges || 
          !appSettings.setupListBikeAdjustmentValues || 
          !appSettings.setupListPersonAdjustmentValues || 
          !appSettings.setupListRatingAdjustmentValues,
      onSelected: (bool value) async {
        await showSetupListValuesFilterSheet(context: context);
      },
      onDeleted: appSettings.setupListOnlyChanges || 
          !appSettings.setupListBikeAdjustmentValues || 
          !appSettings.setupListPersonAdjustmentValues || 
          !appSettings.setupListRatingAdjustmentValues
          ? () {
              appSettings.setupListOnlyChanges = false;
              appSettings.setupListBikeAdjustmentValues = true;
              appSettings.setupListPersonAdjustmentValues = true;
              appSettings.setupListRatingAdjustmentValues = true;
            }
          : null,
    );
  }
}