import 'package:flutter/material.dart';
import '../models/component.dart';

class GarageComponentIconCard extends StatelessWidget {
  final Component component;
  final String? componentToShowDetails;

  const GarageComponentIconCard({super.key, required this.component, required this.componentToShowDetails});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = componentToShowDetails == component.id;
    
    return Container(
      key: ValueKey(component.id),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.tertiaryContainer 
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? colorScheme.tertiary 
              : colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected 
            ? [BoxShadow(
                color: colorScheme.tertiary.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )]
            : null,
      ),
      child: Icon(
        component.componentType.getIconData(),
        size: 24,
        color: isSelected 
            ? colorScheme.onTertiaryContainer 
            : colorScheme.onSurface,
      ),
    );
  } 
}
