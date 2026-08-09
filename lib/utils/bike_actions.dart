import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/rating_association.dart';
import '../pages/bike_page.dart';
import '../repositories/app_repository.dart';

class BikeActions {
  static Future<void> addBike(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => BikePage.add()),
    );
    if (bike == null) return;

    await appRepository.addBike(bike);
  }

  static Future<void> editBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();

    final editedBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.edit(bike: bike),
      ),
    );
    if (editedBike == null) return;

    await appRepository.editBike(editedBike);
  }

  static Future<void> duplicateBikeWithoutComponents(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();

    final newBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.duplicate(bike: bike.deepCopy()),
      ),
    );
    if (newBike == null) return;

    await appRepository.addBike(newBike);
  }

  static Future<void> duplicateBikeWithComponents(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final bikeComponents = appRepository.components.values.where((c) => c.bike == bike.id).toList();

    final newBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.duplicate(bike: bike.deepCopy()),
      ),
    );
    if (newBike == null) return;

    await appRepository.addBike(newBike);
    await Future.wait(
      bikeComponents.map((c) => appRepository.addComponent(c.deepCopy().copyWithNewInstallation(newBike.id))),
    );
  }

  static Future<void> removeBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();
    final messenger = ScaffoldMessenger.of(context);

    final obsoleteComponents = appRepository.components.values.where((c) => c.bike == bike.id).toList();
    final obsoleteSetups = appRepository.setups.values.where((s) => s.bike == bike.id).toList();
    final obsoleteRatings = appRepository.ratings.values
        .where((r) => r.filterType == FilterType.bike && r.filter == bike.id)
        .toList();

    await appRepository.removeBike(bike);
    await appRepository.removeComponents(obsoleteComponents);
    await appRepository.removeSetups(obsoleteSetups);
    await appRepository.removeRatings(obsoleteRatings);

    String message = "Bike '${bike.name}' moved to trash.";
    if (appSettings.enableRating) {
      if (obsoleteComponents.isNotEmpty || obsoleteSetups.isNotEmpty || obsoleteRatings.isNotEmpty) {
        message +=
            "\n${obsoleteComponents.length} Components, ${obsoleteSetups.length} Setups and ${obsoleteRatings.length} Ratings which belong to this Bike are deleted as well.";
      }
    } else {
      if (obsoleteComponents.isNotEmpty || obsoleteSetups.isNotEmpty) {
        message +=
            "\n${obsoleteComponents.length} Components, ${obsoleteSetups.length} Setups which belong to this Bike are deleted as well.";
      }
    }
    messenger.showSnackBar(
      SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 10),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.restoreBike(bike);
          await appRepository.restoreComponents(obsoleteComponents);
          await appRepository.restoreSetups(obsoleteSetups);
          await appRepository.restoreRatings(obsoleteRatings);
        },
      ),
      ),
    );
  }

  static Future<void> restoreBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreBike(bike);

    messenger.showSnackBar(
      SnackBar(
      content: Text("Bike '${bike.name}' restored from trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.removeBike(bike);
        },
      ),
      ),
    );
  }

  static Future<void> onReorderBikes(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderBike(
      oldIndex: oldIndex,
      newIndex: newIndex,
      filteredBikesList: appRepository.bikes.values.toList(),
    );
  }
}
