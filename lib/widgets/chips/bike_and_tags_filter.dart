import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/filtered_data.dart';
import '../sheets/filter.dart';


class BikeAndTagsFilterChip extends StatelessWidget {
  final bool enableSetupTagFilter;

  const BikeAndTagsFilterChip({super.key, required this.enableSetupTagFilter});

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();

    return FilterChip(
      avatar: enableSetupTagFilter
          ? const Icon(Icons.filter_alt_outlined)
          : const Icon(Bike.iconData),
      label: enableSetupTagFilter
          ? filteredData.selectedBike != null
              ? filteredData.selectedSetupTags.isNotEmpty
                  ? Text("${filteredData.bikes[filteredData.selectedBike]?.name ?? ''} + ${filteredData.selectedSetupTags.length} ${filteredData.selectedSetupTags.length > 1 ? 'Tags' : 'Tag'}")
                  : Text(filteredData.bikes[filteredData.selectedBike]?.name ?? '')
              : filteredData.selectedSetupTags.isNotEmpty
                  ? Text("${filteredData.selectedSetupTags.length} ${filteredData.selectedSetupTags.length > 1 ? 'Tags' : 'Tag'}")
                  : const Text("Filter")
          : filteredData.selectedBike == null 
              ? const Text("All Bikes") 
              : Text(filteredData.bikes[filteredData.selectedBike]?.name ?? ''),
      selected: enableSetupTagFilter
          ? filteredData.selectedBike != null || filteredData.selectedSetupTags.isNotEmpty
          : filteredData.selectedBike != null,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(
          context: context,
          enableSetupTagFilter: enableSetupTagFilter,
        );
      },
      onDeleted: enableSetupTagFilter
          ? filteredData.selectedBike == null && filteredData.selectedSetupTags.isEmpty
              ? null 
              : () {
                  filteredData.onBikeTap(null);
                  filteredData.deselectAllSetupTags();
                }
          : filteredData.selectedBike == null
              ? null 
              : () {
                  filteredData.onBikeTap(null);
                },
    );
  }
}
