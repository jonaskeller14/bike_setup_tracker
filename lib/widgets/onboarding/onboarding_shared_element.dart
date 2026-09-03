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

/// One element that travels between two adjacent pages.
class OnboardingSharedElement {
  const OnboardingSharedElement({
    required this.flightKey,
    required this.fromPage,
    required this.toPage,
    required this.sourceKey,
    required this.targetKey,
    required this.hidden,
    required this.builder,
  });

  /// Identifies what is painted in flight, so a test can find it.
  final Key flightKey;

  final int fromPage;
  final int toPage;

  final GlobalKey sourceKey;
  final GlobalKey targetKey;

  /// Set while the flight owns the visual, so both endpoints hide themselves.
  final ValueNotifier<bool> hidden;

  /// Builds what is painted in flight, from the transition's 0..1 progress and
  /// the target endpoint's size. The result is laid out at the interpolated
  /// bounds, so it is responsible for handling sizes between the two endpoints.
  final Widget Function(BuildContext context, double progress, Size targetSize) builder;
}

/// Flies elements between [PageView] pages while they scroll.
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
    required this.elements,
    required this.child,
  });

  /// Drives the transitions; every flight tracks [PageController.page].
  final PageController controller;

  /// The elements that can be in flight. Their page pairs do not overlap, so
  /// at most one of them travels at a time.
  final List<OnboardingSharedElement> elements;

  final Widget child;

  @override
  State<OnboardingSharedElementFlight> createState() => _OnboardingSharedElementFlightState();
}

typedef _Flight = ({Rect rect, double progress, Size targetSize});

class _OnboardingSharedElementFlightState extends State<OnboardingSharedElementFlight> {
  final Map<Key, _Flight> _flights = {};
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
    if (_reduceMotion) {
      for (final element in widget.elements) {
        _land(element);
      }
    }
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
  void _land(OnboardingSharedElement element) {
    element.hidden.value = false;
    if (_flights.remove(element.flightKey) != null) setState(() {});
  }

  void _update() {
    if (!mounted || _reduceMotion) return;
    for (final element in widget.elements) {
      _updateElement(element);
    }
  }

  void _updateElement(OnboardingSharedElement element) {
    final progress = _progress(element);
    if (progress == null || progress <= 0 || progress >= 1) {
      _land(element);
      return;
    }

    final source = _boundsOf(element.sourceKey);
    final target = _boundsOf(element.targetKey);
    // Geometry is unavailable for the frame in which the incoming page is
    // first built, and after a resize until it has been laid out again.
    // Retrying after the frame picks the flight up as soon as it is laid out
    // instead of waiting for the next scroll notification.
    if (source == null || target == null) {
      _land(element);
      _retryAfterFrame();
      return;
    }

    element.hidden.value = true;
    setState(() {
      _flights[element.flightKey] = (
        rect: Rect.lerp(source, target, progress)!,
        progress: progress,
        targetSize: target.size,
      );
    });
  }

  void _retryAfterFrame() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      if (mounted) _update();
    });
  }

  double? _progress(OnboardingSharedElement element) {
    final controller = widget.controller;
    if (!controller.hasClients || controller.positions.length != 1) return null;
    final page = controller.page;
    if (page == null) return null;
    return (page - element.fromPage) / (element.toPage - element.fromPage);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        for (final element in widget.elements)
          if (_flights[element.flightKey] case final flight?)
            Positioned.fromRect(
              rect: flight.rect,
              child: IgnorePointer(
                child: KeyedSubtree(
                  key: element.flightKey,
                  child: element.builder(context, flight.progress, flight.targetSize),
                ),
              ),
            ),
      ],
    );
  }
}
