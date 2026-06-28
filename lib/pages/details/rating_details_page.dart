import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/person.dart';
import '../../models/rating.dart';
import '../../models/rating_association.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Badge(
                  label: switch (rating.filterType) {
                    FilterType.global => const Icon(Icons.circle_outlined, size: 11),
                    FilterType.bike => Icon(Bike.iconData, color: bikes[rating.filter] == null ? Theme.of(context).colorScheme.error : null, size: 11),
                    FilterType.person => Icon(Person.iconData, color: persons[rating.filter] == null ? Theme.of(context).colorScheme.error : null, size: 11),
                    FilterType.component => Icon(
                      components[rating.filter]?.componentType.getIconData() ?? Icons.error,
                      color: components[rating.filter] == null ? Theme.of(context).colorScheme.error : null,
                      size: 11
                    ),
                    FilterType.componentType => Icon(ComponentType.fromString(rating.filter).getIconData(), size: 11),
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: const Icon(Icons.filter_alt_outlined),
                ),
                title: switch (rating.filterType) {
                  FilterType.global => const Text("Apply everywhere", overflow: TextOverflow.ellipsis),
                  FilterType.bike => Text(
                    bikes[rating.filter]?.name ?? "BIKE NOT FOUND", 
                    overflow: TextOverflow.ellipsis,
                    style: bikes[rating.filter] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                  ),
                  FilterType.person => Text(
                    persons[rating.filter]?.name ?? "PERSON NOT FOUND", 
                    overflow: TextOverflow.ellipsis,
                    style: persons[rating.filter] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                  ),
                  FilterType.component => Text(
                    components[rating.filter]?.name ?? "COMPONENT NOT FOUND", 
                    overflow: TextOverflow.ellipsis,
                    style: components[rating.filter] == null ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                  ),
                  FilterType.componentType => Text(ComponentType.fromString(rating.filter).label, overflow: TextOverflow.ellipsis),
                },
                dense: true,
              ),

              if (rating.notes != null)
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.titleHeight,
                  title: SelectableText(rating.notes!),
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
