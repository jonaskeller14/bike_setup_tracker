import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Marks a widget as one end of a shared-element flight.
///
/// The endpoint keeps occupying its layout slot while it is hidden, so the
/// flight can keep reading its geometry and the surrounding slide never
/// reflows mid-transition.
class SharedElementEndpoint extends StatelessWidget {
  const SharedElementEndpoint({
    super.key,
    this.endpointKey,
    this.hidden,
    required this.child,
  });

  /// Identifies this endpoint's render box. When null the widget is inert,
  /// so slides can still be built standalone (previews, isolated tests).
  final GlobalKey? endpointKey;

  /// True while the flight paints this element itself.
  final ValueListenable<bool>? hidden;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final endpointKey = this.endpointKey;
    final hidden = this.hidden;
    if (endpointKey == null || hidden == null) return child;

    return ValueListenableBuilder<bool>(
      valueListenable: hidden,
      builder: (context, isHidden, child) => Visibility.maintain(
        visible: !isHidden,
        child: child!,
      ),
      child: KeyedSubtree(key: endpointKey, child: child),
    );
  }
}

/// Flies a single element between two [PageView] pages while they scroll.
///
/// A route [Hero] cannot be used here: both endpoints live inside the same
/// route, and the flight has to follow an interactive swipe rather than a
/// fixed route transition. Instead the element is painted in a stack above
/// the page view and positioned by interpolating the two endpoints' live
/// geometry.
///
/// Interpolating *live* geometry is what makes the element ignore the page
/// scroll: the horizontal shift the endpoints inherit from the scroll cancels
/// out in the interpolation, so the element glides between the two resting
/// positions no matter how the swipe is driven, interrupted, or reversed.
class OnboardingSharedElementFlight extends StatefulWidget {
  const OnboardingSharedElementFlight({
    super.key,
    required this.controller,
    required this.fromPage,
    required this.toPage,
    required this.sourceKey,
    required this.targetKey,
    required this.hidden,
    required this.flight,
    required this.child,
  });

  /// Drives the transition; the flight tracks [PageController.page].
  final PageController controller;

  final int fromPage;
  final int toPage;

  final GlobalKey sourceKey;
  final GlobalKey targetKey;

  /// Set while the flight owns the visual, so both endpoints hide themselves.
  final ValueNotifier<bool> hidden;

  /// What is painted in flight. Scaled to fit the interpolated bounds.
  final Widget flight;

  final Widget child;

  static const Key flightKey = ValueKey('onboarding_shared_element_flight');

  @override
  State<OnboardingSharedElementFlight> createState() => _OnboardingSharedElementFlightState();
}

class _OnboardingSharedElementFlightState extends State<OnboardingSharedElementFlight> {
  Rect? _rect;
  bool _reduceMotion = false;
  bool _retryScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    _reduceMotion = mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    if (_reduceMotion) _land();
  }

  @override
  void didUpdateWidget(covariant OnboardingSharedElementFlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  /// Hands the element back to its endpoints and stops painting it.
  void _land() {
    widget.hidden.value = false;
    if (_rect != null) setState(() => _rect = null);
  }

  void _update() {
    if (!mounted || _reduceMotion) return;

    final progress = _progress();
    if (progress == null || progress <= 0 || progress >= 1) {
      _land();
      return;
    }

    final source = _boundsOf(widget.sourceKey);
    final target = _boundsOf(widget.targetKey);
    // Geometry is unavailable for the frame in which the incoming page is
    // first built, and after a resize until it has been laid out again.
    // Retrying after the frame picks the flight up as soon as it is laid out
    // instead of waiting for the next scroll notification.
    if (source == null || target == null) {
      _land();
      _retryAfterFrame();
      return;
    }

    widget.hidden.value = true;
    setState(() => _rect = Rect.lerp(source, target, progress));
  }

  void _retryAfterFrame() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      if (mounted) _update();
    });
  }

  double? _progress() {
    final controller = widget.controller;
    if (!controller.hasClients || controller.positions.length != 1) return null;
    final page = controller.page;
    if (page == null) return null;
    return (page - widget.fromPage) / (widget.toPage - widget.fromPage);
  }

  /// The endpoint's bounds in this widget's own coordinate space.
  Rect? _boundsOf(GlobalKey key) {
    final self = context.findRenderObject();
    final endpoint = key.currentContext?.findRenderObject();
    if (self is! RenderBox || endpoint is! RenderBox) return null;
    if (!self.attached || !endpoint.attached || !self.hasSize || !endpoint.hasSize) return null;

    return endpoint.localToGlobal(Offset.zero, ancestor: self) & endpoint.size;
  }

  @override
  Widget build(BuildContext context) {
    final rect = _rect;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (rect != null)
          Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: FittedBox(
                key: OnboardingSharedElementFlight.flightKey,
                fit: BoxFit.fill,
                child: widget.flight,
              ),
            ),
          ),
      ],
    );
  }
}
