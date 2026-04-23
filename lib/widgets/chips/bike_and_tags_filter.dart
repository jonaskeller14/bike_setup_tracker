import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';
import '../sheets/filter.dart';

class BikeAndTagsFilterChip extends StatelessWidget {
  final bool enableSetupTagFilter;

  const BikeAndTagsFilterChip({super.key, required this.enableSetupTagFilter});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    return FilterChip(
      avatar: enableSetupTagFilter
          ? const Icon(Icons.filter_alt_outlined)
          : const Icon(Bike.iconData),
      label: enableSetupTagFilter
          ? appRepository.selectedBike != null
              ? appRepository.selectedSetupTags.isNotEmpty
                  ? Text("${appRepository.bikes[appRepository.selectedBike]?.name ?? ''} + ${appRepository.selectedSetupTags.length} ${appRepository.selectedSetupTags.length > 1 ? 'Tags' : 'Tag'}")
                  : Text(appRepository.bikes[appRepository.selectedBike]?.name ?? '')
              : appRepository.selectedSetupTags.isNotEmpty
                  ? Text("${appRepository.selectedSetupTags.length} ${appRepository.selectedSetupTags.length > 1 ? 'Tags' : 'Tag'}")
                  : const Text("Filter")
          : appRepository.selectedBike == null 
              ? const Text("All Bikes") 
              : Text(appRepository.bikes[appRepository.selectedBike]?.name ?? ''),
      selected: enableSetupTagFilter
          ? appRepository.selectedBike != null || appRepository.selectedSetupTags.isNotEmpty
          : appRepository.selectedBike != null,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(
          context: context,
          enableSetupTagFilter: enableSetupTagFilter,
          enableTaskPriorityFilter: false,
        );
      },
      onDeleted: enableSetupTagFilter
          ? appRepository.selectedBike == null && appRepository.selectedSetupTags.isEmpty
              ? null 
              : () {
                  appRepository.onBikeTap(null);
                  appRepository.deselectAllSetupTags();
                }
          : appRepository.selectedBike == null
              ? null 
              : () {
                  appRepository.onBikeTap(null);
                },
    );
  }
}
