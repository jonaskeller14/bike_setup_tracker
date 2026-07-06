import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/person_actions.dart';
import '../../widgets/notes_text.dart';

class PersonDetailsPage extends StatelessWidget {
  final String personId;

  const PersonDetailsPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();

    final person = appRepository.persons[personId];
    if (person == null) return const SizedBox.shrink();

    final stravaAthlete = appRepository.stravaAthletes[person.stravaAthlete];
    final linkedBikes = appRepository.bikes.values.where((b) => b.person == person.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 8,
          children: [
            const Icon(Person.iconData),
            Expanded(
              child: Text(person.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => PersonActions.editPerson(context, person: person),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (person.notes != null)
                ListTile(
                  leading: const Icon(Icons.notes),
                  titleAlignment: ListTileTitleAlignment.titleHeight,
                  title: NotesText(person.notes!, maxLines: 10),
                  dense: true,
                ),

              if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement)
                ListTile(
                  leading: Badge(
                    label: const Icon(SimpleIcons.strava, size: 11),
                    backgroundColor: Colors.transparent,
                    child: person.stravaAthlete != null
                        ? Icon(Icons.link, color: appRepository.stravaAthletes.containsKey(person.stravaAthlete) ? null : Theme.of(context).colorScheme.error)
                        : const Icon(Icons.link_off),
                  ),
                  title: Text(
                    stravaAthlete != null
                        ? "${stravaAthlete.firstname} ${stravaAthlete.lastname}"
                        : (person.stravaAthlete == null
                            ? "No Strava Athlete linked to this person."
                            : "STRAVA ATHLETE NOT FOUND"),
                    style: TextStyle(
                      color: person.stravaAthlete == null || stravaAthlete != null
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),
              if (linkedBikes.isEmpty)
                const ListTile(
                  leading: Icon(Bike.iconData),
                  title: Text("No bikes linked to this person."),
                  dense: true,
                  enabled: false,
                )
              else
                ...linkedBikes.map((bike) => ListTile(
                  leading: const Icon(Bike.iconData),
                  title: Text(bike.name),
                  dense: true,
                )),
            ],
          ),
        )
      ),
    );
  }
}
