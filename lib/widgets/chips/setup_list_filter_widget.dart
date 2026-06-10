import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import 'filter_sheet_chip.dart';
import 'setup_list_calendar.dart';
import 'setup_list_map.dart';
import 'setup_list_search.dart';
import 'setup_list_sort.dart';

class SetupListFilterWidget extends StatelessWidget {
  const SetupListFilterWidget({
    super.key, 
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          const SetupListSort(),
          const SetupListSearch(),
          const SetupListMap(),
          if (appSettings.enableCalendar) const SetupListCalendar(),
          FilterSheetChip(
            enableSetupTagFilter: appSettings.enableSetupTags,
            showTimelineVisibility: true,
            showOnlyChangesSection: true,
            showByCategorySection: true,
          ),
        ],
      ),
    );
  }
}
