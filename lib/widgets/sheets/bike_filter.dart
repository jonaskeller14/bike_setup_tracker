import 'package:flutter/material.dart';
import '../../models/bike.dart';
import 'sheet.dart';

Future<List<Bike>?> showBikeFilterSheet({required BuildContext context, required Iterable<Bike> bikes, required Bike? selectedBike}) async {
  return showModalBottomSheet<List<Bike>?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
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
                      sheetTitle(context, 'Bike Filter'),
                      sheetCloseButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 6,
                      children: bikes.map((bike) => FilterChip(
                        avatar: const Icon(Bike.iconData),
                        label: Text(bike.name),
                        selected: bike == selectedBike,
                        showCheckmark: false,
                        onSelected: (bool newValue) {
                          switch (newValue) {
                            case true: setSheetState(() => selectedBike = bike);
                            case false: setSheetState(() => selectedBike = null);
                          }
                        },
                        onDeleted: selectedBike != null && selectedBike == bike 
                            ? () => setSheetState(() => selectedBike = null)
                            : null,
                      )).toList(),
                    ),
                  )
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, selectedBike == null ? <Bike>[] : <Bike>[selectedBike!]),
                    child: const Text("Confirm Selection"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
