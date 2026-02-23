import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/app_settings.dart';
import '../models/filtered_data.dart';
import '../models/bike.dart';
import '../models/person.dart';
import 'adjustment_compact_display_list.dart';

class PersonListCard extends StatelessWidget {
  final Person person;
  final int index;
  final double? elevation;
  final Future<void> Function(Person person) editPerson;
  final Future<void> Function(Person person) duplicatePerson;
  final Future<void> Function(Person person) removePerson;

  const PersonListCard({
    super.key,
    required this.person,
    required this.index,
    this.elevation,
    required this.editPerson,
    required this.duplicatePerson,
    required this.removePerson,
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
    final filteredData = context.watch<FilteredData>();
    final bikes = filteredData.bikes;
    final setups = filteredData.setups;
    
    return Card(
      key: ValueKey(person.id),
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      clipBehavior: Clip.antiAlias, // Borderradius for InkWell
      child: InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: context.watch<AppSettings>().enableStrava 
                  ? Badge(
                      label: person.stravaAthlete == null
                          ? Icon(
                              Icons.link_off, 
                              size: 11, 
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            )
                          : !filteredData.stravaAthletes.containsKey(person.stravaAthlete)
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
              enabled: setups.values.lastWhereOrNull((s) => s.person == person.id) != null,
              subtitle: _bikeColumn(context, person: person, bikes: bikes),
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
                        case 'edit': editPerson(person);
                        case 'duplicate': duplicatePerson(person);
                        case 'remove': removePerson(person);
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
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: AdjustmentCompactDisplayList(
                components: [person],
                adjustmentValues: setups.values.lastWhereOrNull((s) => s.person == person.id)?.personAdjustmentValues ?? {},
                showComponentIcons: false,
                missingValuesPlaceholder: true,
                displayBikeAdjustmentValues: false,
                displayPersonAdjustmentValues: true,
                displayRatingAdjustmentValues: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
