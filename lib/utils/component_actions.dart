import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/task/task_association.dart';
import '../models/task/task_rule.dart';
import '../pages/adjustment/boolean_adjustment_page.dart';
import '../pages/adjustment/categorical_adjustment_page.dart';
import '../pages/adjustment/duration_adjustment_page.dart';
import '../pages/adjustment/numerical_adjustment_page.dart';
import '../pages/adjustment/sag_adjustment_page.dart';
import '../pages/adjustment/step_adjustment_page.dart';
import '../pages/adjustment/text_adjustment_page.dart';
import '../pages/component_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/component_descendant_warning.dart';
import '../widgets/sheets/component_add_adjustment.dart';
import '../widgets/sheets/copy_task_rules.dart';
import '../widgets/sheets/delete_task_rules.dart';
import '../widgets/sheets/replace_component.dart';
import 'bike_actions.dart';
import 'installation_timeline_validation.dart';

class ComponentActions {
  static Future<void> addComponent(BuildContext context, {Object? initialBike = const _Sentinel(), List<Installation>? initialInstallations}) async {
    final appRepository = context.read<AppRepository>();

    if (initialInstallations == null && initialBike is _Sentinel && appRepository.filteredBikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          'Add a bike first',
          action: AppSnackBarAction(
            label: 'ADD',
            onPressed: () => BikeActions.addBike(context),
          ),
        ),
      );
      return;
    }
    final installations = initialInstallations ??
        (initialBike is _Sentinel ? null : [Installation.sinceBeginning(parent: initialBike as String?)]);

    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => ComponentPage.add(initialInstallations: installations)),
    );

    if (component == null) return;
    await appRepository.addComponents([component]);
  }

  static Future<void> editComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();

    final result = await Navigator.push<EditResult<Component>>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.edit(component: component),
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    if (!component.isArchived && result.value.isArchived) {
      final confirmed = await confirmComponentDescendantImpact(
        context,
        component: component,
        descendants: appRepository.affectedDescendants(component.id),
        action: 'Archive',
      );
      if (!confirmed || !context.mounted) return;
    }
    await appRepository.editComponent(result.value, conversions: result.conversions);
  }

  static Future<void> duplicateComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();

    final newComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.duplicate(component: component.deepCopy()),
      ),
    );
    if (newComponent == null) return;

    await appRepository.addComponents([newComponent]);

    if (!context.mounted) return;
    await _copyTaskRulesTo(context, source: component, target: newComponent);
  }

  static Future<void> _copyTaskRulesTo(
    BuildContext context, {
    required Component source,
    required Component target,
  }) async {
    if (!context.read<AppSettings>().enableTask) return;

    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final rules = appRepository.taskRules.values.where((rule) => rule.association.componentId == source.id).toList();
    if (rules.isEmpty) return;

    final selected = await showCopyTaskRulesSheet(context, taskRules: rules, componentName: target.name);
    if (selected == null || selected.isEmpty) return;

    // deepCopy() keeps the original association, so it has to be re-pointed.
    final copies = selected.map((rule) => rule.deepCopy().copyWith(association: ComponentTaskAssociation(target.id))).toList();
    await appRepository.addTaskRules(copies);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        "Copied ${copies.length} task${copies.length == 1 ? '' : 's'} to '${target.name}'.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeTaskRules(copies),
        ),
      ),
    );
  }

  static Future<void> replaceComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showReplaceComponentSheet(context, component: component);
    if (result == null) return;

    final currentInstallation = appRepository.componentHierarchy.currentInstallation(component.id);
    if (currentInstallation == null ||
        (currentInstallation is! BikeInstallation && currentInstallation is! ComponentInstallation)) {
      return;
    }

    final removedAt = stampInstallationNow(component.installations, now: result.replacementDate);
    final uninstallation = Installation(
      parent: null,
      dateTimeUTC: removedAt.utc,
      dateTimeLocal: removedAt.local,
    );

    switch (result) {
      case ReplaceComponentExistingResult(:final existingComponent, :final replacementDate):
        // Swap in an already uninstalled component: install it on the same parent
        // (bike or component) and retire the current one, both at the replacement date.
        final installedAt = stampInstallationNow(existingComponent.installations, now: replacementDate);
        await appRepository.editComponents([
          existingComponent.copyWith(
            installations: [
              ...existingComponent.installations,
              currentInstallation.samePlacementAt(
                dateTimeUTC: installedAt.utc,
                dateTimeLocal: installedAt.local,
              ),
            ],
          ),
          component.copyWith(
            installations: [
              ...component.installations,
              uninstallation,
            ],
          ),
        ]);

        if (!context.mounted) return;
        messenger.showSnackBar(
          AppSnackBar.success(
            context,
            "Replaced '${component.name}' with '${existingComponent.name}'.",
            duration: const Duration(seconds: 5),
          ),
        );

      case ReplaceComponentNewResult(:final replacementDate):
        // Create a brand-new replacement component, pre-filled from the current one.
        if (!context.mounted) return;
        final newComponent = await Navigator.push<Component>(
          context,
          MaterialPageRoute(
            builder: (context) => ComponentPage.replace(
              component: component.deepCopy(),
              replacementDate: replacementDate,
            ),
          ),
        );
        if (newComponent == null) return;

        await appRepository.addComponents([newComponent]);
        await appRepository.editComponent(
          component.copyWith(
            installations: [
              ...component.installations,
              uninstallation,
            ],
          ),
        );

        if (!context.mounted) return;
        await _copyTaskRulesTo(context, source: component, target: newComponent);
    }
  }

  static Future<void> removeComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await confirmComponentDescendantImpact(
      context,
      component: component,
      descendants: appRepository.affectedDescendants(component.id),
      action: 'Move to trash',
    );
    if (!confirmed || !context.mounted) return;

    final relatedTaskRules = appRepository.taskRules.values.where((rule) => rule.association.componentId == component.id).toList();
    final selectedTaskRules = relatedTaskRules.isEmpty
        ? const <TaskRule>[]
        : await showDeleteTaskRulesSheet(context, taskRules: relatedTaskRules) ?? const <TaskRule>[];
    final selectedRuleIds = selectedTaskRules.map((rule) => rule.id).toSet();
    final obsoleteTaskEntries = appRepository.taskEntries.values
        .where((entry) => selectedRuleIds.contains(entry.taskRule))
        .toList();

    await appRepository.removeComponents([component]);
    await appRepository.removeTaskRules(selectedTaskRules);
    await appRepository.removeTaskEntries(obsoleteTaskEntries);

    final taskSummary = selectedTaskRules.isEmpty
        ? ''
        : '\nAlso moved to trash: ${Intl.plural(
            selectedTaskRules.length,
            one: '1 task and its entries',
            other: '${selectedTaskRules.length} tasks and their entries',
          )}.';
    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Component '${component.name}' moved to trash.$taskSummary",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await appRepository.restoreComponents([component]);
            await appRepository.restoreTaskRules(selectedTaskRules);
            await appRepository.restoreTaskEntries(obsoleteTaskEntries);
          },
        ),
      ),
    );
  }

  static Future<void> restoreComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    await appRepository.restoreComponents([component]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Component '${component.name}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeComponents([component]),
        ),
      ),
    );
  }

  static Future<void> onReorderComponents(BuildContext context, {required int oldIndex, required int newIndex}) async {
    final appRepository = context.read<AppRepository>();
    await appRepository.reorderComponent(
      oldIndex: oldIndex,
      newIndex: newIndex,
      filteredComponentsList: appRepository.filteredComponents.values.toList(),
    );
  }

  static Future<void> addAdjustmentForComponent(BuildContext context, {required Component component}) async {
    showComponentAddAdjustmentBottomSheet(
      context: context,
      componentType: component.componentType,
      existingAdjustments: component.adjustments,
      enableDurationAdjustment: false,
      addAdjustmentFromPreset: (Adjustment adjustment) async {
        final appRepository = context.read<AppRepository>();
        final newAdjustment = await Navigator.push<Adjustment>(
          context,
          MaterialPageRoute(
            builder: (context) => switch (adjustment.deepCopy()) {
              final BooleanAdjustment a => BooleanAdjustmentPage.template(adjustment: a),
              final CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a),
              final StepAdjustment a => StepAdjustmentPage.template(adjustment: a),
              final SagAdjustment a => SagAdjustmentPage.template(adjustment: a, componentType: component.componentType),
              final NumericalAdjustment a => NumericalAdjustmentPage.template(adjustment: a),
              final TextAdjustment a => TextAdjustmentPage.template(adjustment: a),
              final DurationAdjustment a => DurationAdjustmentPage.template(adjustment: a),
            },
          ),
        );
        if (newAdjustment == null) return;
        await appRepository.editComponent(component.copyWith(adjustments: [...component.adjustments, newAdjustment]));
      },
      addAdjustment: <T extends Adjustment>() async {
        final appRepository = context.read<AppRepository>();
        final newAdjustment = await Navigator.push<T>(
          context,
          MaterialPageRoute(
            builder: (context) => switch (T) {
              const (BooleanAdjustment) => BooleanAdjustmentPage.add(),
              const (CategoricalAdjustment) => CategoricalAdjustmentPage.add(),
              const (StepAdjustment) => StepAdjustmentPage.add(),
              const (NumericalAdjustment) => NumericalAdjustmentPage.add(),
              const (TextAdjustment) => TextAdjustmentPage.add(),
              const (DurationAdjustment) => DurationAdjustmentPage.add(),
              Type() => throw UnimplementedError(),
            },
          ),
        );
        if (newAdjustment == null) return;
        await appRepository.editComponent(component.copyWith(adjustments: [...component.adjustments, newAdjustment]));
      },
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
