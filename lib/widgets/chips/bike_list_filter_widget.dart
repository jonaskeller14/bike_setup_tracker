import 'package:flutter/material.dart';

import 'filter_sheet_chip.dart';

class BikeListFilterWidget extends StatelessWidget {
  const BikeListFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          FilterSheetChip(enableSetupTagFilter: false),
        ],
      ),
    );
  }
}
