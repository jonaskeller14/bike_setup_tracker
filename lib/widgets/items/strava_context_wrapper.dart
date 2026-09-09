import 'package:flutter/material.dart';

import '../../models/timeline_row.dart';

class StravaContextWrapper extends StatelessWidget {
  static const Color stravaOrange = Color(0xFFFC5200);
  static const double barWidth = 4;
  static const double endInset = 3;

  final StravaContext stravaContext;
  final Widget child;

  const StravaContextWrapper({
    super.key,
    required this.stravaContext,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: stravaContext.isFirst ? endInset : 0,
          bottom: stravaContext.isLast ? endInset : 0,
          width: barWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: stravaOrange,
              borderRadius: BorderRadius.vertical(
                top: stravaContext.isFirst ? const Radius.circular(barWidth / 2) : Radius.zero,
                bottom: stravaContext.isLast ? const Radius.circular(barWidth / 2) : Radius.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
