import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rating_entry.dart';
import '../models/setup.dart';
import '../pages/rating_entry_page.dart';
import '../pages/setup_page.dart';
import '../repositories/app_repository.dart';
import '../services/image_storage_service.dart';
import '../services/share_service.dart';
import '../widgets/app_snackbar.dart';
import 'bike_actions.dart';
import 'component_actions.dart';
import 'to_text.dart';

class SetupActions {
  static Future<void> addSetup(
    BuildContext context, {
    DateTime? initialDateTimeLocal,
  }) async {
    final appRepository = context.read<AppRepository>();

    if (appRepository.bikes.values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          'A bike is required to create a setup',
          action: AppSnackBarAction(
            label: 'ADD',
            onPressed: () => BikeActions.addBike(context),
          ),
        ),
      );
      return;
    }
    if (appRepository.components.values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          'A component is required to create a setup',
          action: AppSnackBarAction(
            label: 'ADD',
            onPressed: () => ComponentActions.addComponent(context),
          ),
        ),
      );
      return;
    }

    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPage.add(
          initialDateTimeUtc: initialDateTimeLocal?.toUtc(),
          initialDateTimeLocal: initialDateTimeLocal,
        ),
      ),
    );
    if (newSetup == null) return;

    await appRepository.addSetup(newSetup);
  }

  static Future<void> editSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final originalImages = List<String>.from(setup.images);

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.edit(setup: setup)),
    );
    if (editedSetup == null) return;

    await appRepository.editSetup(editedSetup);

    // Delete images that the user removed during editing.
    final removedImages = originalImages.where((f) => !editedSetup.images.contains(f));
    await ImageStorageService().deleteImages(removedImages);
  }

  static Future<Setup?> duplicateSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final deepCopied = setup.deepCopy();

    // Copy each photo file so the duplicate owns its own files.
    final service = ImageStorageService();
    final copiedImages = <String>[];
    for (final filename in deepCopied.images) {
      copiedImages.add(await service.copyExisting(filename));
    }
    final setupWithCopiedImages = deepCopied.copyWith(images: copiedImages);

    if (!context.mounted) {
      await service.deleteImages(copiedImages);
      return null;
    }

    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.duplicate(setup: setupWithCopiedImages)),
    );
    if (newSetup == null) {
      await service.deleteImages(copiedImages);
      return null;
    }

    await appRepository.addSetup(newSetup);
    return newSetup;
  }

  static Future<void> removeSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.removeSetups([setup]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Setup '${setup.displayName}' moved to trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.restoreSetups([setup]),
        ),
      ),
    );
  }

  static Future<void> restoreSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreSetups([setup]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Setup '${setup.displayName}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeSetups([setup]),
        ),
      ),
    );
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
