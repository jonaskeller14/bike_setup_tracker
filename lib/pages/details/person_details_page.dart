import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../utils/person_actions.dart';

class PersonDetailsPage extends StatelessWidget {
  final String personId;

  const PersonDetailsPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();

    final person = appRepository.persons[personId];
    if (person == null) return const SizedBox.shrink();

    final stravaAthlete = appRepository.stravaAthletes[person.stravaAthlete];
    
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (person.notes != null)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.notes),
                    titleAlignment: ListTileTitleAlignment.top,
                    title: SelectableText(person.notes!),
                    dense: true,
                  ),
                ),
              if (appSettings.enableStrava)
                Card.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: person.stravaAthlete != null
                        ? const Icon(Icons.link)
                        : const Icon(Icons.link_off),                  
                    title: Text(
                      stravaAthlete != null
                          ? "${stravaAthlete.firstname} ${stravaAthlete.lastname}"
                          : (person.stravaAthlete == null ? "No Strava Athlete linked to this person." : "STRAVA ATHLETE NOT FOUND"),
                      style: TextStyle(
                        color: person.stravaAthlete == null || stravaAthlete != null
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    dense: true,
                  ),
                ),
              //TODO: Table view setup person adjustment vlaues (analogue to ComponetDetailsPage)
            ],
          ),
        )
      ),
    );
  }
}
