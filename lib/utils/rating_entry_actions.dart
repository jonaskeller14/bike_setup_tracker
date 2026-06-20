import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rating_entry.dart';
import '../pages/rating_entry_page.dart';
import '../repositories/app_repository.dart';

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

  static Future<void> removeRatingEntry(BuildContext context, {required RatingEntry ratingEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.removeRatingEntries([ratingEntry]);

    messenger.showSnackBar(SnackBar(
      content: Text("Rating '${ratingEntry.displayName}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.restoreRatingEntries([ratingEntry]);
        },
      ),
    ));
  }

  static Future<void> restoreRatingEntry(BuildContext context, {required RatingEntry ratingEntry}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreRatingEntries([ratingEntry]);

    messenger.showSnackBar(SnackBar(
      content: Text("Rating '${ratingEntry.displayName}' restored."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.removeRatingEntries([ratingEntry]);
        },
      ),
    ));
  }
}
