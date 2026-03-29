import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';

class BikeDetailsPage extends StatelessWidget {
  final String bikeId;

  const BikeDetailsPage({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();

    final bike = appRepository.bikes[bikeId];
    if (bike == null) return const SizedBox.shrink();

    final person = appRepository.persons[bike.person];
    final stravaGear = appRepository.stravaGears[bike.stravaGear];
    final components = appRepository.components.values.where((c) => c.bike == bike.id);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Bike.iconData),
            Expanded(
              child: Text(bike.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => BikeActions.editBike(context, bike: bike),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (bike.notes != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.notes),
                    titleAlignment: ListTileTitleAlignment.top,
                    title: SelectableText(bike.notes!),
                    dense: true,
                  ),
                ),
              if (appSettings.enablePerson)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: bike.person != null
                        ? const Icon(Person.iconData)
                        : const Icon(Icons.person_off),
                    title: Text(
                      person?.name ?? (bike.person == null ? "No bike owner person specified." : "PERSON NOT FOUND"),
                      style: TextStyle(
                        color: bike.person == null || person != null
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    dense: true,
                  ),
                ),
              if (appSettings.enableStrava)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: bike.stravaGear != null
                        ? const Icon(Icons.link)
                        : const Icon(Icons.link_off),                  
                    title: Text(
                      stravaGear?.name ?? (bike.stravaGear == null ? "No Strava Gear linked to this bike." : "STRAVA GEAR NOT FOUND"),
                      style: TextStyle(
                        color: bike.stravaGear == null || stravaGear != null
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    dense: true,
                  ),
                ),
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Components", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(Intl.plural(
                          components.length,
                          zero: "No components yet.",
                          one: "1 component",
                          other: '${components.length} components',
                        )),
                    ),
                    ...components.map((component) {
                      return ListTile(
                        leading: Icon(component.componentType.getIconData()),
                        title: Text(component.name),
                        dense: true,
                      );
                    })
                  ],
                )
              ),
            ],
          ),
        )
      ),
    );
  }
}