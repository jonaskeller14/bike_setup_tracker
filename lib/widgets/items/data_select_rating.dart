import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import '../../models/rating_association.dart';

class DataSelectRating extends StatelessWidget {
  final Rating item;
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;
  final Map<String, Component> components;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectRating({
    super.key,
    required this.item,
    required this.bikes,
    required this.persons,
    required this.components,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Rating.iconData),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(
              switch (item.filterType) {
                FilterType.global => Icons.circle_outlined,
                FilterType.bike => Bike.iconData,
                FilterType.person => Person.iconData,
                FilterType.component =>
                  (components[item.filter]?.componentType ??
                          ComponentType.other)
                      .getIconData(),
                FilterType.componentType =>
                  (ComponentType.values.firstWhereOrNull(
                            (ct) => ct.toString() == item.filter,
                          ) ??
                          ComponentType.other)
                      .getIconData(),
              },
              size: 13,
              color: switch (item.filterType) {
                FilterType.global || FilterType.componentType => Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                FilterType.person =>
                  persons.containsKey(item.filter)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                FilterType.bike =>
                  bikes.containsKey(item.filter)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                FilterType.component =>
                  components.containsKey(item.filter)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
              },
            ),
            Flexible(
              child: switch (item.filterType) {
                FilterType.global => Text(
                  "Global",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                FilterType.bike => Text(
                  bikes[item.filter]?.name ?? "BIKE NOT FOUND",
                  style: TextStyle(
                    color: bikes.containsKey(item.filter)
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                FilterType.person => Text(
                  persons[item.filter]?.name ??
                      "PERSON NOT FOUND",
                  style: TextStyle(
                    color: persons.containsKey(item.filter)
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                FilterType.component => Text(
                  components[item.filter]?.name ??
                      "COMPONENT NOT FOUND",
                  style: TextStyle(
                    color: components.containsKey(item.filter)
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                FilterType.componentType => Text(
                  ComponentType.values
                          .firstWhereOrNull(
                            (ct) => ct.toString() == item.filter,
                          )
                          ?.label ??
                      "-",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              },
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
