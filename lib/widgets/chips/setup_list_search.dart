import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/filtered_data.dart';
import '../../models/setup.dart';
import '../../pages/setup_display_page.dart';
import '../setup_list_card.dart';

class SetupListSearch extends StatelessWidget {
  final Future<void> Function(Setup setup) editSetup;
  final Future<void> Function(Setup setup) restoreSetup;
  final Future<void> Function(Setup setup) removeSetup;

  const SetupListSearch({
    super.key, 
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
  });

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder:(context, controller) {
        return FilterChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // label: Text(controller.text),
          label: const SizedBox.shrink(),
          labelPadding: EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.zero,
          avatar: Icon(Icons.search),
          showCheckmark: false,
          // selected: controller.text.isNotEmpty,
          selected: false,
          onSelected: (bool newValue) {controller.text = ""; controller.openView();},
          // onDeleted: controller.text.isEmpty ? null : () => setState(() => controller.text = ""),
        );
      },
      viewBuilder: (Iterable<Widget> suggestions) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) => suggestions.elementAt(index),
        );
      },
      suggestionsBuilder: (context, controller) {
        final appSettings = context.read<AppSettings>();
        final filteredData = context.read<FilteredData>();

        final controllerText = controller.text.trim().toLowerCase();
        final Iterable<Setup> setups = appSettings.setupListSortAscending
            ? filteredData.filteredSetups.values
            : filteredData.filteredSetups.values.toList().reversed;
        final Iterable<Setup> suggestedSetups = setups.where((s) {
          return s.name.toLowerCase().contains(controllerText) || 
              (s.notes ?? "").toLowerCase().contains(controllerText);
        });

        return suggestedSetups.map((setup) {
          return SetupListCard(
            setupId: setup.id, 
            onTap: () async {
              await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                setupIds: suggestedSetups.map((s) => s.id).toList(),
                initialSetup: setup,
                editSetup: editSetup,
              )));
            },
            editSetup: editSetup, 
            restoreSetup: restoreSetup, 
            removeSetup: removeSetup, 
            displayOnlyChanges: appSettings.setupListOnlyChanges, 
            displayBikeAdjustmentValues:appSettings.setupListBikeAdjustmentValues, 
            displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues, 
            displayRatingAdjustmentValues: appSettings.setupListRatingAdjustmentValues,
          );
        });
      },
    );
  }
}
