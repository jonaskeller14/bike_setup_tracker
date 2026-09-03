import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/person.dart';
import '../models/rating_association.dart';
import '../pages/person_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/person_add_adjustment.dart';

class PersonActions {
  static Future<void> addPerson(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (context) => PersonPage.add()),
    );
    if (person == null) return;

    await appRepository.addPerson(person);
  }

  static Future<Person?> createOnboardingRider(BuildContext context, {required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final person = Person(name: trimmed, adjustments: [ridingWeightPreset.deepCopy()]);
    await context.read<AppRepository>().addPerson(person);
    return person;
  }

  static Future<void> editPerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();

    final result = await Navigator.push<EditResult<Person>>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage.edit(person: person),
      ),
    );
    if (result == null) return;

    await appRepository.editPerson(result.value, conversions: result.conversions);
  }

  static Future<void> duplicatePerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();

    final newPerson = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage.duplicate(person: person.deepCopy()),
      ),
    );
    if (newPerson == null) return;

    await appRepository.addPerson(newPerson);
  }

  static Future<void> removePerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();
    final messenger = ScaffoldMessenger.of(context);

    final obsoleteRatings = appRepository.ratings.values
        .where((r) => r.filterType == FilterType.person && r.filter == person.id)
        .toList();

    await appRepository.removePerson(person);
    await appRepository.removeRatings(obsoleteRatings);

    String message = "Person '${person.name}' moved to trash.";
    if (obsoleteRatings.isNotEmpty && appSettings.enableRating) {
      message += "\n${obsoleteRatings.length} Ratings which belong to this person are deleted as well.";
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        message,
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.restorePerson(person),
        ),
      ),
    );
  }

  static Future<void> restorePerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restorePerson(person);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Person '${person.name}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removePerson(person),
        ),
      ),
    );
  }

  static Future<void> onReorderPerson(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderPerson(
      oldIndex: oldIndex,
      newIndex: newIndex,
      filteredPersonsList: appRepository.filteredPersons.values.toList(),
    );
  }
}
