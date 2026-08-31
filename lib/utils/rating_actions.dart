import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/rating.dart';
import '../pages/rating_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

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

    final result = await Navigator.push<EditResult<Rating>>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage.edit(rating: rating),
      ),
    );
    if (result == null) return;

    await appRepository.editRating(result.value, conversions: result.conversions);
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
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.removeRatings([rating]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Rating '${rating.name}' moved to trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreRatings([rating]);
          },
        ),
      ),
    );
  }

  static Future<void> restoreRating(BuildContext context, {required Rating rating}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreRatings([rating]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Rating '${rating.name}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.removeRatings([rating]);
          },
        ),
      ),
    );
  }

  static Future<void> onReorderRating(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderRating(
      oldIndex: oldIndex,
      newIndex: newIndex,
      filteredRatingsList: appRepository.filteredRatings.values.toList(),
    );
  }
}
