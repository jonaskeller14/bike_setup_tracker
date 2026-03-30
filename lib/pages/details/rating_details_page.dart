import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_actions.dart';

class RatingDetailsPage extends StatelessWidget {
  final String ratingId;

  const RatingDetailsPage({super.key, required this.ratingId});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    final rating = appRepository.ratings[ratingId];
    if (rating == null) return const SizedBox.shrink();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Person.iconData),
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
              // Card.outlined(
              //   margin: const EdgeInsets.symmetric(vertical: 4),
              //   child: ListTile(
              //     leading: const Icon(Icons.filter_alt_outlined),
              //     title: Row(
              //       spacing: 8,
              //       children: [
              //         switch (rating.filterType) {
              //           FilterType.global => const Icon(Icons.circle_outlined),
              //           FilterType.bike => const Icon(Bike.iconData),
              //           FilterType.person => const Icon(Person.iconData),
              //           FilterType.component => ,
              //           FilterType.componentType => ,
              //         },
              //         Expanded(
              //           child: Text(
              //             //FIXME
              //             "Apply everywhere", 
              //             overflow: TextOverflow.ellipsis
              //           ),
              //         ),
              //       ],
              //     ),
              //     dense: true,
              //   ),
              // ),
              //TODO: Table view setup rating adjustment vlaues (analogue to ComponetDetailsPage)
            ],
          ),
        )
      ),
    );
  }
}
