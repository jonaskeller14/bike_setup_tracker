import 'package:flutter/material.dart';

import '../../models/setup.dart';

class SetupGroupHeader extends StatelessWidget {
  final int setupCount;

  /// Replaces "N Setups", e.g. with the name of a test session.
  final String? title;
  final IconData iconData;
  final String dateTimeText;
  final Widget bikeMetadata;
  final List<Widget> contextMetadata;
  final bool selected;

  /// Replaces the [iconData] icon, e.g. with an animated one.
  final Widget? leading;

  /// Right after the title, e.g. a status badge.
  final Widget? badge;

  /// At the end of the title row, e.g. an options menu.
  final Widget? trailing;

  const SetupGroupHeader({
    super.key,
    required this.setupCount,
    this.title,
    this.iconData = Setup.iconData,
    required this.dateTimeText,
    required this.bikeMetadata,
    required this.contextMetadata,
    this.selected = false,
    this.leading,
    this.badge,
    this.trailing,
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
                child: leading ?? Icon(iconData, color: selectedColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: Text(
                            title ?? '$setupCount Setups',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: selectedColor),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ?badge,
                      ],
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
              ?trailing,
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
