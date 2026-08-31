import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Lays out [header] above [content] like a column, but while the section
/// straddles the top of the enclosing scrollable the header is shifted down
/// so it stays visible ("pinned"), clamped to the section's own bounds so the
/// next section pushes it out.
///
/// Box-protocol replacement for a `PinnedHeaderSliver` per section: because a
/// [StickySection] is an ordinary box, whole sections can be children of one
/// lazy `SliverList` — only near-viewport sections are ever built, instead of
/// one eager sliver group per section. The header should paint an opaque
/// background, since the section's own content scrolls beneath it while it is
/// pinned.
class StickySection extends MultiChildRenderObjectWidget {
  StickySection({super.key, required Widget header, required Widget content})
      // Content first: children paint in list order, so the header is drawn
      // on top of rows sliding beneath it (and hit-tested first).
      : super(children: [content, header]);

  @override
  RenderStickySection createRenderObject(BuildContext context) =>
      RenderStickySection(Scrollable.of(context).position);

  @override
  void updateRenderObject(BuildContext context, RenderStickySection renderObject) {
    renderObject.scrollPosition = Scrollable.of(context).position;
  }
}

class _StickySectionParentData extends ContainerBoxParentData<RenderBox> {}

class RenderStickySection extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StickySectionParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StickySectionParentData> {
  RenderStickySection(this._scrollPosition);

  bool _followUpLayoutScheduled = false;

  ScrollPosition _scrollPosition;
  set scrollPosition(ScrollPosition value) {
    if (identical(_scrollPosition, value)) return;
    if (attached) _scrollPosition.removeListener(markNeedsLayout);
    _scrollPosition = value;
    if (attached) _scrollPosition.addListener(markNeedsLayout);
  }

  RenderBox get _content => firstChild!;
  RenderBox get _header => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StickySectionParentData) {
      child.parentData = _StickySectionParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollPosition.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _scrollPosition.removeListener(markNeedsLayout);
    super.detach();
  }

  /// How far this section's top sits above the scrollable's top edge (0 when
  /// fully on screen). The header is shifted down by this amount, clamped to
  /// the section, so it appears pinned to the viewport.
  double _stuckOffset() {
    final scrollBox =
        _scrollPosition.context.notificationContext?.findRenderObject();
    if (scrollBox is! RenderBox || !scrollBox.attached || !attached) return 0;
    try {
      return -localToGlobal(Offset.zero, ancestor: scrollBox).dy;
    } catch (_) {
      // Transform unavailable mid-mutation (e.g. while being reparented).
      return 0;
    }
  }

  @override
  void performLayout() {
    final previousSize = hasSize ? size : null;
    final childConstraints = constraints.widthConstraints();
    _header.layout(childConstraints, parentUsesSize: true);
    _content.layout(childConstraints, parentUsesSize: true);
    final headerHeight = _header.size.height;
    size = constraints.constrain(Size(
      math.max(_header.size.width, _content.size.width),
      headerHeight + _content.size.height,
    ));

    (_content.parentData! as _StickySectionParentData).offset =
        Offset(0, headerHeight);
    final maxOffset = math.max(0.0, size.height - headerHeight);
    (_header.parentData! as _StickySectionParentData).offset =
        Offset(0, _stuckOffset().clamp(0.0, maxOffset));

    // The viewport finalizes its new scroll extent after laying out this box.
    // If changing content height clamps the scroll position, the sticky offset
    // above was calculated against the previous extent. Recalculate it once
    // the viewport has applied its content dimensions.
    if (previousSize != null &&
        previousSize != size &&
        !_followUpLayoutScheduled) {
      _followUpLayoutScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _followUpLayoutScheduled = false;
        if (attached) markNeedsLayout();
      });
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childConstraints = constraints.widthConstraints();
    final header = _header.getDryLayout(childConstraints);
    final content = _content.getDryLayout(childConstraints);
    return constraints.constrain(Size(
      math.max(header.width, content.width),
      header.height + content.height,
    ));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
