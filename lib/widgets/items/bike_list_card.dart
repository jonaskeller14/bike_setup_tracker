import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../pages/details/bike_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/bike_actions.dart';

class BikeListCard extends StatelessWidget{
  final Bike bike;
  final int index;
  final double? elevation;

  const BikeListCard({
    super.key, 
    required this.bike, 
    required this.index,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final persons = appRepository.persons;
    
    return Card(
      key: ValueKey(bike.id),
      elevation: elevation,
      color: bike.id == appRepository.selectedBike ? Theme.of(context).colorScheme.secondaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      child: InkWell(
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => BikeDetailsPage(bikeId: bike.id),
            ),
          );
        },
        onDoubleTap: () => appRepository.onBikeTap(bike.id),
        child: Opacity(
          opacity: bike.id == appRepository.selectedBike || appRepository.selectedBike == null ? 1 : 0.3,
          child: ListTile(
            dense: true,
            leading: appSettings.enableStrava && subscriptionService.hasStravaEntitlement
                ? Badge(
                    label: bike.stravaGear == null
                        ? Icon(
                            Icons.link_off, 
                            size: 11, 
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          )
                        : !appRepository.stravaGears.containsKey(bike.stravaGear)
                            ? Icon(Icons.error_outline, size: 11, color: Theme.of(context).colorScheme.error)
                            : const Icon(SimpleIcons.strava, size: 10, color: Color(0xFFFC4C02)),
                    backgroundColor: Colors.transparent,
                    child: const Icon(Bike.iconData),
                  )
                : const Icon(Bike.iconData),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              bike.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: appSettings.enablePerson || (bike.notes != null && bike.notes!.isNotEmpty) 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (appSettings.enablePerson)
                        Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 2,
                              children: [
                                Icon(bike.person != null
                                    ? Person.iconData 
                                    : Icons.person_off, 
                                  size: 13, 
                                  color: bike.person == null || persons.containsKey(bike.person) 
                                      ? Theme.of(context).colorScheme.onSurfaceVariant 
                                      : Theme.of(context).colorScheme.error,
                                ),
                                if (bike.person != null)
                                  Flexible(
                                    child: Text(
                                      persons[bike.person]?.name ?? "PERSON NOT FOUND",
                                      style: TextStyle(
                                        color: bike.person == null || persons.containsKey(bike.person) 
                                            ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8) 
                                            : Theme.of(context).colorScheme.error, 
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      if (bike.notes != null && bike.notes!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3), // tweak to match font size
                              child: Icon(
                                Icons.notes,
                                size: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                bike.notes!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                PopupMenuButton<_BikeOptions>(
                  onSelected: (value) async {
                    switch (value) {
                      case _BikeOptions.edit:
                        await BikeActions.editBike(context, bike: bike);
                      case _BikeOptions.duplicate: 
                        await BikeActions.duplicateBikeWithoutComponents(context, bike: bike);
                      case _BikeOptions.remove:
                        await BikeActions.removeBike(context, bike: bike);
                    }
                  },
                  itemBuilder: (BuildContext context) => _BikeOptions.values.map((option) {
                    return PopupMenuItem<_BikeOptions>(
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
            )
          ),
        ),
      ),
    );
  }
}

enum _BikeOptions {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _BikeOptions(this.label, this.iconData);
}
