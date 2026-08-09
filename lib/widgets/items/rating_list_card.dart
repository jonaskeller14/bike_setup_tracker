import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import '../../models/rating_association.dart';
import '../../pages/details/rating_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_actions.dart';
import '../notes_text.dart';

class RatingListCard extends StatelessWidget {
  final Rating rating;
  final int index;
  final double? elevation;

  const RatingListCard({
    super.key,
    required this.rating,
    required this.index,
    this.elevation,
  });

  Column _ratingAdjustmentsColumn(BuildContext context, {required Rating rating}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rating.metrics.map((metric) {
        return Text(
          "● ${metric.adjustment.name}",
          maxLines: 1, 
          overflow: TextOverflow.ellipsis, 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final persons = appRepository.persons;
    final components = appRepository.components;

    return Card(
      key:  ValueKey(rating.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      child: InkWell(
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => RatingDetailsPage(ratingId: rating.id),
            ),
          );
        },
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
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
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
                                ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.label ?? "-",
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
                          child: NotesText(
                            rating.notes!,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
                  PopupMenuButton<_RatingOptions>(
                    onSelected: (value) async {
                      switch (value) {
                        case _RatingOptions.edit:
                          await RatingActions.editRating(context, rating: rating);
                        case _RatingOptions.duplicate:
                          await RatingActions.duplicateRating(context, rating: rating);
                        case _RatingOptions.remove:
                          await RatingActions.removeRating(context, rating: rating);
                      }
                    },
                    itemBuilder: (BuildContext context) => _RatingOptions.values.map((option) {
                      return PopupMenuItem<_RatingOptions>(
                        value: option,
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(option.iconData, size: 20),
                            Text(option.label),
                          ],
                        ),
                      );
                    }).toList(),
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

enum _RatingOptions {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _RatingOptions(this.label, this.iconData);
}
