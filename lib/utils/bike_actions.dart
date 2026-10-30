import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../l10n/list_text.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/task/task_association.dart';
import '../models/task/task_rule.dart';
import '../pages/forms/bike_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/delete_task_rules.dart';
import '../widgets/sheets/set_bike_person.dart';
import 'attachment_actions.dart';

class BikeActions {
  static Future<void> addBike(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => BikePage.add()),
    );
    if (bike == null) return;

    await appRepository.addBikes([bike]);
  }

  static Future<void> editBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();

    final editedBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.edit(bike: bike),
      ),
    );
    if (editedBike == null) return;

    await appRepository.editBikes([editedBike]);
    await AttachmentActions.deleteUnsaved(bike.attachments, saved: editedBike.attachments);
  }

  static Future<void> duplicateBikeWithoutComponents(BuildContext context, {required Bike bike}) async {
    await _duplicateBike(context, bike: bike);
  }

  static Future<void> duplicateBikeWithComponents(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final bikeComponents = appRepository.components.values.where(
      (component) => appRepository.componentHierarchy.currentBike(component.id) == bike.id,
    ).toList();

    final newBike = await _duplicateBike(context, bike: bike);
    if (newBike == null) return;

    // The components never pass through a form, so their files are copied only once the bike is saved.
    final newComponents = <Component>[];
    for (final component in bikeComponents) {
      final copy = component.deepCopy().copyWithNewInstallation(newBike.id);
      newComponents.add(copy.copyWith(attachments: await AttachmentActions.copyAttachmentFiles(copy.attachments)));
    }
    await appRepository.addComponents(newComponents);
  }

  static Future<Bike?> _duplicateBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final deepCopied = bike.deepCopy();
    final copiedAttachments = await AttachmentActions.copyAttachmentFiles(deepCopied.attachments);

    if (!context.mounted) {
      await AttachmentActions.deleteAttachmentFiles(copiedAttachments);
      return null;
    }

    final newBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.duplicate(bike: deepCopied.copyWith(attachments: copiedAttachments)),
      ),
    );
    if (newBike != null) await appRepository.addBikes([newBike]);
    await AttachmentActions.deleteUnsaved(copiedAttachments, saved: newBike?.attachments);
    return newBike;
  }

  static Future<bool> setBikesPerson(BuildContext context, {required Iterable<String> bikeIds}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final bikes = bikeIds.map((id) => appRepository.bikes[id]).whereType<Bike>().toList();
    if (bikes.isEmpty) return false;

    final result = await showSetBikePersonSheet(
      context: context,
      bikePersons: bikes.map((bike) => bike.person).toList(),
      persons: appRepository.persons,
    );
    if (result == null) return false;
    final newPerson = result.person;

    final bikesToUpdate = bikes.where((bike) => bike.person != newPerson).toList();
    if (bikesToUpdate.isEmpty) return true;

    final updatedBikes = bikesToUpdate.map((bike) => bike.copyWith(person: newPerson)).toList();
    await appRepository.editBikes(updatedBikes);

    if (!context.mounted) return true;
    final personName = appRepository.persons[newPerson]?.name;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        personName == null
            ? l10n.bikeRiderRemoved(updatedBikes.length)
            : l10n.bikeRiderSet(updatedBikes.length, personName),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: l10n.undo,
          onPressed: () async => appRepository.editBikes(bikesToUpdate),
        ),
      ),
    );
    return true;
  }

  static Future<void> removeBike(BuildContext context, {required Bike bike}) =>
      removeBikes(context, bikes: [bike]);

  static Future<void> removeBikes(BuildContext context, {required Iterable<Bike> bikes}) async {
    final bikeList = bikes.toList();
    if (bikeList.isEmpty) return;

    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final bikeIds = bikeList.map((bike) => bike.id).toSet();
    final obsoleteComponents = appRepository.components.values.where(
      (component) => bikeIds.contains(appRepository.componentHierarchy.currentBike(component.id)),
    ).toList();
    final obsoleteSetups = appRepository.setups.values.where((s) => bikeIds.contains(s.bike)).toList();
    final obsoleteComponentIds = obsoleteComponents.map((component) => component.id).toSet();
    final relatedTaskRules = appRepository.taskRules.values
        .where((rule) => switch (rule.association) {
          BikeTaskAssociation(:final id) => bikeIds.contains(id),
          ComponentTaskAssociation(:final id) => obsoleteComponentIds.contains(id),
          GeneralTaskAssociation() => false,
        })
        .toList();
    final selectedTaskRules = relatedTaskRules.isEmpty
        ? const <TaskRule>[]
        : await showDeleteTaskRulesSheet(context, taskRules: relatedTaskRules);
    if (selectedTaskRules == null) return;
    final selectedRuleIds = selectedTaskRules.map((rule) => rule.id).toSet();
    final obsoleteTaskEntries = appRepository.taskEntries.values
        .where((entry) => selectedRuleIds.contains(entry.taskRule))
        .toList();

    await appRepository.removeBikes(bikeList);
    await appRepository.removeComponents(obsoleteComponents);
    await appRepository.removeSetups(obsoleteSetups);
    await appRepository.removeTaskRules(selectedTaskRules);
    await appRepository.removeTaskEntries(obsoleteTaskEntries);

    final deletedItems = [
      if (obsoleteComponents.isNotEmpty) l10n.bikeTrashedComponents(obsoleteComponents.length),
      if (obsoleteSetups.isNotEmpty) l10n.bikeTrashedSetups(obsoleteSetups.length),
      if (selectedTaskRules.isNotEmpty) l10n.bikeTrashedTasks(selectedTaskRules.length),
    ];
    String message = l10n.bikeMovedToTrash(bikeList.length, bikeList.first.name);
    if (deletedItems.isNotEmpty) {
      message += '\n${l10n.bikeAlsoTrashed(joinItems(l10n, deletedItems))}';
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        message,
        duration: const Duration(seconds: 10),
        action: AppSnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            await appRepository.restoreBikes(bikeList);
            await appRepository.restoreComponents(obsoleteComponents);
            await appRepository.restoreSetups(obsoleteSetups);
            await appRepository.restoreTaskRules(selectedTaskRules);
            await appRepository.restoreTaskEntries(obsoleteTaskEntries);
          },
        ),
      ),
    );
  }

  static Future<void> restoreBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    await appRepository.restoreBikes([bike]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        l10n.bikeRestoredFromTrash(bike.name),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            await appRepository.removeBikes([bike]);
          },
        ),
      ),
    );
  }

  static Future<void> onReorderBikes(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderBike(
      oldIndex: oldIndex,
      newIndex: newIndex,
      filteredBikesList: appRepository.bikes.values.toList(),
    );
  }
}
