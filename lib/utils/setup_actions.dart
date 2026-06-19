import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rating_entry.dart';
import '../models/setup.dart';
import '../pages/rating_entry_page.dart';
import '../pages/setup_page.dart';
import '../repositories/app_repository.dart';
import '../services/share_service.dart';
import 'bike_actions.dart';
import 'component_actions.dart';
import 'to_text.dart';

class SetupActions {
  static Future<void> addSetup(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    if (appRepository.bikes.values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true, 
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a bike first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        action: SnackBarAction(
          label: 'ADD',
          textColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: () => BikeActions.addBike(context),
        ),
      ));
      return;
    }
    if (appRepository.components.values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true, 
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a component first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        action: SnackBarAction(
          label: 'ADD',
          textColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: () => ComponentActions.addComponent(context),
        ),
      ));
      return;
    }

    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.add()),
    );
    if (newSetup == null) return;

    await appRepository.addSetup(newSetup);
  }

  static Future<void> editSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.edit(setup: setup)),
    );
    if (editedSetup == null) return;

    await appRepository.editSetup(editedSetup);
  }

  static Future<void> duplicateSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    
    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.duplicate(setup: setup.deepCopy())),
    );
    if (newSetup == null) return;

    await appRepository.addSetup(newSetup);
  }

  static Future<void> removeSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.removeSetups([setup]);

    messenger.showSnackBar(SnackBar(
      content: Text("Setup '${setup.displayName}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.restoreSetups([setup]),
      ),
    ));
  }

  static Future<void> restoreSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreSetups([setup]);

    messenger.showSnackBar(SnackBar(
      content: Text("Setup '${setup.displayName}' restored from trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async => appRepository.removeSetups([setup]),
      ),
    ));
  }


  static Future<void> shareSetup(BuildContext context, {required Setup setup}) async {
    final String content = setupToText(
      context: context,
      setup: setup,
    );
    
    await ShareService.shareText(
      context: context,
      text: content,
    );
  }

  static Future<void> addRatingEntryForSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final bike = appRepository.bikes[setup.bike];

    final newRatingEntry = await Navigator.push<RatingEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingEntryPage.add(
          initialBike: bike,
          initialSetupId: setup.id,
        ),
      ),
    );
    if (newRatingEntry == null) return;

    await appRepository.addRatingEntry(newRatingEntry);
  }
}
