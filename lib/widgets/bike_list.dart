import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/person.dart';

const defaultVisibleCount = 10;

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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded
        ? widget.bikes.length
        : widget.bikes.length.clamp(0, defaultVisibleCount);
    
    final List<Card> cards = <Card>[];
    for (int index = 0; index < visibleCount; index++) {
      final bike = widget.bikes[index];
      cards.add(
        Card(
          key: ValueKey(bike.id),
          color: bike == widget.selectedBike ? Theme.of(context).colorScheme.secondaryContainer : null,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Opacity(
            opacity: bike == widget.selectedBike || widget.selectedBike == null ? 1 : 0.3,
              child: ListTile(
              dense: true,
              leading: const Icon(Icons.pedal_bike),
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
                              Icon(Icons.person, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      if (value == 'edit') {
                        widget.editBike(bike);
                      } else if (value == 'remove') {
                        widget.removeBike(bike);
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
      );
    }

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: Card(elevation: elevation, color: cards[index].color, child: cards[index].child),
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
            itemCount: visibleCount,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: widget.filterWidget,
            footer: widget.bikes.length > defaultVisibleCount
                ? Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(_expanded ? "Show less" : "Show more"),
                    ),
                  )
                : null,
            proxyDecorator: proxyDecorator,
            onReorder: widget.onReorderBikes,
            itemBuilder: (context, index) {
              return cards[index];
            },
          );
  }
}
