import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import '../models/component.dart';
import '../repositories/app_repository.dart';
import '../utils/component_actions.dart';
import 'dashed_border_painter.dart';
import 'component_list_card.dart';
import 'garage_component_icon_card.dart';

class GarageUninstalledCard extends StatelessWidget{
  final String? componentToShowDetails;
  final void Function(Component) onPressedComponent;
  final void Function({required String? newBike}) onAcceptWithDetails;
  final ValueChanged<Component?> setDraggedComponent;
  final ValueNotifier<Component?> draggedComponentNotifier;

  const GarageUninstalledCard({
    super.key, 
    required this.componentToShowDetails, 
    required this.onPressedComponent, 
    required this.onAcceptWithDetails,
    required this.setDraggedComponent,
    required this.draggedComponentNotifier,
  });

  Widget _releaseToDeinstallWidget(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        strokeWidth: 2,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 60,
          minWidth: double.infinity,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              Icons.archive_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                "Release to deinstall component",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
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
          constraints: const BoxConstraints(
            minHeight: 60,
            minWidth: double.infinity,
          ),
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

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final Map<String, Component> deinstalledComponents = Map.fromEntries(appRepository.components.entries.where((ce) => !appRepository.bikes.keys.contains(ce.value.bike)));

    return DragTarget<Object>(
      builder: (context, candidateItems, rejectedItems) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.shelves),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  "Archive - Deinstalled components",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: null,
                trailing: null,
              ),
              ValueListenableBuilder<Component?>(
                valueListenable: draggedComponentNotifier,
                builder: (context, draggedComp, child) {
                  final bool showDropZone =
                      candidateItems.isNotEmpty &&
                      (draggedComp != null && draggedComp.bike != null);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: showDropZone ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: showDropZone,
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
                                              adjustNewIndex: false,
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
                                            onTap: () =>
                                                onPressedComponent(component),
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
                        if (showDropZone)
                          Positioned.fill(
                            child: _releaseToDeinstallWidget(context),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (componentToShowDetails != null &&
                  deinstalledComponents.keys.contains(componentToShowDetails))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
            ],
          ),
        );
      },
      onWillAcceptWithDetails: (details) {
        final draggedComp = draggedComponentNotifier.value;
        return draggedComp != null && draggedComp.bike != null;
      },
      onAcceptWithDetails: (details) {
        onAcceptWithDetails(newBike: null);
        setDraggedComponent(null);
      },
    ); 
  }
}
