import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';

class SetupListSort extends StatelessWidget {
  const SetupListSort({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      labelPadding: EdgeInsets.symmetric(vertical: 2),
      avatar: appSettings.setupListSortAscending 
          ? const Icon(Icons.arrow_upward) 
          : const Icon(Icons.arrow_downward),
      label: const SizedBox.shrink(), 
      onSelected: (bool value) => appSettings.setupListSortAscending = value,
      selected: appSettings.setupListSortAscending,
      showCheckmark: false,
    );
  }
}