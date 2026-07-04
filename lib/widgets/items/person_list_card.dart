import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../pages/details/person_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/person_actions.dart';
import '../lists/adjustment_compact_display_list.dart';

class PersonListCard extends StatelessWidget {
  final Person person;
  final int index;
  final double? elevation;

  const PersonListCard({
    super.key,
    required this.person,
    required this.index,
    this.elevation,
  });

  Column _bikeColumn(BuildContext context, {required Person person, required Map<String, Bike> bikes}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bikes.values.where((b) => b.person == person.id).map((bike) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(Bike.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            Flexible(
              child: Text(
                bike.name,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final bikes = appRepository.bikes;
    
    return Card(
      key: ValueKey(person.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      child: InkWell(
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailsPage(personId: person.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: context.watch<AppSettings>().enableStrava && subscriptionService.hasStravaEntitlement
                  ? Badge(
                      label: person.stravaAthlete == null
                          ? Icon(
                              Icons.link_off, 
                              size: 11, 
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            )
                          : !appRepository.stravaAthletes.containsKey(person.stravaAthlete)
                              ? Icon(Icons.error_outline, size: 11, color: Theme.of(context).colorScheme.error)
                              : const Icon(SimpleIcons.strava, size: 10, color: Color(0xFFFC4C02)),
                      backgroundColor: Colors.transparent,
                      child: const Icon(Person.iconData),
                    )
                  : const Icon(Person.iconData),
              minTileHeight: 0,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                person.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: _bikeColumn(context, person: person, bikes: bikes),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  PopupMenuButton<_PersonOptions>(
                    onSelected: (_PersonOptions value) async {
                      switch (value) {
                        case _PersonOptions.edit:
                          await PersonActions.editPerson(context, person: person);
                        case _PersonOptions.duplicate:
                          await PersonActions.duplicatePerson(context, person: person);
                        case _PersonOptions.remove:
                          await PersonActions.removePerson(context, person: person);
                      }
                    },
                    itemBuilder: (BuildContext context) => _PersonOptions.values.map((option) {
                      return PopupMenuItem<_PersonOptions>(
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
              padding: const EdgeInsets.only(bottom: 8),
              child: AdjustmentCompactDisplayList(
                persons: [person],
                adjustmentValues: appRepository.currentAdjustmentValues,
                showRowIcons: false,
                missingValuesPlaceholder: true,
                displayBikeAdjustmentValues: false,
                displayPersonAdjustmentValues: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PersonOptions {
  edit("Edit", Icons.edit),
  duplicate("Duplicate", Icons.copy),
  remove("Remove", Icons.delete);
  final String label;
  final IconData iconData;
  const _PersonOptions(this.label, this.iconData);
}
