import 'package:flutter/material.dart';

import '../../pages/map_page.dart';
import '../../utils/automation_ids.dart';

class SetupListMap extends StatelessWidget {
  const SetupListMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: AutomationIds.setupListMap,
      child: FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: const SizedBox.shrink(),
        labelPadding: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.zero,
        avatar: const Icon(Icons.map_outlined),
        showCheckmark: false,
        selected: false,
        onSelected: (_) async {
          await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const MapPage()));
        },
      ),
    );
  }
}