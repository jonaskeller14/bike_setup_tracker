import 'package:flutter/material.dart';

import '../../models/timeline_row.dart';

class StravaContextWrapper extends StatelessWidget {
  static const Color stravaOrange = Color(0xFFFC5200);
  static const double barWidth = 4;
  static const double endInset = 3;

  final StravaContext stravaContext;
  final Widget child;
  final bool isFirstAndCurrentSetupInSection;
  final bool isLastAndCurrentSetupInSection;

  const StravaContextWrapper({
    super.key,
    required this.stravaContext,
    required this.child,
    this.isFirstAndCurrentSetupInSection = false,
    this.isLastAndCurrentSetupInSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: stravaContext.isFirst && !isFirstAndCurrentSetupInSection ? endInset : 0,
          bottom: stravaContext.isLast && !isLastAndCurrentSetupInSection ? endInset : 0,
          width: barWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: stravaOrange,
              borderRadius: BorderRadius.vertical(
                top: stravaContext.isFirst && !isFirstAndCurrentSetupInSection
                    ? const Radius.circular(barWidth / 2)
                    : Radius.zero,
                bottom: stravaContext.isLast && !isLastAndCurrentSetupInSection
                    ? const Radius.circular(barWidth / 2)
                    : Radius.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
