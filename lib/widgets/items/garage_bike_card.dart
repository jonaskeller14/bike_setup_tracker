import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../pages/details/bike_details_page.dart';
import '../../pages/details/component_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/bike_actions.dart';
import '../../utils/component_actions.dart';
import '../dashed_border_painter.dart';
import 'component_list_card.dart';
import 'garage_component_icon_card.dart';

class GarageBikeCard extends StatefulWidget {
  final Bike bike;
  final int index;
  final double? elevation;
  final String? componentToShowDetails;
  final void Function(Component) onPressedComponent;
  final void Function({required String? newBike}) onAcceptWithDetails;
  final ValueChanged<Component?> setDraggedComponent;
  final ValueNotifier<Component?> draggedComponentNotifier;

  const GarageBikeCard({
    super.key,
    required this.bike,
    required this.index,
    this.elevation,
    required this.componentToShowDetails,
    required this.onPressedComponent,
    required this.onAcceptWithDetails,
    required this.setDraggedComponent,
    required this.draggedComponentNotifier,
  });

  @override
  State<GarageBikeCard> createState() => _GarageBikeCardState();
}

class _GarageBikeCardState extends State<GarageBikeCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive {
    final dragged = widget.draggedComponentNotifier.value;
    return dragged != null && dragged.bike == widget.bike.id;
  }

  @override
  void initState() {
    super.initState();
    widget.draggedComponentNotifier.addListener(_onDragChanged);
  }

  @override
  void didUpdateWidget(GarageBikeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draggedComponentNotifier != widget.draggedComponentNotifier) {
      oldWidget.draggedComponentNotifier.removeListener(_onDragChanged);
      widget.draggedComponentNotifier.addListener(_onDragChanged);
    }
  }

  @override
  void dispose() {
    widget.draggedComponentNotifier.removeListener(_onDragChanged);
    super.dispose();
  }

  void _onDragChanged() => updateKeepAlive();

  Widget _releaseToBikeWidget(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            Flexible(
              child: Text(
                "Release to install to ${widget.bike.name}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
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

  Widget _dragHintToBikeWidget(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
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
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.add_circle_outline, size: 18, color: color.withValues(alpha: 0.6)),
            Flexible(
              child: Text(
                "Drag here to install on ${widget.bike.name}",
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final persons = appRepository.persons;
    final bikeComponents = Map.fromEntries(appRepository.components.entries.where((ce) => ce.value.bike == widget.bike.id));

    return DragTarget<Object>(
      key: ValueKey(widget.bike.id),
      builder: (context, candidateData, rejectedData) => Card(
        key: ValueKey(widget.bike.id),
        elevation: widget.elevation,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias, // Borderradius for InkWell
        child: InkWell(
          onTap: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (context) => BikeDetailsPage(bikeId: widget.bike.id),
              ),
            );
          },
          onDoubleTap: () => appRepository.onBikeTap(widget.bike.id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                dense: true,
                leading: appSettings.enableStrava && subscriptionService.hasStravaEntitlement
                    ? Badge(
                        label: widget.bike.stravaGear == null
                            ? Icon(
                                Icons.link_off,
                                size: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              )
                            : !appRepository.stravaGears.containsKey(widget.bike.stravaGear)
                                ? Icon(Icons.error_outline, size: 11, color: Theme.of(context).colorScheme.error)
                                : const Icon(SimpleIcons.strava, size: 10, color: Color(0xFFFC4C02)),
                        backgroundColor: Colors.transparent,
                        child: const Icon(Bike.iconData),
                      )
                    : const Icon(Bike.iconData),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  widget.bike.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: appSettings.enablePerson || (widget.bike.notes != null && widget.bike.notes!.isNotEmpty)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (appSettings.enablePerson)
                            Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 2,
                                  children: [
                                    Icon(widget.bike.person != null
                                          ? Person.iconData
                                          : Icons.person_off,
                                      size: 13,
                                      color: widget.bike.person == null || persons.containsKey(widget.bike.person)
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                    if (widget.bike.person != null)
                                      Flexible(
                                        child: Text(
                                          persons[widget.bike.person]?.name ?? "PERSON NOT FOUND",
                                          style: TextStyle(
                                            color: widget.bike.person == null || persons.containsKey(widget.bike.person)
                                                ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                                : Theme.of(context).colorScheme.error,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          if (widget.bike.notes != null && widget.bike.notes!.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3), // tweak to match font size
                                  child: Icon(
                                    Icons.notes,
                                    size: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    widget.bike.notes!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    PopupMenuButton<_BikeOptions>(
                      onSelected: (value) async {
                        switch (value) {
                          case _BikeOptions.edit:
                            await BikeActions.editBike(context, bike: widget.bike);
                          case _BikeOptions.duplicate:
                            await BikeActions.duplicateBikeWithComponents(context, bike: widget.bike);
                          case _BikeOptions.remove:
                            await BikeActions.removeBike(context, bike: widget.bike);
                        }
                      },
                      itemBuilder: (BuildContext context) => _BikeOptions.values.map((option) {
                        return PopupMenuItem<_BikeOptions>(
                          value: option,
                          child: Row(
                            spacing: 10,
                            children: [
                              Icon(option.iconData, size: 20),
                              Text(option.label),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<Component?>(
                valueListenable: widget.draggedComponentNotifier,
                builder: (context, draggedComp, child) {
                  final bool showDropZone =
                      candidateData.isNotEmpty &&
                      candidateData.every(
                        (c) =>
                            c == null ||
                            (draggedComp != null &&
                                draggedComp.bike != widget.bike.id),
                      );
                  final bool isPassiveDropZone =
                      draggedComp != null &&
                      draggedComp.bike != widget.bike.id &&
                      !showDropZone;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: (showDropZone || isPassiveDropZone) ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: showDropZone || isPassiveDropZone,
                            child: ReorderableWrap(
                              scrollPhysics: const NeverScrollableScrollPhysics(),
                              ignorePrimaryScrollController: true,
                              onReorder: (int oldIndex, int newIndex) async {
                                await context.read<AppRepository>().reorderComponent(
                                  oldIndex: oldIndex,
                                  newIndex: newIndex,
                                  filteredComponentsList: bikeComponents.values.toList(),
                                );
                                widget.setDraggedComponent(null);
                              },
                              onReorderStarted: (index) => widget.setDraggedComponent(bikeComponents.values.toList()[index]),
                              onNoReorder: (index) => widget.setDraggedComponent(null),
                              runSpacing: 8,
                              spacing: 8,
                              footer: Container(
                                width: bikeComponents.isEmpty
                                    ? double.infinity
                                    : null,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                    width: 1.0,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => ComponentActions.addComponent(context, initialBike: widget.bike.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 8,
                                      children: [
                                        Icon(Icons.add, size: 24, color: Theme.of(context).colorScheme.primary),
                                        if (bikeComponents.isEmpty)
                                          Text(
                                            "Add Component",
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              children: bikeComponents.values.map((component) => GestureDetector(
                                key: ValueKey(component),
                                onTap: () => widget.onPressedComponent(component),
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
                                  componentToShowDetails: widget.componentToShowDetails,
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                        if (isPassiveDropZone)
                          Positioned.fill(child: _dragHintToBikeWidget(context)),
                        if (showDropZone)
                          Positioned.fill(child: _releaseToBikeWidget(context)),
                      ],
                    ),
                  );
                },
              ),
              if (widget.componentToShowDetails != null &&
                  bikeComponents.keys.contains(widget.componentToShowDetails))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: LongPressDraggable<int>(
                    data: bikeComponents.keys.toList().indexOf(widget.componentToShowDetails!),
                    onDragStarted: () => widget.draggedComponentNotifier.value = bikeComponents[widget.componentToShowDetails],
                    onDragEnd: (_) => widget.draggedComponentNotifier.value = null,
                    onDraggableCanceled: (_, _) => widget.draggedComponentNotifier.value = null,
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: GarageComponentIconCard(
                      component: bikeComponents[widget.componentToShowDetails]!,
                      componentToShowDetails: widget.componentToShowDetails,
                    ),
                    child: ComponentListCard(
                      component: bikeComponents[widget.componentToShowDetails]!,
                      index: null,
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      onWillAcceptWithDetails: (details) {
        final draggedComp = widget.draggedComponentNotifier.value;
        final willAccept = draggedComp != null && draggedComp.bike != widget.bike.id;
        if (willAccept) unawaited(HapticFeedback.lightImpact());
        return willAccept;
      },
      onAcceptWithDetails: (details) {
        widget.onAcceptWithDetails(newBike: widget.bike.id);
        widget.setDraggedComponent(null);
      },
    );
  }
}

enum _BikeOptions {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _BikeOptions(this.label, this.iconData);
}
