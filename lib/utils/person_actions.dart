import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../models/rating/rating_association.dart';
import '../pages/adjustment/adjustment_page.dart';
import '../pages/adjustment/boolean_adjustment_page.dart';
import '../pages/adjustment/categorical_adjustment_page.dart';
import '../pages/adjustment/duration_adjustment_page.dart';
import '../pages/adjustment/numerical_adjustment_page.dart';
import '../pages/adjustment/sag_adjustment_page.dart';
import '../pages/adjustment/step_adjustment_page.dart';
import '../pages/adjustment/text_adjustment_page.dart';
import '../pages/forms/person_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/bike_link_sheet.dart';
import '../widgets/sheets/person_add_adjustment.dart';
import 'setup_actions.dart';

class PersonActions {
  static Future<void> addPerson(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (context) => PersonPage.add()),
    );
    if (person == null) return;

    await appRepository.addPersons([person]);
  }

  static Future<void> addPersonForBike(BuildContext context, {required String bikeId}) async {
    final appRepository = context.read<AppRepository>();

    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (context) => PersonPage.add()),
    );
    if (person == null) return;

    await appRepository.addPersons([person]);
    if (!context.mounted) return;
    await linkPersonToBike(context, bikeId: bikeId, person: person);
  }

  static Future<void> linkPersonToBike(BuildContext context, {required String bikeId, required Person person}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final bike = appRepository.bikes[bikeId];
    if (bike == null) {
      messenger.showSnackBar(AppSnackBar.error(context, 'Bike not found.'));
      return;
    }

    await appRepository.editBikes([bike.copyWith(person: person.id)]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(context, "'${person.name}' is now the rider of '${bike.name}'."),
    );
  }

  static Future<Person?> createRider(BuildContext context, {required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final person = Person(name: trimmed, adjustments: [ridingWeightPreset.deepCopy()]);
    await context.read<AppRepository>().addPersons([person]);
    return person;
  }

  static Future<Person?> createRiderForBike(BuildContext context, {required String name, required String bikeId}) async {
    final appRepository = context.read<AppRepository>();

    final person = await createRider(context, name: name);
    if (person == null) return null;

    final bike = appRepository.bikes[bikeId];
    if (bike != null) await appRepository.editBikes([bike.copyWith(person: person.id)]);
    return person;
  }

  /// No snackbar: the card menu also opens this inside the rider sheet, where
  /// a snackbar would render behind it. The card's bike list shows the result.
  static Future<void> editBikeLinks(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();

    final linkedIds = await showBikeLinkSheet(context, person: person);
    if (linkedIds == null) return;

    await appRepository.editBikes([
      for (final bike in appRepository.bikes.values)
        if (linkedIds.contains(bike.id) != (bike.person == person.id))
          bike.copyWith(person: linkedIds.contains(bike.id) ? person.id : null),
    ]);
  }

  /// The bike a new setup for [person] starts on: the selected filter bike if
  /// it is linked to [person], else the first linked bike.
  static Bike? recordTargetBike(AppRepository appRepository, {required Person person}) {
    final selected = appRepository.bikes[appRepository.filters.bikeId];
    if (selected?.person == person.id) return selected;
    return appRepository.bikes.values.where((bike) => bike.person == person.id).firstOrNull;
  }

  static Future<void> recordRiderValues(BuildContext context, {required Person person}) async {
    final bike = recordTargetBike(context.read<AppRepository>(), person: person);
    if (bike == null) return;
    await SetupActions.addSetup(context, initialBike: bike, openRiderTab: true);
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

    await appRepository.addPersons([newPerson]);
  }

  static Future<void> removePerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();
    final messenger = ScaffoldMessenger.of(context);

    final obsoleteRatings = appRepository.ratings.values
        .where((r) => r.association == PersonRatingAssociation(person.id))
        .toList();

    await appRepository.removePersons([person]);
    await appRepository.removeRatings(obsoleteRatings);

    String message = "Rider '${person.name}' moved to trash.";
    if (obsoleteRatings.isNotEmpty && appSettings.enableRating) {
      message += "\n${obsoleteRatings.length} Ratings which belong to this rider are deleted as well.";
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        message,
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.restorePersons([person]),
        ),
      ),
    );
  }

  static Future<void> restorePerson(BuildContext context, {required Person person}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restorePersons([person]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Rider '${person.name}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removePersons([person]),
        ),
      ),
    );
  }

  static Future<void> onReorderPerson(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderPerson(
      oldIndex: oldIndex,
      newIndex: newIndex,
      filteredPersonsList: appRepository.view.persons.values.toList(),
    );
  }

  static Future<void> addAdjustmentForPerson(BuildContext context, {required Person person}) async {
    showPersonAddAdjustmentBottomSheet(
      context: context,
      existingAdjustments: person.adjustments,
      addAdjustmentFromPreset: (Adjustment adjustment) async {
        final appRepository = context.read<AppRepository>();
        final newAdjustment = await Navigator.push<Adjustment>(
          context,
          MaterialPageRoute(
            builder: (context) => switch (adjustment.deepCopy()) {
              final BooleanAdjustment a => BooleanAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
              final CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
              final StepAdjustment a => StepAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
              final SagAdjustment a => SagAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
              final NumericalAdjustment a => NumericalAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
              final TextAdjustment a => TextAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
              final DurationAdjustment a => DurationAdjustmentPage.template(adjustment: a, term: AdjustmentTerm.attribute),
            },
          ),
        );
        if (newAdjustment == null) return;
        await appRepository.editPerson(person.copyWith(adjustments: [...person.adjustments, newAdjustment]));
      },
      addAdjustment: <T extends Adjustment>() async {
        final appRepository = context.read<AppRepository>();
        final newAdjustment = await Navigator.push<T>(
          context,
          MaterialPageRoute(
            builder: (context) => switch (T) {
              const (BooleanAdjustment) => BooleanAdjustmentPage.add(term: AdjustmentTerm.attribute),
              const (CategoricalAdjustment) => CategoricalAdjustmentPage.add(term: AdjustmentTerm.attribute),
              const (StepAdjustment) => StepAdjustmentPage.add(term: AdjustmentTerm.attribute),
              const (NumericalAdjustment) => NumericalAdjustmentPage.add(term: AdjustmentTerm.attribute),
              const (TextAdjustment) => TextAdjustmentPage.add(term: AdjustmentTerm.attribute),
              const (DurationAdjustment) => DurationAdjustmentPage.add(term: AdjustmentTerm.attribute),
              Type() => throw UnimplementedError(),
            },
          ),
        );
        if (newAdjustment == null) return;
        await appRepository.editPerson(person.copyWith(adjustments: [...person.adjustments, newAdjustment]));
      },
    );
  }
}
