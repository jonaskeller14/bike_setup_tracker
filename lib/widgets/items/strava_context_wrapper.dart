import 'package:flutter/material.dart';
import '../../utils/timeline_grouping.dart';

class StravaContextWrapper extends StatelessWidget {
  static const Color stravaOrange = Color(0xFFFC5200);
  static const double _barWidth = 4;
  static const double _contentInset = 10;
  static const double _endInset = 3;

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
        Positioned(
          left: 0,
          top: stravaContext.isFirst ? _endInset : 0,
          bottom: stravaContext.isLast ? _endInset : 0,
          width: _barWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: stravaOrange,
              borderRadius: BorderRadius.vertical(
                top: stravaContext.isFirst ? const Radius.circular(_barWidth / 2) : Radius.zero,
                bottom: stravaContext.isLast ? const Radius.circular(_barWidth / 2) : Radius.zero,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _barWidth + _contentInset),
          child: child,
        ),
      ],
    );
  }
}
