import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/attachment.dart';
import '../repositories/app_repository.dart';
import '../services/attachment_storage_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';

class AttachmentActions {
  /// Attachments of [original] that [edited] no longer contains, matched by id.
  static List<Attachment> removedAttachments(Iterable<Attachment> original, Iterable<Attachment> edited) {
    final editedIds = edited.map((a) => a.id).toSet();
    return original.where((a) => !editedIds.contains(a.id)).toList();
  }

  /// Copies each file under a new id so a duplicate never shares a file with its source.
  static Future<List<Attachment>> copyAttachmentFiles(Iterable<Attachment> attachments) async {
    final service = AttachmentStorageService();
    return [for (final attachment in attachments) await service.copyExisting(attachment)];
  }

  static Future<void> deleteAttachmentFiles(Iterable<Attachment> attachments) =>
      AttachmentStorageService().deleteFiles(attachments.map((a) => a.filename));

  /// Deletes the files of [attachments] that did not make it into [saved];
  /// a discarded form (`saved == null`) keeps none of them.
  static Future<void> deleteUnsaved(Iterable<Attachment> attachments, {required Iterable<Attachment>? saved}) =>
      deleteAttachmentFiles(removedAttachments(attachments, saved ?? const []));

  static Future<bool> deleteAttachments(BuildContext context, {required Set<String> filenames}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: filenames.length == 1 ? 'Delete attachment?' : 'Delete ${filenames.length} attachments?',
      content:
          'The attachments are permanently deleted and removed from their setups, bikes and components. '
          'This action cannot be undone.',
      trueText: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return false;
    unawaited(HapticFeedback.heavyImpact());

    await removeAttachmentReferences(appRepository, filenames: filenames);
    await AttachmentStorageService().deleteFiles(filenames);

    if (!context.mounted) return true;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        filenames.length == 1 ? 'Attachment deleted.' : '${filenames.length} attachments deleted.',
      ),
    );
    return true;
  }

  /// Strips [filenames] from every setup, bike and component that references them.
  static Future<void> removeAttachmentReferences(AppRepository appRepository, {required Set<String> filenames}) async {
    bool references(List<Attachment> attachments) => attachments.any((a) => filenames.contains(a.filename));
    List<Attachment> without(List<Attachment> attachments) =>
        attachments.where((a) => !filenames.contains(a.filename)).toList();

    await appRepository.editSetups(
      appRepository.setups.values
          .where((setup) => references(setup.attachments))
          .map((setup) => setup.copyWith(attachments: without(setup.attachments)))
          .toList(),
    );
    final bikes = appRepository.bikes.values.where((bike) => references(bike.attachments)).toList();
    for (final bike in bikes) {
      await appRepository.editBike(bike.copyWith(attachments: without(bike.attachments)));
    }
    await appRepository.editComponents(
      appRepository.components.values
          .where((component) => references(component.attachments))
          .map((component) => component.copyWith(attachments: without(component.attachments)))
          .toList(),
    );
  }
}
