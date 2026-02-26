import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/app_data.dart';
import '../models/app_settings.dart';
import '../models/component.dart';
import '../models/filtered_data.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../pages/bike_page.dart';
import '../pages/component_page.dart';
import 'dashed_border_painter.dart';
import 'component_list_card.dart';
import 'garage_component_icon_card.dart';

class GarageBikeCard extends StatelessWidget{
  final Bike bike;
  final int index;
  final double? elevation;
  final String? componentToShowDetails;
  final void Function(Component) onPressedComponent;

  const GarageBikeCard({
    super.key, 
    required this.bike, 
    required this.index,
    this.elevation,
    required this.componentToShowDetails,
    required this.onPressedComponent,
  });

  Future<void> _editBike(BuildContext context, {required Bike bike}) async {
    final data = context.read<AppData>();

    final editedBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.edit(bike: bike),
      ),
    );
    if (editedBike == null) return;

    data.editBike(editedBike);
  }

  Future<void> _removeBike(BuildContext context, {required Bike bike}) async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();

    final obsoleteComponents = filteredData.components.values.where((c) => c.bike == bike.id).toList();
    final obsoleteSetups = filteredData.setups.values.where((s) => s.bike == bike.id).toList();
    final obsoleteRatings = filteredData.ratings.values.where((r) => r.filterType == FilterType.bike && r.filter == bike.id);

    data.removeBike(bike);
    data.removeComponents(obsoleteComponents);
    data.removeSetups(obsoleteSetups);
    data.removeRatings(obsoleteRatings);

    String message = "Bike '${bike.name}' moved to trash.";
    if (context.read<AppSettings>().enableRating) {
      if (obsoleteComponents.isNotEmpty || obsoleteSetups.isNotEmpty || obsoleteRatings.isNotEmpty) {
        message += "\n${obsoleteComponents.length} Components, ${obsoleteSetups.length} Setups and ${obsoleteRatings.length} Ratings which belong to this Bike are deleted as well.";
      }
    } else {
      if (obsoleteComponents.isNotEmpty || obsoleteSetups.isNotEmpty) {
        message += "\n${obsoleteComponents.length} Components, ${obsoleteSetups.length} Setups which belong to this Bike are deleted as well.";
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 10),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          data.restoreBike(bike);
          data.restoreComponents(obsoleteComponents);
          data.restoreSetups(obsoleteSetups);
          data.restoreRatings(obsoleteRatings);
        },
      ),
    ));
  }

  Future<void> _addComponent(BuildContext context, {required String initialBike}) async {
    final data = context.read<AppData>();
    
    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => ComponentPage.add(initialBike: initialBike)),
    );
    if (component == null) return;

    data.addComponent(component);
  }

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
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              "Release to install to ${bike.name}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final persons = filteredData.persons;
    final bikeComponents = Map.fromEntries(filteredData.components.entries.where((ce) => ce.value.bike == bike.id));
    
    return DragTarget<Component>(
      key: ValueKey(bike.id),
      builder: (context, candidateData, rejectedData) => Card(
        key: ValueKey(bike.id),
        elevation: elevation,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias, // Borderradius for InkWell
        child: InkWell(
          onDoubleTap: () => filteredData.onBikeTap(bike.id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: true,
                leading: context.watch<AppSettings>().enableStrava 
                    ? Badge(
                        label: bike.stravaGear == null
                            ? Icon(
                                Icons.link_off, 
                                size: 11, 
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              )
                            : !filteredData.stravaGears.containsKey(bike.stravaGear)
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
                  bike.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: context.read<AppSettings>().enablePerson || (bike.notes != null && bike.notes!.isNotEmpty) 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (context.read<AppSettings>().enablePerson)
                            Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 2,
                                  children: [
                                    Icon(bike.person != null
                                        ? Person.iconData 
                                        : Icons.person_off, 
                                      size: 13, 
                                      color: bike.person == null || persons.containsKey(bike.person) 
                                          ? Theme.of(context).colorScheme.onSurfaceVariant 
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                    if (bike.person != null)
                                      Flexible(
                                        child: Text(
                                          persons[bike.person]?.name ?? "PERSON NOT FOUND",
                                          style: TextStyle(
                                            color: bike.person == null || persons.containsKey(bike.person) 
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
                          if (bike.notes != null && bike.notes!.isNotEmpty)
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
                                    bike.notes!,
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
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit': _editBike(context, bike: bike);
                          case 'remove': _removeBike(context, bike: bike);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20),
                              SizedBox(width: 10),
                              Text('Remove'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ),
              if (candidateData.isNotEmpty && candidateData.every((c) => c == null || c.bike != bike.id))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _releaseToBikeWidget(context),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    height: 48,
                    child: ReorderableListView(
                      onReorder: (int oldIndex, int newIndex) => context.read<AppData>().reorderComponent(
                        oldIndex: oldIndex, 
                        newIndex: newIndex, 
                        filteredComponentsList: bikeComponents.values.toList(),
                      ),
                      scrollDirection: Axis.horizontal,
                      proxyDecorator: (Widget child, int index, Animation<double> animation) => AnimatedBuilder(
                        animation: animation, 
                        builder: (BuildContext context, Widget? child) {
                          final double animValue = Curves.easeInOut.transform(animation.value);
                          final double scale = lerpDouble(1, 1.03, animValue)!;
                          final Component component = bikeComponents.values.toList()[index];
                          return Transform.scale(
                            scale: scale,
                            child: GarageComponentIconCard(
                              component: component,
                              componentToShowDetails: componentToShowDetails,
                            ),
                          );
                        }
                      ),
                      footer: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1.0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _addComponent(context, initialBike: bike.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      children: bikeComponents.values.map((component) => GestureDetector(
                        key: ValueKey(component),
                        onTap: () => onPressedComponent(component),
                        child: GarageComponentIconCard(
                          component: component, 
                          componentToShowDetails: componentToShowDetails
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              if (componentToShowDetails != null && bikeComponents.keys.contains(componentToShowDetails))
                Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: LongPressDraggable<Component>(
                  data: bikeComponents[componentToShowDetails]!,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: GarageComponentIconCard(
                    component: bikeComponents[componentToShowDetails]!, 
                    componentToShowDetails: componentToShowDetails
                  ),
                  child: ComponentListCard(
                    component: bikeComponents[componentToShowDetails]!,
                    index: null,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      onAcceptWithDetails: (details) {
        final Component component = details.data;
        context.read<AppData>().editComponent(component.copyWith(bike: bike.id));
      },
    );
  }
}
