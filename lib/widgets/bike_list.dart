import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/filtered_data.dart';
import '../models/person.dart';

class BikeList extends StatefulWidget {
  final Map<String, Bike> bikes;
  final void Function(Bike bike) editBike;
  final void Function(Bike bike) removeBike;
  final void Function(int oldIndex, int newIndex) onReorderBikes;
  final Widget filterWidget;

  const BikeList({
    super.key,
    required this.bikes,
    required this.editBike,
    required this.removeBike,
    required this.onReorderBikes,
    required this.filterWidget,
  });

  @override
  State<BikeList> createState() => _BikeListState();
}

class _BikeListState extends State<BikeList> {
  int _maxItemCount = 10;
  static const int _itemCountIncrement = 10;

  @override
  Widget build(BuildContext context) {
    final visibleItemCount = widget.bikes.length.clamp(0, _maxItemCount);
    
    final filteredData = context.watch<FilteredData>();
    final persons = filteredData.persons;
    
    final List<InkWell> inkWells = <InkWell>[];
    final bikes = widget.bikes.values.toList();
    for (int index = 0; index < visibleItemCount; index++) {
      final bike = bikes[index];
      inkWells.add(
        InkWell(
          key: ValueKey(bike.id),
          child: Card(
            color: bike.id == filteredData.selectedBike ? Theme.of(context).colorScheme.secondaryContainer : null,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Opacity(
              opacity: bike.id == filteredData.selectedBike || filteredData.selectedBike == null ? 1 : 0.3,
                child: ListTile(
                dense: true,
                leading: const Icon(Bike.iconData),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  bike.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () => filteredData.onBikeTap(bike.id),
                subtitle: context.read<AppSettings>().enablePerson
                    ? Wrap(
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
                          case 'edit': widget.editBike(bike);
                          case 'remove': widget.removeBike(bike);
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
            ),
          ),
        ),
      );
    }

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          final card = inkWells[index].child! as Card;
          return Transform.scale(
            scale: scale,
            child: Card(elevation: elevation, color: card.color, child: card.child),
          );
        },
        child: child,
      );
    }

    return widget.bikes.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.filterWidget,
                Expanded(
                  child: Center(
                    child: Text(
                      'No bikes yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          )
        : ReorderableListView.builder(
            itemCount: visibleItemCount,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: widget.filterWidget,
            footer: widget.bikes.length > visibleItemCount
                ? Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _maxItemCount += _itemCountIncrement),
                      icon: const Icon(Icons.expand_more),
                      label: const Text("Show more"),
                    ),
                  )
                : null,
            proxyDecorator: proxyDecorator,
            onReorder: widget.onReorderBikes,
            itemBuilder: (context, index) {
              return inkWells[index];
            },
          );
  }
}
