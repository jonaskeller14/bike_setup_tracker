import 'package:bike_setup_tracker/models/task_rule.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../sheets/filter.dart';

class BikeAndPriorityFilterChip extends StatelessWidget {

  const BikeAndPriorityFilterChip({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final hasPriorityFilter = !setEquals(appRepository.selectedTaskPriorities, TaskPriority.values.toSet());
    final hasTagFilter = appRepository.selectedTaskRuleTags.isNotEmpty;
    final hasBikeFilter = appRepository.selectedBike != null;
    final isFiltered = hasBikeFilter || hasPriorityFilter || hasTagFilter;

    int extraFilters = 0;
    if (hasPriorityFilter) extraFilters++;
    if (hasTagFilter) extraFilters++;

    Widget label;
    if (hasBikeFilter) {
      if (extraFilters > 0) {
        label = Text("${appRepository.bikes[appRepository.selectedBike]?.name ?? ''} + $extraFilters Filter${extraFilters > 1 ? 's' : ''}");
      } else {
        label = Text(appRepository.bikes[appRepository.selectedBike]?.name ?? '');
      }
    } else if (hasPriorityFilter && !hasTagFilter) {
      label = Text("${appRepository.selectedTaskPriorities.length} ${appRepository.selectedTaskPriorities.length > 1 ? 'Priorities' : 'Priority'}");
    } else if (hasTagFilter && !hasPriorityFilter) {
      label = Text("${appRepository.selectedTaskRuleTags.length} ${appRepository.selectedTaskRuleTags.length > 1 ? 'Tags' : 'Tag'}");
    } else if (extraFilters > 0) {
      label = Text("$extraFilters Filters");
    } else {
      label = const Text("Filter");
    }

    return FilterChip(
      avatar: const Icon(Icons.filter_alt_outlined),
      label: label,
      selected: isFiltered,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(
          context: context,
          enableSetupTagFilter: false,
          enableTaskPriorityFilter: true,
          enableTaskRuleTagFilter: true,
        );
      },
      onDeleted: !isFiltered
          ? null 
          : () {
              appRepository.onBikeTap(null);
              appRepository.selectAllTaskPriorities();
              appRepository.deselectAllTaskRuleTags();
            }
    );
  }
}
