import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_list_card.dart';

class PersonList extends StatelessWidget {
  final Map<String, Person> persons;
  final Future<void> Function(Person person) editPerson;
  final Future<void> Function(Person person) duplicatePerson;
  final Future<void> Function(Person person) removePerson;
  final Future<void> Function(int oldIndex, int newIndex) onReorderPerson;
  final Widget filterWidget;

  const PersonList({
    super.key,
    required this.persons,
    required this.editPerson,
    required this.duplicatePerson,
    required this.removePerson,
    required this.onReorderPerson,
    required this.filterWidget,
  });

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterWidget,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final personsList = persons.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: PersonListCard(
              person: personsList[index],
              index: index,
              elevation: elevation,
              editPerson: editPerson,
              duplicatePerson: duplicatePerson, 
              removePerson: removePerson,
            ),
          );
        },
        child: child,
      );
    }

    return personsList.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: personsList.length,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: filterWidget,
            proxyDecorator: proxyDecorator,
            onReorder: onReorderPerson,
            itemBuilder: (context, index) {
              final person = personsList[index];
              return PersonListCard(
                key: ValueKey(person.id),
                person: person,
                index: index,
                editPerson: editPerson,
                duplicatePerson: duplicatePerson,
                removePerson: removePerson,
              );
            },
          );
  }
}
