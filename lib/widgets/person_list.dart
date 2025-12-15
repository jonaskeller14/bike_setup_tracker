import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/setup.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../widgets/adjustment_display_list.dart';

const defaultVisibleCount = 3;

class PersonList extends StatefulWidget {
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;
  final List<Setup> setups;
  final void Function(Person person) editPerson;
  final void Function(Person person) duplicatePerson;
  final void Function(Person person) removePerson;
  final void Function(int oldIndex, int newIndex) onReorderPerson;

  const PersonList({
    super.key,
    required this.bikes,
    required this.persons,
    required this.setups,
    required this.editPerson,
    required this.duplicatePerson,
    required this.removePerson,
    required this.onReorderPerson,
  });

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  bool _expanded = false;

  Column _bikeColumn(Person person) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.bikes.values.where((b) => b.person == person.id).map((bike) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pedal_bike, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              bike.name,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded
        ? widget.persons.length
        : widget.persons.length.clamp(0, defaultVisibleCount);
    
    final List<Card> cards = <Card>[];
    for (var index = 0; index < visibleCount; index++) {
      final person = widget.persons.values.toList()[index];
      cards.add(
        Card(
          key: ValueKey(person.id),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                minTileHeight: 0,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  person.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                enabled: widget.setups.lastWhereOrNull((s) => s.person == person.id) != null,
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
                child: AdjustmentDisplayList(
                  components: [person],
                  adjustmentValues: widget.setups.lastWhereOrNull((s) => s.person == person.id)?.personAdjustmentValues ?? {},
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

    return widget.persons.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            itemCount: visibleCount,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            proxyDecorator: proxyDecorator,
            header: null,
            footer: widget.persons.length > defaultVisibleCount
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
            onReorder: widget.onReorderPerson,
            itemBuilder: (context, index) {
              return cards[index];
            },
          );
  }
}
