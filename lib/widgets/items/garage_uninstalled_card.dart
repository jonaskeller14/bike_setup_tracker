import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../../models/component/component.dart';
import '../../repositories/app_repository.dart';
import '../../utils/component_actions.dart';
import '../../utils/garage_component_grouping.dart';
import '../../utils/installation_issue.dart';
import '../dashed_border_painter.dart';
import 'component_list_card.dart';
import 'garage_component_cell.dart';
import 'garage_component_group.dart';
import 'garage_component_icon_card.dart';

class GarageUninstalledCard extends StatefulWidget {
  final String? componentToShowDetails;
  final void Function(Component) onPressedComponent;
  final void Function({required String? newBike}) onAcceptWithDetails;
  final VoidCallback onArchiveAccept;
  final ValueChanged<Component?> setDraggedComponent;
  final ValueNotifier<Component?> draggedComponentNotifier;

  const GarageUninstalledCard({
    super.key,
    required this.componentToShowDetails,
    required this.onPressedComponent,
    required this.onAcceptWithDetails,
    required this.onArchiveAccept,
    required this.setDraggedComponent,
    required this.draggedComponentNotifier,
  });

  @override
  State<GarageUninstalledCard> createState() => _GarageUninstalledCardState();
}

class _GarageUninstalledCardState extends State<GarageUninstalledCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isDraggingDetail = false;

  Widget _releaseToUninstallWidget(
    BuildContext context, {
    required bool isUnarchiving,
    Component? parent,
  }) {
    final color = Theme.of(context).colorScheme.error;
    final bgColor = Theme.of(context).colorScheme.errorContainer;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color.withValues(alpha: 0.5),
        strokeWidth: 2,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60, minWidth: double.infinity),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              isUnarchiving ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: color,
            ),
            Flexible(
              child: Text(
                isUnarchiving
                    ? "Release to unarchive"
                    : parent == null
                        ? "Release to uninstall component"
                        : "Release to uninstall from ${parent.name}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHereToUninstall(BuildContext context) {
    return InkWell(
      onTap: () => ComponentActions.addComponent(context, initialBike: null),
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Theme.of(context).colorScheme.outlineVariant,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: 12,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60, minWidth: double.infinity),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Drag components here to uninstall from bike"),
              Text(
                "or tap to add new",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHintToUninstallWidget(BuildContext context, {Component? parent}) {
    final color = Theme.of(context).colorScheme.error;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color.withValues(alpha: 0.4),
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60, minWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.archive_outlined, size: 18, color: color.withValues(alpha: 0.6)),
            Flexible(
              child: Text(
                parent == null
                    ? "Drag here to uninstall"
                    : "Drag here to uninstall from ${parent.name}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHintToArchiveWidget(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color.withValues(alpha: 0.4),
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52, minWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: color.withValues(alpha: 0.6)),
            Flexible(
              child: Text(
                "Drag here to archive",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _releaseToArchiveWidget(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color.withValues(alpha: 0.5),
        strokeWidth: 2,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 52,
          minWidth: double.infinity,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.inventory_2_outlined, color: color),
            Flexible(
              child: Text(
                "Release to archive",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHereToArchive(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.4),
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 52,
          minWidth: double.infinity,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.tertiaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.6),
            ),
            Text(
              "Drag here to archive",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.tertiary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appRepository = context.watch<AppRepository>();

    final hierarchy = appRepository.componentHierarchy;
    final uninstalledComponents = Map.fromEntries(
      appRepository.components.entries.where(
        (ce) =>
            !appRepository.bikes.keys.contains(hierarchy.currentBike(ce.key)) &&
            !hierarchy.isEffectivelyArchived(ce.key),
      ),
    );
    final archivedComponents = appRepository.archivedComponents;

    InstallationIssue? issueOf(Component component) => installationIssueOf(
      component.id,
      hierarchy: hierarchy,
      bikes: appRepository.bikes,
    );

    final uninstalledGroups = garageGroupsFor(uninstalledComponents.values, hierarchy: hierarchy);
    final uninstalledRoots = uninstalledGroups.map((group) => group.parent).toList();
    final archivedGroups = garageGroupsFor(archivedComponents.values, hierarchy: hierarchy);
    final archivedRoots = archivedGroups.map((group) => group.parent).toList();

    final showUninstalledComponent = widget.componentToShowDetails != null && uninstalledComponents.keys.contains(widget.componentToShowDetails);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.shelves),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              "Uninstalled components",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          DragTarget<Object>(
            onWillAcceptWithDetails: (details) {
              final d = widget.draggedComponentNotifier.value;
              final willAccept = d != null && (hierarchy.currentBike(d.id) != null || d.isArchived);
              if (willAccept) unawaited(HapticFeedback.lightImpact());
              return willAccept;
            },
            onAcceptWithDetails: (details) {
              widget.onAcceptWithDetails(newBike: null);
              widget.setDraggedComponent(null);
            },
            builder: (context, candidateItems, rejectedItems) {
              return ValueListenableBuilder<Component?>(
                valueListenable: widget.draggedComponentNotifier,
                builder: (context, draggedComp, child) {
                  final bool showDropZone =
                      candidateItems.isNotEmpty &&
                      draggedComp != null &&
                      hierarchy.currentBike(draggedComp.id) != null &&
                      !draggedComp.isArchived;
                  final bool showUnarchiveZone =
                      candidateItems.isNotEmpty &&
                      draggedComp != null &&
                      draggedComp.isArchived;
                  final bool isPassiveUninstallZone =
                      draggedComp != null &&
                      (hierarchy.currentBike(draggedComp.id) != null || draggedComp.isArchived) &&
                      !showDropZone &&
                      !showUnarchiveZone;
                  final draggedParent = draggedComp == null
                      ? null
                      : currentParentComponentOf(draggedComp.id, hierarchy: hierarchy);
                  final detailDraggedIds = _isDraggingDetail
                      ? idsMovedWith(draggedComp, hierarchy: hierarchy)
                      : const <String>{};

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: (showDropZone || showUnarchiveZone || isPassiveUninstallZone)
                              ? 0.0
                              : 1.0,
                          child: IgnorePointer(
                            ignoring: showDropZone || showUnarchiveZone || isPassiveUninstallZone,
                            child: uninstalledComponents.isEmpty
                                ? _dragHereToUninstall(context)
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      const spacing = 8.0;
                                      final itemWidth = GarageComponentIconCard.widthFor(
                                        constraints.maxWidth,
                                        spacing: spacing,
                                      );
                                      final cardsPerRow = GarageComponentIconCard.cardsPerRow(
                                        constraints.maxWidth,
                                        spacing: spacing,
                                      );

                                      return ReorderableWrap(
                                        key: ValueKey(uninstalledComponents),
                                        scrollPhysics: const NeverScrollableScrollPhysics(),
                                        ignorePrimaryScrollController: true,
                                        onReorder: (int oldIndex, int newIndex) async {
                                          await context.read<AppRepository>().reorderComponent(
                                            oldIndex: oldIndex,
                                            newIndex: newIndex,
                                            filteredComponentsList: uninstalledRoots,
                                          );
                                          widget.setDraggedComponent(null);
                                        },
                                        onReorderStarted: (index) =>
                                            widget.setDraggedComponent(uninstalledRoots[index]),
                                        onNoReorder: (index) => widget.setDraggedComponent(null),
                                        buildDraggableFeedback: buildGarageDraggableFeedback,
                                        footer: Container(
                                          width: itemWidth,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.outlineVariant,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () => ComponentActions.addComponent(context, initialBike: null),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.add,
                                                size: 24,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        spacing: spacing,
                                        runSpacing: spacing,
                                        children: uninstalledGroups.map((group) => group.isGroup
                                          ? GarageComponentGroup(
                                              key: ValueKey(group.parent),
                                              group: group,
                                              componentToShowDetails: widget.componentToShowDetails,
                                              cellWidth: itemWidth,
                                              spacing: spacing,
                                              cardsPerRow: cardsPerRow,
                                              onPressedComponent: widget.onPressedComponent,
                                              setDraggedComponent: widget.setDraggedComponent,
                                              issueOf: issueOf,
                                              dimmedIds: detailDraggedIds,
                                            )
                                          : GarageComponentCell(
                                              key: ValueKey(group.parent),
                                              component: group.parent,
                                              componentToShowDetails: widget.componentToShowDetails,
                                              width: itemWidth,
                                              dimmed: detailDraggedIds.contains(group.parent.id),
                                              issue: issueOf(group.parent),
                                              onPressed: widget.onPressedComponent,
                                            )).toList(),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        if (isPassiveUninstallZone)
                          Positioned.fill(
                            child: _dragHintToUninstallWidget(context, parent: draggedParent),
                          ),
                        if (showDropZone)
                          Positioned.fill(
                            child: _releaseToUninstallWidget(
                              context,
                              isUnarchiving: false,
                              parent: draggedParent,
                            ),
                          ),
                        if (showUnarchiveZone)
                          Positioned.fill(
                            child: _releaseToUninstallWidget(context, isUnarchiving: true)),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // ── Detail card for selected uninstalled component ───────────
          if (showUninstalledComponent)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: LayoutBuilder( // workaround to get same GarageComponentIconCard width
                builder: (context, constraints) => LongPressDraggable<Component>(
                  data: uninstalledComponents[widget.componentToShowDetails]!,
                  onDragStarted: () {
                    _isDraggingDetail = true;
                    widget.draggedComponentNotifier.value = uninstalledComponents[widget.componentToShowDetails];
                  },
                  onDragEnd: (_) {
                    _isDraggingDetail = false;
                    widget.draggedComponentNotifier.value = null;
                  },
                  onDraggableCanceled: (_, _) => widget.draggedComponentNotifier.value = null,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: buildGarageDetailDragFeedback(
                    context,
                    group: garageGroupOf(
                      uninstalledComponents[widget.componentToShowDetails]!,
                      uninstalledComponents.values,
                      hierarchy: hierarchy,
                    ),
                    availableWidth: constraints.maxWidth,
                    componentToShowDetails: widget.componentToShowDetails,
                    onPressedComponent: widget.onPressedComponent,
                    setDraggedComponent: widget.setDraggedComponent,
                    issueOf: issueOf,
                  ),
                  child: GarageDetailDragDimmer(
                    componentId: widget.componentToShowDetails!,
                    draggedComponentNotifier: widget.draggedComponentNotifier,
                    hierarchy: hierarchy,
                    child: ComponentListCard(
                      component: uninstalledComponents[widget.componentToShowDetails]!,
                      index: null,
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      showCurrentAdjustmentValues: false,
                    ),
                  ),
                ),
              ),
            ),

          // ── Archived section ─────────────────────────────────────────
          ValueListenableBuilder<Component?>(
            valueListenable: widget.draggedComponentNotifier,
            builder: (context, draggedComp, child) {
              final isDraggingNonArchived =
                  draggedComp != null && !draggedComp.isArchived;
              final showSection =
                  archivedComponents.isNotEmpty || isDraggingNonArchived;
              final detailDraggedIds = _isDraggingDetail
                  ? idsMovedWith(draggedComp, hierarchy: hierarchy)
                  : const <String>{};

              if (!showSection) {
                if (showUninstalledComponent) {
                  return const SizedBox(height: 12);
                } else {
                  return const SizedBox.shrink();
                }
              }

              return DragTarget<Object>(
                builder: (context, innerCandidates, innerRejected) {
                  final showDropZone =
                      innerCandidates.isNotEmpty && isDraggingNonArchived;
                  final bool isPassiveArchiveZone =
                      isDraggingNonArchived &&
                      archivedComponents.isNotEmpty &&
                      !showDropZone;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(indent: 12, endIndent: 12),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory_2_outlined),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          "Archive",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: (showDropZone || isPassiveArchiveZone) ? 0.0 : 1.0,
                              child: IgnorePointer(
                                ignoring: showDropZone || isPassiveArchiveZone,
                                child: archivedComponents.isEmpty
                                    ? _dragHereToArchive(context)
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          const spacing = 8.0;
                                          final itemWidth = GarageComponentIconCard.widthFor(
                                            constraints.maxWidth,
                                            spacing: spacing,
                                          );
                                          final cardsPerRow = GarageComponentIconCard.cardsPerRow(
                                            constraints.maxWidth,
                                            spacing: spacing,
                                          );

                                          return ReorderableWrap(
                                            key: ValueKey(archivedComponents),
                                            scrollPhysics: const NeverScrollableScrollPhysics(),
                                            ignorePrimaryScrollController: true,
                                            onReorder: (int oldIndex, int newIndex) async {
                                              await context.read<AppRepository>().reorderComponent(
                                                oldIndex: oldIndex,
                                                newIndex: newIndex,
                                                filteredComponentsList: archivedRoots,
                                              );
                                              widget.setDraggedComponent(null);
                                            },
                                            onReorderStarted: (int index) =>
                                                widget.setDraggedComponent(archivedRoots[index]),
                                            onNoReorder: (int index) => widget.setDraggedComponent(null),
                                            buildDraggableFeedback: buildGarageDraggableFeedback,
                                            spacing: spacing,
                                            runSpacing: spacing,
                                            children: archivedGroups.map((group) => group.isGroup
                                              ? GarageComponentGroup(
                                                  key: ValueKey(group.parent),
                                                  group: group,
                                                  componentToShowDetails: widget.componentToShowDetails,
                                                  cellWidth: itemWidth,
                                                  spacing: spacing,
                                                  cardsPerRow: cardsPerRow,
                                                  onPressedComponent: widget.onPressedComponent,
                                                  setDraggedComponent: widget.setDraggedComponent,
                                                  dimmedIds: detailDraggedIds,
                                                )
                                              : GarageComponentCell(
                                                  key: ValueKey(group.parent),
                                                  component: group.parent,
                                                  componentToShowDetails: widget.componentToShowDetails,
                                                  width: itemWidth,
                                                  dimmed: detailDraggedIds.contains(group.parent.id),
                                                  onPressed: widget.onPressedComponent,
                                                )).toList(),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            if (isPassiveArchiveZone)
                              Positioned.fill(child: _dragHintToArchiveWidget(context)),
                            if (showDropZone)
                              Positioned.fill(
                                child: _releaseToArchiveWidget(context),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                onWillAcceptWithDetails: (details) {
                  final d = widget.draggedComponentNotifier.value;
                  final willAccept = d != null && !d.isArchived;
                  if (willAccept) unawaited(HapticFeedback.lightImpact());
                  return willAccept;
                },
                onAcceptWithDetails: (details) => widget.onArchiveAccept(),
              );
            },
          ),

          // ── Detail card for selected archived component ──────────────
          if (widget.componentToShowDetails != null && archivedComponents.keys.contains(widget.componentToShowDetails))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: LayoutBuilder( // workaround to get same GarageComponentIconCard width
                builder: (context, constraints) => LongPressDraggable<Component>(
                  data: archivedComponents[widget.componentToShowDetails]!,
                  onDragStarted: () {
                    _isDraggingDetail = true;
                    widget.draggedComponentNotifier.value = archivedComponents[widget.componentToShowDetails];
                  },
                  onDragEnd: (_) {
                    _isDraggingDetail = false;
                    widget.draggedComponentNotifier.value = null;
                  },
                  onDraggableCanceled: (_, _) => widget.draggedComponentNotifier.value = null,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: buildGarageDetailDragFeedback(
                    context,
                    group: garageGroupOf(
                      archivedComponents[widget.componentToShowDetails]!,
                      archivedComponents.values,
                      hierarchy: hierarchy,
                    ),
                    availableWidth: constraints.maxWidth,
                    componentToShowDetails: widget.componentToShowDetails,
                    onPressedComponent: widget.onPressedComponent,
                    setDraggedComponent: widget.setDraggedComponent,
                  ),
                  child: GarageDetailDragDimmer(
                    componentId: widget.componentToShowDetails!,
                    draggedComponentNotifier: widget.draggedComponentNotifier,
                    hierarchy: hierarchy,
                    child: ComponentListCard(
                      component: archivedComponents[widget.componentToShowDetails]!,
                      index: null,
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      showCurrentAdjustmentValues: false,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
