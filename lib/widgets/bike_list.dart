import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/person.dart';

class BikeList extends StatefulWidget {
  final List<Bike> bikes;
  final Map<String, Person> persons;
  final Bike? selectedBike;
  final void Function(Bike bike) onBikeTap;
  final void Function(Bike bike) editBike;
  final void Function(Bike bike) removeBike;
  final void Function(int oldIndex, int newIndex) onReorderBikes;
  final Widget filterWidget;

  const BikeList({
    super.key,
    required this.bikes,
    required this.persons,
    required this.selectedBike,
    required this.onBikeTap,
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
    
    final List<InkWell> inkWells = <InkWell>[];
    for (int index = 0; index < visibleItemCount; index++) {
      final bike = widget.bikes[index];
      inkWells.add(
        InkWell(
          key: ValueKey(bike.id),
          onTap: null, //TODO
          child: Card(
            color: bike == widget.selectedBike ? Theme.of(context).colorScheme.secondaryContainer : null,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Opacity(
              opacity: bike == widget.selectedBike || widget.selectedBike == null ? 1 : 0.3,
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
                onTap: () => widget.onBikeTap(bike),
                subtitle: context.read<AppSettings>().enablePerson
                    ? Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (bike.person != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Person.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Text(
                                  widget.persons[bike.person]?.name ?? "-",
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          if (bike.person == null)
                            Icon(Icons.person_off, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
