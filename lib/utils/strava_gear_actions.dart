import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bike.dart';
import '../models/strava/strava_gear.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class StravaGearActions {
  static Future<void> linkBike(BuildContext context, {required StravaGear gear, required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    unawaited(HapticFeedback.selectionClick());
    await appRepository.editBike(bike.copyWith(stravaGear: gear.id));

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        "Linked '${gear.name}' to '${bike.name}'.",
        action: AppSnackBarAction(label: 'UNDO', onPressed: () => unawaited(appRepository.editBike(bike))),
      ),
    );
  }

  static Future<void> unlinkBike(BuildContext context, {required StravaGear gear, required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    unawaited(HapticFeedback.selectionClick());
    await appRepository.editBike(bike.copyWith(stravaGear: null));

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Unlinked '${gear.name}' from '${bike.name}'.",
        action: AppSnackBarAction(label: 'UNDO', onPressed: () => unawaited(appRepository.editBike(bike))),
      ),
    );
  }

  static Future<void> addAsNewBike(BuildContext context, {required StravaGear gear}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final newBike = Bike(
      name: gear.name,
      person: appRepository.persons.values.firstOrNull?.id,
      stravaGear: gear.id,
    );

    unawaited(HapticFeedback.selectionClick());
    await appRepository.addBikes([newBike]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        "Added bike '${newBike.name}' and linked it to '${gear.name}'.",
        action: AppSnackBarAction(label: 'UNDO', onPressed: () => unawaited(appRepository.removeBikes([newBike]))),
      ),
    );
  }
}
