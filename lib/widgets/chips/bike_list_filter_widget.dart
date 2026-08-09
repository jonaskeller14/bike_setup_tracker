import 'package:flutter/material.dart';

import 'filter_sheet_chip.dart';

class BikeListFilterWidget extends StatelessWidget {
  const BikeListFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 8),
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
