import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';

class SetupListSort extends StatelessWidget {
  const SetupListSort({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      labelPadding: const EdgeInsets.symmetric(vertical: 2),
      avatar: appRepository.stravaSortAscending 
          ? const Icon(Icons.arrow_upward) 
          : const Icon(Icons.arrow_downward),
      label: const SizedBox.shrink(), 
      onSelected: (bool value) => appRepository.setStravaSortOrder(value),
      selected: appRepository.stravaSortAscending,
      showCheckmark: false,
    );
  }
}