import 'package:flutter/material.dart';
import '../../models/setup.dart';
import '../../pages/map_page.dart';

class SetupListMap extends StatelessWidget {
  final Future<void> Function(Setup) editSetup;

  const SetupListMap({super.key, required this.editSetup});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: const SizedBox.shrink(),
      labelPadding: EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.zero,
      avatar: Icon(Icons.map_outlined),
      showCheckmark: false,
      selected: false,
      onSelected: (_) async {
        await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => MapPage(
          editSetup: editSetup,
        )));
      },
    );
  }
}