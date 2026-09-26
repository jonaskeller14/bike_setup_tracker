import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/person.dart';
import '../../models/rating/rating.dart';
import '../../models/rating/rating_association.dart';

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
              switch (item.association) {
                GlobalRatingAssociation() => Icons.circle_outlined,
                BikeRatingAssociation() => Bike.iconData,
                PersonRatingAssociation() => Person.iconData,
                ComponentRatingAssociation(:final componentId) =>
                  (components[componentId]?.componentType ??
                          ComponentType.other)
                      .getIconData(),
                ComponentTypeRatingAssociation(:final componentTypeStr) =>
                  (ComponentType.values.firstWhereOrNull(
                            (ct) => ct.toString() == componentTypeStr,
                          ) ??
                          ComponentType.other)
                      .getIconData(),
              },
              size: 13,
              color: switch (item.association) {
                GlobalRatingAssociation() || ComponentTypeRatingAssociation() => Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                PersonRatingAssociation(:final personId) =>
                  persons.containsKey(personId)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                BikeRatingAssociation(:final bikeId) =>
                  bikes.containsKey(bikeId)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                ComponentRatingAssociation(:final componentId) =>
                  components.containsKey(componentId)
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
              },
            ),
            Flexible(
              child: switch (item.association) {
                GlobalRatingAssociation() => Text(
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
                BikeRatingAssociation(:final bikeId) => Text(
                  bikes[bikeId]?.name ?? "BIKE NOT FOUND",
                  style: TextStyle(
                    color: bikes.containsKey(bikeId)
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                PersonRatingAssociation(:final personId) => Text(
                  persons[personId]?.name ??
                      "PERSON NOT FOUND",
                  style: TextStyle(
                    color: persons.containsKey(personId)
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                ComponentRatingAssociation(:final componentId) => Text(
                  components[componentId]?.name ??
                      "COMPONENT NOT FOUND",
                  style: TextStyle(
                    color: components.containsKey(componentId)
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                ComponentTypeRatingAssociation(:final componentTypeStr) => Text(
                  ComponentType.values
                          .firstWhereOrNull(
                            (ct) => ct.toString() == componentTypeStr,
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
