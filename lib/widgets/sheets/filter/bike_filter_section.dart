import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/bike.dart';
import '../../../repositories/app_repository.dart';
import '../../text/sheet_section_title.dart';
import '../sheet.dart';

class BikeFilterSection extends StatelessWidget {
  const BikeFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final filters = appRepository.filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetSectionTitle(title: "Bike"),
        appRepository.bikes.isEmpty
            ? const SheetFilterEmptyHint(
                icon: Bike.iconData,
                title: "No bikes yet",
                hint: "Add a bike to filter this list by bike.",
              )
            : Wrap(
                spacing: 6,
                children: appRepository.bikes.values
                    .map(
                      (bike) => FilterChip(
                        avatar: const Icon(Bike.iconData),
                        label: Text(bike.name),
                        selected: bike.id == filters.bikeId,
                        showCheckmark: false,
                        onSelected: (_) => filters.toggleBike(bike.id),
                        onDeleted: bike.id == filters.bikeId ? () => filters.toggleBike(bike.id) : null,
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }
}
