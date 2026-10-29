import 'package:flutter/material.dart';

class SheetSectionTitle extends StatelessWidget {
  final String title;
  final IconData? iconData;

  const SheetSectionTitle({super.key, required this.title, this.iconData});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
    );
    return Padding(
      padding: const EdgeInsetsGeometry.only(top: 12, bottom: 6),
      child: iconData == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Icon(iconData, size: 18),
                Flexible(child: label),
              ],
            ),
    );
  }
}
