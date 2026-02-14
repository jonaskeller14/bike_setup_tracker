import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/filtered_data.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/component.dart';

class RatingListCard extends StatelessWidget {
  final Rating rating;
  final int index;
  final double? elevation;
  final Future<void> Function(Rating rating) editRating;
  final Future<void> Function(Rating rating) duplicateRating;
  final Future<void> Function(Rating rating) removeRating;

  const RatingListCard({
    super.key,
    required this.rating,
    required this.index,
    this.elevation,
    required this.editRating,
    required this.duplicateRating,
    required this.removeRating,
  });

  Column _ratingAdjustmentsColumn(BuildContext context, {required Rating rating}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rating.adjustments.map((adjustment) {
        return Text(
          "● ${adjustment.name}", 
          maxLines: 1, 
          overflow: TextOverflow.ellipsis, 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final bikes = filteredData.bikes;
    final persons = filteredData.persons;
    final components = filteredData.components;

    return Card(
      key:  ValueKey(rating.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      child: InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Rating.iconData),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                rating.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            switch(rating.filterType) {
                              FilterType.global => Icons.circle_outlined,
                              FilterType.bike => Bike.iconData,
                              FilterType.person => Person.iconData,
                              FilterType.component => (components[rating.filter]?.componentType ?? ComponentType.other).getIconData(),
                              FilterType.componentType => (ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter) ?? ComponentType.other).getIconData(),
                            },
                            size: 13, 
                            color: switch(rating.filterType) {
                              FilterType.global || FilterType.componentType  => Theme.of(context).colorScheme.onSurfaceVariant,
                              FilterType.person => persons.containsKey(rating.filter) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
                              FilterType.bike => bikes.containsKey(rating.filter) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
                              FilterType.component => components.containsKey(rating.filter) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
                            },
                          ),
        
                          const SizedBox(width: 2),
                          
                          Flexible(
                            child: switch(rating.filterType) {
                              FilterType.global => Text(
                                "Global",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              FilterType.bike => Text(
                                bikes[rating.filter]?.name ?? "BIKE NOT FOUND",
                                style: TextStyle(
                                  color: bikes.containsKey(rating.filter) 
                                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) 
                                      : Theme.of(context).colorScheme.error, 
                                  fontSize: 13
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              FilterType.person => Text(
                                persons[rating.filter]?.name ?? "PERSON NOT FOUND",
                                style: TextStyle(
                                  color: persons.containsKey(rating.filter) 
                                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) 
                                      : Theme.of(context).colorScheme.error,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              FilterType.component => Text(
                                components[rating.filter]?.name ?? "COMPONENT NOT FOUND",
                                style: TextStyle(
                                  color: components.containsKey(rating.filter) 
                                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) 
                                      : Theme.of(context).colorScheme.error,
                                  fontSize: 13
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              FilterType.componentType => Text(
                                ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.value ?? "-",
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (rating.notes != null && rating.notes!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.notes,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            rating.notes!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
                        case 'edit': editRating(rating);
                        case 'duplicate': duplicateRating(rating);
                        case 'remove': removeRating(rating);
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ratingAdjustmentsColumn(context, rating: rating),
            ),
          ],
        ),
      ),
    );
  }
}
