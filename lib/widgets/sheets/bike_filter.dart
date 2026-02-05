import 'package:flutter/material.dart';
import '../../models/bike.dart';
import 'sheet.dart';

Future<List<String>?> showBikeFilterSheet({required BuildContext context, required Iterable<Bike> bikes, required String? selectedBike}) async {
  return showModalBottomSheet<List<String>?>(
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
                    child: bikes.isEmpty 
                        ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text("No bikes yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
                        )
                        : Wrap(
                            spacing: 6,
                            children: bikes.map((bike) => FilterChip(
                              avatar: const Icon(Bike.iconData),
                              label: Text(bike.name),
                              selected: bike.id == selectedBike,
                              showCheckmark: false,
                              onSelected: (bool newValue) {
                                switch (newValue) {
                                  case true: setSheetState(() => selectedBike = bike.id);
                                  case false: setSheetState(() => selectedBike = null);
                                }
                              },
                              onDeleted: selectedBike != null && selectedBike == bike.id 
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
                    onPressed: bikes.isEmpty
                        ? null 
                        : () => Navigator.pop(context, selectedBike == null ? <String>[] : <String>[selectedBike!]),
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
