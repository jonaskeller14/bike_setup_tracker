import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import '../../models/component.dart';
import '../../pages/details/component_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../utils/component_actions.dart';
import '../dashed_border_painter.dart';
import 'component_list_card.dart';
import 'garage_component_icon_card.dart';

class GarageUninstalledCard extends StatelessWidget {
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

  Widget _releaseToDeinstallWidget(
    BuildContext context, {
    required bool isUnarchiving,
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
                    : "Release to deinstall component",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHereToDeinstall(BuildContext context) {
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
              const Text("Drag components here to deinstall from bike"),
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

  Widget _dragHintToDeinstallWidget(BuildContext context) {
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
                "Drag here to deinstall",
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
    final appRepository = context.watch<AppRepository>();

    final deinstalledComponents = Map.fromEntries(
      appRepository.components.entries.where(
        (ce) =>
            !appRepository.bikes.keys.contains(ce.value.bike) &&
            !ce.value.isArchived,
      ),
    );
    final archivedComponents = appRepository.archivedComponents;

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
              "Deinstalled components",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          DragTarget<Object>(
            onWillAcceptWithDetails: (details) {
              final d = draggedComponentNotifier.value;
              final willAccept = d != null && (d.bike != null || d.isArchived);
              if (willAccept) unawaited(HapticFeedback.lightImpact());
              return willAccept;
            },
            onAcceptWithDetails: (details) {
              onAcceptWithDetails(newBike: null);
              setDraggedComponent(null);
            },
            builder: (context, candidateItems, rejectedItems) {
              return ValueListenableBuilder<Component?>(
                valueListenable: draggedComponentNotifier,
                builder: (context, draggedComp, child) {
                  final bool showDropZone =
                      candidateItems.isNotEmpty &&
                      draggedComp != null &&
                      draggedComp.bike != null &&
                      !draggedComp.isArchived;
                  final bool showUnarchiveZone =
                      candidateItems.isNotEmpty &&
                      draggedComp != null &&
                      draggedComp.isArchived;
                  final bool isPassiveDeinstallZone =
                      draggedComp != null &&
                      (draggedComp.bike != null || draggedComp.isArchived) &&
                      !showDropZone &&
                      !showUnarchiveZone;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: (showDropZone || showUnarchiveZone || isPassiveDeinstallZone)
                              ? 0.0
                              : 1.0,
                          child: IgnorePointer(
                            ignoring: showDropZone || showUnarchiveZone || isPassiveDeinstallZone,
                            child: deinstalledComponents.isEmpty
                                ? _dragHereToDeinstall(context)
                                : ReorderableWrap(
                                    key: ValueKey(deinstalledComponents),
                                    onReorder: (int oldIndex, int newIndex) =>
                                        context
                                            .read<AppRepository>()
                                            .reorderComponent(
                                              oldIndex: oldIndex,
                                              newIndex: newIndex,
                                              filteredComponentsList:
                                                  deinstalledComponents.values
                                                      .toList(),
                                            ),
                                    onReorderStarted: (index) =>
                                        setDraggedComponent(
                                          deinstalledComponents.values
                                              .toList()[index],
                                        ),
                                    onNoReorder: (index) => setDraggedComponent(null),
                                    footer: Container(
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
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: deinstalledComponents.values
                                        .map(
                                          (component) => GestureDetector(
                                            onTap: () => onPressedComponent(component),
                                            onDoubleTap: () async {
                                              await Navigator.push<void>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ComponentDetailsPage(componentId: component.id),
                                                ),
                                              );
                                            },
                                            child: GarageComponentIconCard(
                                              component: component,
                                              componentToShowDetails:
                                                  componentToShowDetails,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ),
                        if (isPassiveDeinstallZone)
                          Positioned.fill(child: _dragHintToDeinstallWidget(context)),
                        if (showDropZone)
                          Positioned.fill(child: _releaseToDeinstallWidget(context, isUnarchiving: false)),
                        if (showUnarchiveZone)
                          Positioned.fill(
                            child: _releaseToDeinstallWidget(context, isUnarchiving: true)),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // ── Detail card for selected deinstalled component ───────────
          if (componentToShowDetails != null && deinstalledComponents.keys.contains(componentToShowDetails))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: LongPressDraggable<Component>(
                data: deinstalledComponents[componentToShowDetails]!,
                onDragStarted: () => draggedComponentNotifier.value = deinstalledComponents[componentToShowDetails],
                onDragEnd: (_) => draggedComponentNotifier.value = null,
                onDraggableCanceled: (_, _) => draggedComponentNotifier.value = null,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: GarageComponentIconCard(
                  component: deinstalledComponents[componentToShowDetails]!,
                  componentToShowDetails: componentToShowDetails,
                ),
                child: ComponentListCard(
                  component: deinstalledComponents[componentToShowDetails]!,
                  index: null,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  showCurrentAdjustmentValues: false,
                ),
              ),
            ),

          // ── Archived section ─────────────────────────────────────────
          ValueListenableBuilder<Component?>(
            valueListenable: draggedComponentNotifier,
            builder: (context, draggedComp, child) {
              final isDraggingNonArchived =
                  draggedComp != null && !draggedComp.isArchived;
              final showSection =
                  archivedComponents.isNotEmpty || isDraggingNonArchived;

              if (!showSection) return const SizedBox.shrink();

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
                                    : ReorderableWrap(
                                        key: ValueKey(archivedComponents),
                                        onReorder: (int oldIndex, int newIndex) {
                                          context.read<AppRepository>().reorderComponent(
                                            oldIndex: oldIndex,
                                            newIndex: newIndex,
                                            filteredComponentsList: archivedComponents.values.toList(),
                                          );
                                        },
                                        onReorderStarted: (int index) =>
                                            setDraggedComponent(
                                              archivedComponents.values
                                                  .toList()[index],
                                            ),
                                        onNoReorder: (int index) =>
                                            setDraggedComponent(null),
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: archivedComponents.values.map((component) {
                                          return GestureDetector(
                                            onTap: () => onPressedComponent(component),
                                            onDoubleTap: () async {
                                              await Navigator.push<void>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ComponentDetailsPage(
                                                        componentId: component.id,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: GarageComponentIconCard(
                                              component: component,
                                              componentToShowDetails: componentToShowDetails,
                                            ),
                                          );
                                        }).toList(),
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
                  final d = draggedComponentNotifier.value;
                  final willAccept = d != null && !d.isArchived;
                  if (willAccept) unawaited(HapticFeedback.lightImpact());
                  return willAccept;
                },
                onAcceptWithDetails: (details) => onArchiveAccept(),
              );
            },
          ),

          // ── Detail card for selected archived component ──────────────
          if (componentToShowDetails != null && archivedComponents.keys.contains(componentToShowDetails))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: LongPressDraggable<Component>(
                data: archivedComponents[componentToShowDetails]!,
                onDragStarted: () => draggedComponentNotifier.value = archivedComponents[componentToShowDetails],
                onDragEnd: (_) => draggedComponentNotifier.value = null,
                onDraggableCanceled: (_, _) => draggedComponentNotifier.value = null,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: GarageComponentIconCard(
                  component: archivedComponents[componentToShowDetails]!,
                  componentToShowDetails: componentToShowDetails,
                ),
                child: ComponentListCard(
                  component: archivedComponents[componentToShowDetails]!,
                  index: null,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  showCurrentAdjustmentValues: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
