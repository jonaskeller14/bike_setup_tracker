import 'package:flutter/material.dart';

import '../dashed_border_painter.dart';

class GarageAddComponentButton extends StatelessWidget {
  final VoidCallback onTap;
  final double width;
  final String? label;
  final String? semanticsIdentifier;

  const GarageAddComponentButton({
    super.key,
    required this.onTap,
    required this.width,
    this.label,
    this.semanticsIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      child: Semantics(
        container: true,
        identifier: semanticsIdentifier,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1.0,
              dashWidth: 6,
              dashSpace: 4,
              borderRadius: 12,
            ),
            child: Padding(
              // The painted border takes no layout space; 11 matches the component cards (border 1 + padding 10).
              padding: const EdgeInsets.all(11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(Icons.add, size: 24, color: color),
                  if (label != null)
                    Flexible(
                      child: Text(
                        label!,
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
