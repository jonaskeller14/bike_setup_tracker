import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/rating_association.dart';
import '../models/task/task_rule.dart';
import '../pages/bike_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/sheets/delete_task_rules.dart';

class BikeActions {
  static Future<void> addBike(BuildContext context) async {
    final appRepository = context.read<AppRepository>();

    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => BikePage.add()),
    );
    if (bike == null) return;

    await appRepository.addBike(bike);
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

    await appRepository.editBike(editedBike);
  }

  static Future<void> duplicateBikeWithoutComponents(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();

    final newBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.duplicate(bike: bike.deepCopy()),
      ),
    );
    if (newBike == null) return;

    await appRepository.addBike(newBike);
  }

  static Future<void> duplicateBikeWithComponents(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final bikeComponents = appRepository.components.values.where((c) => c.bike == bike.id).toList();

    final newBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage.duplicate(bike: bike.deepCopy()),
      ),
    );
    if (newBike == null) return;

    await appRepository.addBike(newBike);
    await Future.wait(
      bikeComponents.map((c) => appRepository.addComponent(c.deepCopy().copyWithNewInstallation(newBike.id))),
    );
  }

  static Future<void> removeBike(BuildContext context, {required Bike bike}) async {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();
    final messenger = ScaffoldMessenger.of(context);

    final obsoleteComponents = appRepository.components.values.where((c) => c.bike == bike.id).toList();
    final obsoleteSetups = appRepository.setups.values.where((s) => s.bike == bike.id).toList();
    final obsoleteRatings = appRepository.ratings.values
        .where((r) => r.filterType == FilterType.bike && r.filter == bike.id)
        .toList();
    final obsoleteComponentIds = obsoleteComponents.map((component) => component.id).toSet();
    final relatedTaskRules = appRepository.taskRules.values
        .where((rule) => rule.bikeId == bike.id || obsoleteComponentIds.contains(rule.componentId))
        .toList();
    final selectedTaskRules = relatedTaskRules.isEmpty
        ? const <TaskRule>[]
        : await showDeleteTaskRulesSheet(context, taskRules: relatedTaskRules) ?? const <TaskRule>[];
    final selectedRuleIds = selectedTaskRules.map((rule) => rule.id).toSet();
    final obsoleteTaskEntries = appRepository.taskEntries.values
        .where((entry) => selectedRuleIds.contains(entry.taskRule))
        .toList();

    await appRepository.removeBike(bike);
    await appRepository.removeComponents(obsoleteComponents);
    await appRepository.removeSetups(obsoleteSetups);
    await appRepository.removeRatings(obsoleteRatings);
    await appRepository.removeTaskRules(selectedTaskRules);
    await appRepository.removeTaskEntries(obsoleteTaskEntries);

    final deletedItems = [
      if (obsoleteComponents.isNotEmpty)
        Intl.plural(obsoleteComponents.length, one: '1 component', other: '${obsoleteComponents.length} components'),
      if (obsoleteSetups.isNotEmpty)
        Intl.plural(obsoleteSetups.length, one: '1 setup', other: '${obsoleteSetups.length} setups'),
      if (appSettings.enableRating && obsoleteRatings.isNotEmpty)
        Intl.plural(obsoleteRatings.length, one: '1 rating', other: '${obsoleteRatings.length} ratings'),
      if (selectedTaskRules.isNotEmpty)
        Intl.plural(
          selectedTaskRules.length,
          one: '1 task and its entries',
          other: '${selectedTaskRules.length} tasks and their entries',
        ),
    ];
    String message = "Bike '${bike.name}' moved to trash.";
    if (deletedItems.isNotEmpty) {
      final summary = switch (deletedItems.length) {
        1 => deletedItems.single,
        2 => '${deletedItems.first} and ${deletedItems.last}',
        _ => '${deletedItems.sublist(0, deletedItems.length - 1).join(', ')}, and ${deletedItems.last}',
      };
      message += '\nAlso moved to trash: $summary.';
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        persist: false,
        showCloseIcon: true,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreBike(bike);
            await appRepository.restoreComponents(obsoleteComponents);
            await appRepository.restoreSetups(obsoleteSetups);
            await appRepository.restoreRatings(obsoleteRatings);
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

    await appRepository.restoreBike(bike);

    messenger.showSnackBar(
      SnackBar(
        content: Text("Bike '${bike.name}' restored from trash."),
        duration: const Duration(seconds: 5),
        persist: false,
        showCloseIcon: true,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.removeBike(bike);
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
