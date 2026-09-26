import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../../models/component/component.dart';
import '../../repositories/app_repository.dart';
import '../../services/component_hierarchy_resolver.dart';
import '../../utils/garage_component_grouping.dart';
import '../../utils/installation_issue.dart';
import 'garage_component_cell.dart';
import 'garage_component_icon_card.dart';

/// A parent component and the components mounted on it, rendered as one wide
/// cell of the surrounding garage wrap.
///
/// The head cell is the parent and is not reorderable inside the group, so a
/// long press on it drags the whole group through the outer wrap, while a long
/// press on a child starts a reorder within the group.
class GarageComponentGroup extends StatelessWidget {
  static const double borderRadius = 12;

  /// How far the group outline sits outside the cells, into the wrap spacing.
  static const double _outlineOutset = 2;

  final GarageComponentGroupData group;
  final String? componentToShowDetails;
  final double cellWidth;
  final double spacing;
  final int cardsPerRow;
  final void Function(Component) onPressedComponent;
  final ValueChanged<Component?> setDraggedComponent;
  final InstallationIssue? Function(Component)? issueOf;
  final Set<String> dimmedIds;

  /// Renders a static snapshot without the inner wrap and without gestures, for
  /// the drag feedback of the whole group.
  final bool isSnapshot;

  const GarageComponentGroup({
    super.key,
    required this.group,
    required this.componentToShowDetails,
    required this.cellWidth,
    required this.spacing,
    required this.cardsPerRow,
    required this.onPressedComponent,
    required this.setDraggedComponent,
    this.issueOf,
    this.dimmedIds = const {},
    this.isSnapshot = false,
  });

  /// The group spans whole cells of the outer grid, capped at one full row.
  double get width {
    final cells = math.min(group.components.length, cardsPerRow);
    return cellWidth * cells + spacing * (cells - 1);
  }

  GarageComponentGroup asSnapshot() => GarageComponentGroup(
    group: group,
    componentToShowDetails: componentToShowDetails,
    cellWidth: cellWidth,
    spacing: spacing,
    cardsPerRow: cardsPerRow,
    onPressedComponent: onPressedComponent,
    setDraggedComponent: setDraggedComponent,
    issueOf: issueOf,
    isSnapshot: true,
  );

  bool get _isGroupDimmed => dimmedIds.contains(group.parent.id);

  Widget _cell(Component component, {bool merged = false}) => GarageComponentCell(
    key: ValueKey(component),
    component: component,
    componentToShowDetails: componentToShowDetails,
    width: cellWidth,
    issue: issueOf?.call(component),
    merged: merged,
    // A dimmed group already fades as a whole, outline included.
    dimmed: !_isGroupDimmed && dimmedIds.contains(component.id),
    onPressed: isSnapshot ? null : onPressedComponent,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isParentSelected = componentToShowDetails == group.parent.id;
    final head = _cell(group.parent, merged: true);
    final children = [for (final child in group.children) _cell(child)];

    final content = isSnapshot
        ? Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [head, ...children],
          )
        : ReorderableWrap(
            scrollPhysics: const NeverScrollableScrollPhysics(),
            ignorePrimaryScrollController: true,
            spacing: spacing,
            runSpacing: spacing,
            onReorder: (int oldIndex, int newIndex) async {
              await context.read<AppRepository>().reorderComponent(
                oldIndex: oldIndex,
                newIndex: newIndex,
                filteredComponentsList: group.children,
              );
              setDraggedComponent(null);
            },
            onReorderStarted: (index) => setDraggedComponent(group.children[index]),
            onNoReorder: (index) => setDraggedComponent(null),
            header: [head],
            children: children,
          );

    final box = SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        // Drawn behind the cells and slightly around them, so it never covers
        // a selected cell's border or a task indicator, while the cells
        // themselves stay aligned with the outer grid.
        children: [
          Positioned(
            left: -_outlineOutset,
            top: -_outlineOutset,
            right: -_outlineOutset,
            bottom: -_outlineOutset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isParentSelected
                    ? colorScheme.tertiaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(borderRadius + _outlineOutset),
                border: Border.all(
                  color: isParentSelected ? colorScheme.tertiary : colorScheme.outlineVariant,
                  width: isParentSelected ? 1.5 : 1.0,
                ),
              ),
            ),
          ),
          content,
        ],
      ),
    );
    return _isGroupDimmed ? Opacity(opacity: garageDraggedOpacity, child: box) : box;
  }
}

/// Builds the outer wrap's drag feedback, replacing a dragged group with a
/// static snapshot so its inner wrap is not instantiated a second time in the
/// drag overlay.
Widget buildGarageDraggableFeedback(
  BuildContext context,
  BoxConstraints constraints,
  Widget child,
) {
  return Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 6,
    borderRadius: BorderRadius.circular(GarageComponentGroup.borderRadius),
    child: ConstrainedBox(
      constraints: constraints,
      child: child is GarageComponentGroup ? child.asSnapshot() : child,
    ),
  );
}

/// Dims a component's detail card while it moves with the dragged component,
/// whether the drag started from the card itself or from the wrap, and whether
/// the component itself or one of its ancestors is dragged.
class GarageDetailDragDimmer extends StatelessWidget {
  final String componentId;
  final ValueNotifier<Component?> draggedComponentNotifier;
  final ComponentHierarchyResolver hierarchy;
  final Widget child;

  const GarageDetailDragDimmer({
    super.key,
    required this.componentId,
    required this.draggedComponentNotifier,
    required this.hierarchy,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Component?>(
      valueListenable: draggedComponentNotifier,
      builder: (context, dragged, child) => Opacity(
        opacity: idsMovedWith(dragged, hierarchy: hierarchy).contains(componentId)
            ? garageDraggedOpacity
            : 1.0,
        child: child,
      ),
      child: child,
    );
  }
}

/// How far above the finger the detail drag feedback floats.
const double _detailFeedbackFingerGap = 28;

/// Drag feedback for a component dragged from its detail card, matching the
/// wrap's feedback: a single cell, or the snapshot of the whole [group] when
/// components are mounted on it.
///
/// Meant for [pointerDragAnchorStrategy]: the feedback shifts itself to sit
/// centered above the finger, so the hand does not cover it on touch screens.
/// Fractional shifting avoids having to know the feedback's height up front.
Widget buildGarageDetailDragFeedback(
  BuildContext context, {
  required GarageComponentGroupData group,
  required double availableWidth,
  required String? componentToShowDetails,
  required void Function(Component) onPressedComponent,
  required ValueChanged<Component?> setDraggedComponent,
  InstallationIssue? Function(Component)? issueOf,
}) {
  return Transform.translate(
    offset: const Offset(0, -_detailFeedbackFingerGap),
    child: FractionalTranslation(
      translation: const Offset(-0.5, -1),
      child: _detailDragFeedback(
        context,
        group: group,
        availableWidth: availableWidth,
        componentToShowDetails: componentToShowDetails,
        onPressedComponent: onPressedComponent,
        setDraggedComponent: setDraggedComponent,
        issueOf: issueOf,
      ),
    ),
  );
}

Widget _detailDragFeedback(
  BuildContext context, {
  required GarageComponentGroupData group,
  required double availableWidth,
  required String? componentToShowDetails,
  required void Function(Component) onPressedComponent,
  required ValueChanged<Component?> setDraggedComponent,
  InstallationIssue? Function(Component)? issueOf,
}) {
  const spacing = 8.0;
  final cellWidth = GarageComponentIconCard.widthFor(availableWidth, spacing: spacing);
  if (!group.isGroup) {
    return GarageComponentIconCard(
      component: group.parent,
      componentToShowDetails: componentToShowDetails,
      width: cellWidth,
      issue: issueOf?.call(group.parent),
    );
  }
  final snapshot = GarageComponentGroup(
    group: group,
    componentToShowDetails: componentToShowDetails,
    cellWidth: cellWidth,
    spacing: spacing,
    cardsPerRow: GarageComponentIconCard.cardsPerRow(availableWidth, spacing: spacing),
    onPressedComponent: onPressedComponent,
    setDraggedComponent: setDraggedComponent,
    issueOf: issueOf,
    isSnapshot: true,
  );
  return buildGarageDraggableFeedback(context, BoxConstraints.tightFor(width: snapshot.width), snapshot);
}
