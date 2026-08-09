import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import 'filter_sheet_chip.dart';

class MapFilterWidget extends StatelessWidget {
  const MapFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          FilterSheetChip(
            enableSetupTagFilter: appSettings.enableSetupTags,
            showMapVisibility: true,
          ),
        ],
      ),
    );
  }
}
