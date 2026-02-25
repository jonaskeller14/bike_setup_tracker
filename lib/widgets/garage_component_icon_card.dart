import 'package:flutter/material.dart';
import '../models/component.dart';

class GarageComponentIconCard extends StatelessWidget {
  final Component component;
  final String? componentToShowDetails;

  const GarageComponentIconCard({super.key, required this.component, required this.componentToShowDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(component),
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline), 
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: componentToShowDetails == component.id 
            ? Theme.of(context).colorScheme.tertiaryContainer 
            : Theme.of(context).colorScheme.surface,
      ),
      child: Icon(component.componentType.getIconData()),
    );
  } 
}
