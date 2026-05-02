import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_actions.dart';

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
    if (rating == null) return const SizedBox.shrink();
    
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (rating.notes != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.notes),
                    titleAlignment: ListTileTitleAlignment.top,
                    title: SelectableText(rating.notes!),
                    dense: true,
                  ),
                ),
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: Row(
                    spacing: 8,
                    children: switch (rating.filterType) {
                      FilterType.global => [
                          const Icon(Icons.circle_outlined),
                          const Expanded(child: Text("Apply everywhere", overflow: TextOverflow.ellipsis)),
                        ],
                      FilterType.bike => [
                          Icon(Bike.iconData, color: bikes[rating.filter] == null ? Theme.of(context).colorScheme.error : null),
                          Expanded(child: Text(
                            bikes[rating.filter]?.name ?? "BIKE NOT FOUND", 
                            overflow: TextOverflow.ellipsis,
                            style: bikes[rating.filter] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                          )),
                        ],
                      FilterType.person => [
                          Icon(Person.iconData, color: persons[rating.filter] == null ? Theme.of(context).colorScheme.error : null),
                          Expanded(child: Text(
                            persons[rating.filter]?.name ?? "PERSON NOT FOUND", 
                            overflow: TextOverflow.ellipsis,
                            style: persons[rating.filter] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                          )),
                        ],
                      FilterType.component => [
                          Icon(
                            components[rating.filter]?.componentType.getIconData() ?? Icons.error,
                            color: components[rating.filter] == null ? Theme.of(context).colorScheme.error : null,
                          ),
                          Expanded(child: Text(
                            components[rating.filter]?.name ?? "COMPONENT NOT FOUND", 
                            overflow: TextOverflow.ellipsis,
                            style: components[rating.filter] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                          )),
                        ],
                      FilterType.componentType => [
                          Icon(ComponentType.fromString(rating.filter).getIconData()),
                          Expanded(child: Text(ComponentType.fromString(rating.filter).label, overflow: TextOverflow.ellipsis)),
                        ],
                    },
                  ),
                  dense: true,
                ),
              ),
              //TODO: Table view setup rating adjustment vlaues (analogue to ComponetDetailsPage)
            ],
          ),
        ),
      ),
    );
  }
}
