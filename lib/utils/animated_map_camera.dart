import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Animates a [MapController]'s camera. A new move or rotation replaces the
/// one still running.
class AnimatedMapCamera {
  static const Duration _duration = Duration(milliseconds: 500);

  final MapController _mapController;
  final TickerProvider _vsync;
  AnimationController? _moveController;
  AnimationController? _rotateController;

  AnimatedMapCamera(this._mapController, this._vsync);

  Future<void> move(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    _moveController?.dispose();
    final controller = _moveController = AnimationController(duration: _duration, vsync: _vsync);
    return _run(
      controller,
      onTick: (animation) => _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      ),
      onDone: () {
        if (identical(_moveController, controller)) _moveController = null;
      },
    );
  }

  Future<void> rotate(double destRotation) {
    final rotationTween = Tween<double>(begin: _mapController.camera.rotation, end: destRotation);

    _rotateController?.dispose();
    final controller = _rotateController = AnimationController(duration: _duration, vsync: _vsync);
    return _run(
      controller,
      onTick: (animation) => _mapController.rotate(rotationTween.evaluate(animation)),
      onDone: () {
        if (identical(_rotateController, controller)) _rotateController = null;
      },
    );
  }

  Future<void> _run(
    AnimationController controller, {
    required void Function(Animation<double> animation) onTick,
    required VoidCallback onDone,
  }) async {
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    controller.addListener(() => onTick(animation));
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        onDone();
      }
    });

    try {
      await controller.forward().orCancel;
    } on TickerCanceled {
      // The owner was disposed while the camera was moving.
    }
  }

  void dispose() {
    _moveController?.dispose();
    _rotateController?.dispose();
  }
}
