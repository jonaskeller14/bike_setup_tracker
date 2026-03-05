import 'package:flutter/material.dart';
import '../../pages/map_page.dart';

class SetupListMap extends StatelessWidget {
  const SetupListMap({super.key});

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
        await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => MapPage()));
      },
    );
  }
}