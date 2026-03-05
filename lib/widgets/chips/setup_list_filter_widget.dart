import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import 'bike_and_tags_filter.dart';
import 'setup_list_map.dart';
import 'setup_list_search.dart';
import 'setup_list_sort.dart';
import 'setup_list_values_filter.dart';

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
          SetupListSort(),
          SetupListSearch(),
          if (appSettings.enableMap)
            SetupListMap(),
          BikeAndTagsFilterChip(enableSetupTagFilter: appSettings.enableSetupTags),
          SetupListValuesFilter(),
        ],
      ),
    );
  }
}
