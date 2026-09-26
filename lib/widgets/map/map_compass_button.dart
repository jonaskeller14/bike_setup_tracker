import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'map_control_button.dart';

/// Shows a north-pointing compass while the map is rotated off north and
/// hides it again once north is up.
class MapCompassButton extends StatelessWidget {
  /// Map rotation in degrees.
  final ValueListenable<double> rotation;

  /// Called with the rotation to animate to so north is up again, taking the
  /// short way round.
  final ValueChanged<double> onResetNorth;

  const MapCompassButton({super.key, required this.rotation, required this.onResetNorth});

  static double _rotationOffNorth(double rotation) {
    final normalized = rotation % 360;
    return normalized > 180 ? normalized - 360 : normalized;
  }

  static Widget _transition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: rotation,
      builder: (context, rotation, _) {
        final offNorth = _rotationOffNorth(rotation);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          reverseDuration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _transition,
          child: offNorth.abs() <= 0.5
              ? const SizedBox.shrink()
              : MapControlButton(
                  key: const Key('map-compass'),
                  icon: Transform.rotate(
                    angle: -rotation * math.pi / 180,
                    child: const Icon(Icons.navigation),
                  ),
                  onPressed: () {
                    unawaited(HapticFeedback.selectionClick());
                    onResetNorth(rotation - offNorth);
                  },
                ),
        );
      },
    );
  }
}
