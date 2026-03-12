import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../pages/person_page.dart';
import '../repositories/app_repository.dart';

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

  static Future<void> editPerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();

    final editedPerson = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage.edit(person: person),
      ),
    );
    if (editedPerson == null) return;

    await appRepository.editPerson(editedPerson);
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

    final obsoleteRatings = appRepository.ratings.values.where((r) => r.filterType == FilterType.person && r.filter == person.id);

    await appRepository.removePerson(person);
    await appRepository.removeRatings(obsoleteRatings);

    if (!context.mounted) return;

    String message = "Person '${person.name}' moved to trash.";
    if (obsoleteRatings.isNotEmpty && context.read<AppSettings>().enableRating) {
      message += "\n${obsoleteRatings.length} Ratings which belong to this person are deleted as well.";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => await appRepository.restorePerson(person),
      ),
    ));
  }

  static Future<void> onReorderPerson(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    appRepository.reorderPerson(oldIndex: oldIndex, newIndex: newIndex, filteredPersonsList: appRepository.filteredPersons.values.toList());
  }
}
