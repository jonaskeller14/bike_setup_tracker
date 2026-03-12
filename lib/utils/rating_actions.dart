import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rating.dart';
import '../pages/rating_page.dart';
import '../repositories/app_repository.dart';

class RatingActions {
  static Future<void> addRating(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final newRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage.add(),
      ),
    );
    if (newRating == null) return;

    await appRepository.addRating(newRating);
  }

  static Future<void> editRating(BuildContext context, {required Rating rating}) async {
    final appRepository = context.read<AppRepository>();

    final editedRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage.edit(rating: rating),
      ),
    );
    if (editedRating == null) return;

    await appRepository.editRating(editedRating);
  }

  static Future<void> duplicateRating(BuildContext context, {required Rating rating}) async {
    final appRepository = context.read<AppRepository>();

    final newRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage.duplicate(rating: rating.deepCopy()),
      ),
    );
    if (newRating == null) return;

    await appRepository.addRating(newRating);
  }

  static Future<void> removeRating(BuildContext context, {required Rating rating}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.removeRatings([rating]);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Rating '${rating.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          await appRepository.restoreRatings([rating]);
        },
      ),
    ));
  }

  static Future<void> onReorderRating(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    appRepository.reorderRating(oldIndex: oldIndex, newIndex: newIndex, filteredRatingsList: appRepository.filteredRatings.values.toList());
  }
}
