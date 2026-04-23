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

    return FilterChip(
      avatar: const Icon(Icons.filter_alt_outlined),
      label: appRepository.selectedBike != null
          ? !setEquals(appRepository.selectedTaskPriorities, TaskPriority.values.toSet())
              ? Text("${appRepository.bikes[appRepository.selectedBike]?.name ?? ''} + ${appRepository.selectedTaskPriorities.length} ${appRepository.selectedTaskPriorities.length > 1 ? 'Priorities' : 'Priority'}")
              : Text(appRepository.bikes[appRepository.selectedBike]?.name ?? '')
          : !setEquals(appRepository.selectedTaskPriorities, TaskPriority.values.toSet())
              ? Text("${appRepository.selectedTaskPriorities.length} ${appRepository.selectedTaskPriorities.length > 1 ? 'Priorities' : 'Priority'}")
              : const Text("Filter"),
      selected: appRepository.selectedBike != null || !setEquals(appRepository.selectedTaskPriorities, TaskPriority.values.toSet()),
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(
          context: context,
          enableSetupTagFilter: false,
          enableTaskPriorityFilter: true,
        );
      },
      onDeleted: appRepository.selectedBike == null && setEquals(appRepository.selectedTaskPriorities, TaskPriority.values.toSet())
          ? null 
          : () {
              appRepository.onBikeTap(null);
              appRepository.selectAllTaskPriorities();
            }
    );
  }
}
