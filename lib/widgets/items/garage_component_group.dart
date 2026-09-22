import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../../models/component.dart';
import '../../repositories/app_repository.dart';
import '../../utils/garage_component_grouping.dart';
import '../../utils/installation_issue.dart';
import 'garage_component_cell.dart';

/// A parent component and the components mounted on it, rendered as one wide
/// cell of the surrounding garage wrap.
///
/// The head cell is the parent and is not reorderable inside the group, so a
/// long press on it drags the whole group through the outer wrap, while a long
/// press on a child starts a reorder within the group.
class GarageComponentGroup extends StatelessWidget {
  static const double borderRadius = 12;

  final GarageComponentGroupData group;
  final String? componentToShowDetails;
  final double cellWidth;
  final double spacing;
  final int cardsPerRow;
  final void Function(Component) onPressedComponent;
  final ValueChanged<Component?> setDraggedComponent;
  final InstallationIssue? Function(Component)? issueOf;

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

  Widget _cell(Component component, {bool merged = false}) => GarageComponentCell(
    key: ValueKey(component),
    component: component,
    componentToShowDetails: componentToShowDetails,
    width: cellWidth,
    issue: issueOf?.call(component),
    merged: merged,
    onPressed: isSnapshot ? null : onPressedComponent,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final head = _cell(group.parent, merged: true);
    final children = [for (final child in group.children) _cell(child)];

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      // Painted over the content instead of insetting it, so the cells inside
      // stay aligned with the outer grid.
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: isSnapshot
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
            ),
    );
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
    child: Card(
      child: ConstrainedBox(
        constraints: constraints,
        child: child is GarageComponentGroup ? child.asSnapshot() : child,
      ),
    ),
  );
}
