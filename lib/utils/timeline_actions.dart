import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/rating/rating_entry.dart';
import '../models/setup.dart';
import '../models/task/task_entry.dart';
import '../models/timeline_selection.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class TimelineActions {
  static Future<void> removeSelection(
    BuildContext context, {
    required Set<TimelineSelectionId> selection,
  }) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final setups = selection
        .idsOf(TimelineSelectionKind.setup)
        .map((id) => appRepository.setups[id])
        .whereType<Setup>()
        .toList();
    final taskEntries = selection
        .idsOf(TimelineSelectionKind.taskEntry)
        .map((id) => appRepository.taskEntries[id])
        .whereType<TaskEntry>()
        .toList();
    final ratingEntries = selection
        .idsOf(TimelineSelectionKind.ratingEntry)
        .map((id) => appRepository.ratingEntries[id])
        .whereType<RatingEntry>()
        .toList();

    final total = setups.length + taskEntries.length + ratingEntries.length;
    if (total == 0) return;

    await appRepository.removeSetups(setups);
    await appRepository.removeTaskEntries(taskEntries);
    await appRepository.removeRatingEntries(ratingEntries);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        Intl.plural(
          total,
          one: '1 entry moved to trash.',
          other: '$total entries moved to trash.',
        ),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreSetups(setups);
            await appRepository.restoreTaskEntries(taskEntries);
            await appRepository.restoreRatingEntries(ratingEntries);
          },
        ),
      ),
    );
  }
}
