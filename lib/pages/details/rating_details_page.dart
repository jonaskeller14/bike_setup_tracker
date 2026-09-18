import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/rating/rating.dart';
import '../../models/rating/rating_association.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_actions.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/notes_text.dart';

class RatingDetailsPage extends StatelessWidget {
  final String ratingId;

  const RatingDetailsPage({super.key, required this.ratingId});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final persons = appRepository.persons;
    final components = appRepository.components;

    final rating = appRepository.ratings[ratingId];
    if (rating == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const SafeArea(
          child: EmptyStatePlaceholder.error(
            title: "Rating not found",
            subtitle: "This rating was deleted or is no longer available.",
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Rating.iconData),
            Expanded(
              child: Text(rating.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => RatingActions.editRating(context, rating: rating),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Badge(
                  label: switch (rating.association) {
                    GlobalRatingAssociation() => const Icon(Icons.circle_outlined, size: 11),
                    BikeRatingAssociation(:final bikeId) => Icon(Bike.iconData, color: bikes[bikeId] == null ? Theme.of(context).colorScheme.error : null, size: 11),
                    PersonRatingAssociation(:final personId) => Icon(Person.iconData, color: persons[personId] == null ? Theme.of(context).colorScheme.error : null, size: 11),
                    ComponentRatingAssociation(:final componentId) => Icon(
                      components[componentId]?.componentType.getIconData() ?? Icons.error,
                      color: components[componentId] == null ? Theme.of(context).colorScheme.error : null,
                      size: 11
                    ),
                    ComponentTypeRatingAssociation(:final componentTypeStr) => Icon(ComponentType.fromString(componentTypeStr).getIconData(), size: 11),
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.filter_alt_outlined),
                ),
                title: switch (rating.association) {
                  GlobalRatingAssociation() => const Text("Apply everywhere", overflow: TextOverflow.ellipsis),
                  BikeRatingAssociation(:final bikeId) => Text(
                    bikes[bikeId]?.name ?? "BIKE NOT FOUND", 
                    overflow: TextOverflow.ellipsis,
                    style: bikes[bikeId] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                  ),
                  PersonRatingAssociation(:final personId) => Text(
                    persons[personId]?.name ?? "PERSON NOT FOUND", 
                    overflow: TextOverflow.ellipsis,
                    style: persons[personId] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                  ),
                  ComponentRatingAssociation(:final componentId) => Text(
                    components[componentId]?.name ?? "COMPONENT NOT FOUND", 
                    overflow: TextOverflow.ellipsis,
                    style: components[componentId] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                  ),
                  ComponentTypeRatingAssociation(:final componentTypeStr) => Text(ComponentType.fromString(componentTypeStr).label, overflow: TextOverflow.ellipsis),
                },
                dense: true,
              ),

              if (rating.notes != null)
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.titleHeight,
                  title: NotesText(rating.notes!, maxLines: 10),
                  dense: true,
                ),

              const Divider(height: 1),

              //TODO: Table view setup rating adjustment vlaues (analogue to ComponetDetailsPage)
            ],
          ),
        ),
      ),
    );
  }
}
