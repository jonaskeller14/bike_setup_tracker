import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/rating/rating_entry.dart';
import '../models/setup.dart';
import '../pages/forms/rating_entry_page.dart';
import '../pages/forms/setup_page.dart';
import '../repositories/app_repository.dart';
import '../services/share_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/set_tags_bulk.dart';
import 'attachment_actions.dart';
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

    await appRepository.addSetups([newSetup]);
  }

  static Future<void> editSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.edit(setup: setup)),
    );
    if (editedSetup == null) return;

    await appRepository.editSetups([editedSetup]);
    await AttachmentActions.deleteUnsaved(setup.attachments, saved: editedSetup.attachments);
  }

  static Future<Setup?> duplicateSetup(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final deepCopied = setup.deepCopy();
    final copiedAttachments = await AttachmentActions.copyAttachmentFiles(deepCopied.attachments);

    if (!context.mounted) {
      await AttachmentActions.deleteAttachmentFiles(copiedAttachments);
      return null;
    }

    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPage.duplicate(setup: deepCopied.copyWith(attachments: copiedAttachments)),
      ),
    );
    if (newSetup != null) await appRepository.addSetups([newSetup]);
    await AttachmentActions.deleteUnsaved(copiedAttachments, saved: newSetup?.attachments);
    return newSetup;
  }

  static Future<void> toggleBookmark(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();

    unawaited(HapticFeedback.selectionClick());
    await appRepository.editSetups([setup.copyWith(isBookmarked: !setup.isBookmarked)]);
  }

  static Future<void> toggleBookmarks(BuildContext context, {required Iterable<String> setupIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final setups = setupIds.map((id) => appRepository.setups[id]).whereType<Setup>().toList();
    if (setups.isEmpty) return;

    final bookmark = !setups.every((setup) => setup.isBookmarked);
    final originals = setups.where((setup) => setup.isBookmarked != bookmark).toList();

    unawaited(HapticFeedback.selectionClick());
    await appRepository.editSetups(originals.map((setup) => setup.copyWith(isBookmarked: bookmark)));

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        Intl.plural(
          originals.length,
          one: bookmark ? '1 Setup bookmarked.' : 'Bookmark removed from 1 Setup.',
          other: bookmark
              ? '${originals.length} Setups bookmarked.'
              : 'Bookmark removed from ${originals.length} Setups.',
        ),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.editSetups(originals),
        ),
      ),
    );
  }

  static Future<bool> setSetupsTags(BuildContext context, {required Iterable<String> setupIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final setups = setupIds.map((id) => appRepository.setups[id]).whereType<Setup>().toList();
    if (setups.isEmpty) return false;

    final changes = await showSetTagsBulkSheet(
      context: context,
      itemTags: setups.map((setup) => setup.tags).toList(),
      availableTags: appRepository.setupTags,
      title: 'Set Tags',
      subtitle: 'Use tags to group and organize your setups. For example, to categorize by specific '
          'test sessions, tracks, or terrains.',
      applyLabel: Intl.plural(
        setups.length,
        one: 'Apply to 1 Setup',
        other: 'Apply to ${setups.length} Setups',
      ),
    );
    if (changes == null) return false;

    final originals = <Setup>[];
    final updated = <Setup>[];
    for (final setup in setups) {
      final newTags = changes.apply(setup.tags);
      if (setEquals(newTags, setup.tags)) continue;
      originals.add(setup);
      updated.add(setup.copyWith(tags: newTags));
    }
    if (updated.isEmpty) return true;

    await appRepository.editSetups(updated);

    if (!context.mounted) return true;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        Intl.plural(
          updated.length,
          one: 'Tags updated for 1 Setup.',
          other: 'Tags updated for ${updated.length} Setups.',
        ),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.editSetups(originals),
        ),
      ),
    );
    return true;
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

    await appRepository.addRatingEntries([newRatingEntry]);
  }
}
