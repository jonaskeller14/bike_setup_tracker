import 'package:flutter/material.dart';

import 'filter_sheet_chip.dart';

class MapFilterWidget extends StatelessWidget {
  const MapFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          FilterSheetChip.map,
        ],
      ),
    );
  }
}
