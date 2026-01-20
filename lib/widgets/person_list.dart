import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/setup.dart';
import '../models/bike.dart';
import '../models/person.dart';
import 'adjustment_compact_display_list.dart';

class PersonList extends StatefulWidget {
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;
  final Map<String, Setup> setups;
  final void Function(Person person) editPerson;
  final void Function(Person person) duplicatePerson;
  final void Function(Person person) removePerson;
  final void Function(int oldIndex, int newIndex) onReorderPerson;
  final Widget filterWidget;

  const PersonList({
    super.key,
    required this.bikes,
    required this.persons,
    required this.setups,
    required this.editPerson,
    required this.duplicatePerson,
    required this.removePerson,
    required this.onReorderPerson,
    required this.filterWidget,
  });

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  int _maxItemCount = 3;
  static const int _itemCountIncrement = 3;

  Column _bikeColumn(Person person) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.bikes.values.where((b) => b.person == person.id).map((bike) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(Bike.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            Flexible(
              child: Text(
                bike.name,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItemCount = widget.persons.length.clamp(0, _maxItemCount);
    
    final List<InkWell> inkWells = <InkWell>[];
    for (int index = 0; index < visibleItemCount; index++) {
      final person = widget.persons.values.toList()[index];
      inkWells.add(
        InkWell(
          key: ValueKey(person.id),
          onTap: null, //TODO
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Person.iconData),
                  minTileHeight: 0,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    person.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  enabled: widget.setups.values.lastWhereOrNull((s) => s.person == person.id) != null,
                  subtitle: _bikeColumn(person),
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
                            case 'edit': widget.editPerson(person);
                            case 'duplicate': widget.duplicatePerson(person);
                            case 'remove': widget.removePerson(person);
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
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20),
                                SizedBox(width: 10),
                                Text('Duplicate'),
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: AdjustmentCompactDisplayList(
                    components: [person],
                    adjustmentValues: widget.setups.values.lastWhereOrNull((s) => s.person == person.id)?.personAdjustmentValues ?? {},
                    showComponentIcons: false,
                    missingValuesPlaceholder: true,
                    displayBikeAdjustmentValues: false,
                    displayPersonAdjustmentValues: true,
                    displayRatingAdjustmentValues: false,
                  ),
                ),
              ],
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

    return widget.persons.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.filterWidget,
                Expanded(
                  child: Center(
                    child: Text(
                      'No profile yet',
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
            footer: widget.persons.length > visibleItemCount
                ? Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _maxItemCount += _itemCountIncrement),
                      icon: const Icon(Icons.expand_more),
                      label: const Text("Show more"),
                    ),
                  )
                : null,
            proxyDecorator: proxyDecorator,
            onReorder: widget.onReorderPerson,
            itemBuilder: (context, index) {
              return inkWells[index];
            },
          );
  }
}
