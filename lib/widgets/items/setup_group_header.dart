import 'package:flutter/material.dart';

import '../../models/setup.dart';

class SetupGroupHeader extends StatelessWidget {
  final int setupCount;
  final String dateTimeText;
  final Widget bikeMetadata;
  final List<Widget> contextMetadata;
  final bool selected;

  const SetupGroupHeader({
    super.key,
    required this.setupCount,
    required this.dateTimeText,
    required this.bikeMetadata,
    required this.contextMetadata,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final selectedColor = selected ? Theme.of(context).colorScheme.primary : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Setup.iconData, color: selectedColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$setupCount Setups',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: selectedColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          dateTimeText,
                          style: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                        bikeMetadata,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (contextMetadata.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: contextMetadata,
              ),
            ),
        ],
      ),
    );
  }
}
