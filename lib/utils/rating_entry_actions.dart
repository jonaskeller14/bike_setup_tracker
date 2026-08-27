import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rating_entry.dart';
import '../pages/rating_entry_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class RatingEntryActions {
  static Future<void> editRatingEntry(BuildContext context, {required RatingEntry ratingEntry}) async {
    final appRepository = context.read<AppRepository>();

    final edited = await Navigator.push<RatingEntry>(
      context,
      MaterialPageRoute(builder: (context) => RatingEntryPage.edit(ratingEntry: ratingEntry)),
    );
    if (edited == null) return;

    await appRepository.editRatingEntry(edited);
  }

  static Future<void> duplicateRatingEntry(BuildContext context, {required RatingEntry ratingEntry}) async {
    final appRepository = context.read<AppRepository>();

    final newRatingEntry = await Navigator.push<RatingEntry>(
      context,
      MaterialPageRoute(builder: (context) => RatingEntryPage.duplicate(ratingEntry: ratingEntry.deepCopy())),
    );
    if (newRatingEntry == null) return;

    await appRepository.addRatingEntry(newRatingEntry);
  }

  static Future<void> removeRatingEntry(BuildContext context, {required RatingEntry ratingEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.removeRatingEntries([ratingEntry]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Rating '${ratingEntry.displayName}' moved to trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreRatingEntries([ratingEntry]);
          },
        ),
      ),
    );
  }

  static Future<void> restoreRatingEntry(BuildContext context, {required RatingEntry ratingEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreRatingEntries([ratingEntry]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Rating '${ratingEntry.displayName}' restored.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.removeRatingEntries([ratingEntry]);
          },
        ),
      ),
    );
  }
}
