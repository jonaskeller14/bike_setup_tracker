import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../models/component/subcomponent_detach.dart';
import '../models/task/task_association.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_template.dart';
import '../pages/adjustment/boolean_adjustment_page.dart';
import '../pages/adjustment/categorical_adjustment_page.dart';
import '../pages/adjustment/duration_adjustment_page.dart';
import '../pages/adjustment/numerical_adjustment_page.dart';
import '../pages/adjustment/sag_adjustment_page.dart';
import '../pages/adjustment/step_adjustment_page.dart';
import '../pages/adjustment/text_adjustment_page.dart';
import '../pages/forms/component_page.dart';
import '../repositories/app_repository.dart';
import '../repositories/component_catalog_repository.dart';
import '../services/subscription_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/archive_component.dart';
import '../widgets/sheets/component_add_adjustment.dart';
import '../widgets/sheets/copy_task_rules.dart';
import '../widgets/sheets/delete_task_rules.dart';
import '../widgets/sheets/remove_component.dart';
import '../widgets/sheets/replace_component.dart';
import 'attachment_actions.dart';
import 'bike_actions.dart';
import 'installation_timeline_validation.dart';
import 'task_preset_resolver.dart';

class ComponentActions {
  static Future<void> addComponent(BuildContext context, {Object? initialBike = const _Sentinel(), List<Installation>? initialInstallations}) async {
    final appRepository = context.read<AppRepository>();

    if (initialInstallations == null && initialBike is _Sentinel && appRepository.view.bikes.isEmpty) {
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
    // Callers are often empty-state hints that disappear once the component
    // exists, so the task prompt needs a context that outlives them.
    final navigatorContext = Navigator.of(context).context;

    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => ComponentPage.add(initialInstallations: installations)),
    );

    if (component == null) return;
    await appRepository.addComponents([component]);

    if (!navigatorContext.mounted) return;
    await offerTaskRulesFor(navigatorContext, target: component);
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
    var subcomponentEdits = const <Component>[];
    if (!component.isArchived && result.value.isArchived) {
      final edits = await archiveSubcomponentEdits(
        context,
        component: component,
        atUTC: result.value.latestInstallation!.dateTimeUTC,
      );
      if (edits == null || !context.mounted) {
        // The edit is dropped, so files added in the form would be left unlinked.
        await AttachmentActions.deleteUnsaved(result.value.attachments, saved: component.attachments);
        return;
      }
      subcomponentEdits = edits;
    }
    await appRepository.editComponents([result.value, ...subcomponentEdits], conversions: result.conversions);
    await AttachmentActions.deleteUnsaved(component.attachments, saved: result.value.attachments);
  }

  /// Asks what happens to the subcomponents mounted on [component] when it is
  /// archived at [atUTC]. Returns the subcomponent edits to save alongside the
  /// archival (empty when they follow it), or null when cancelled.
  static Future<List<Component>?> archiveSubcomponentEdits(
    BuildContext context, {
    required Component component,
    required DateTime atUTC,
  }) async {
    final appRepository = context.read<AppRepository>();
    final hierarchy = appRepository.componentHierarchy;
    if (hierarchy.descendantsOf(component.id, atUTC: atUTC).isEmpty) return const [];

    final choice = await showArchiveComponentSheet(context, component: component, atUTC: atUTC);
    if (choice == null) return null;
    if (choice.withSubcomponents) return const [];
    return detachSubcomponents(
      _componentsOf(appRepository, hierarchy.childrenOf(component.id, atUTC: atUTC)),
      mode: choice.detach,
      bikeId: hierarchy.bikeAt(component.id, atUTC),
      at: atUTC.toLocal(),
    );
  }

  /// Archives [component] as its only installation entry, for components
  /// without an installation timeline.
  static Future<void> archiveWithoutTimeline(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final archival = Archival(
      dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final subcomponentEdits = await archiveSubcomponentEdits(
      context,
      component: component,
      atUTC: archival.dateTimeUTC,
    );
    if (subcomponentEdits == null) return;
    await appRepository.editComponents([component.copyWith(installations: [archival]), ...subcomponentEdits]);
  }

  static List<Component> _componentsOf(AppRepository appRepository, Iterable<String> ids) =>
      ids.map((id) => appRepository.components[id]).whereType<Component>().toList();

  /// Edited copies of [directChildren] taken off their parent at [at].
  ///
  /// Only direct children get an event; deeper descendants stay on their own
  /// parent and follow it. A child on a component always has a timeline, so the
  /// event is appended rather than replacing its history.
  @visibleForTesting
  static List<Component> detachSubcomponents(
    Iterable<Component> directChildren, {
    required SubcomponentDetach mode,
    required String? bikeId,
    required DateTime at,
  }) {
    if (mode == SubcomponentDetach.keepLinked) return const [];
    final target = mode == SubcomponentDetach.installOnBike ? bikeId : null;

    return [
      for (final child in directChildren)
        child.copyWith(installations: [...child.installations, _detachEvent(child, target, at)]),
    ];
  }

  static Installation _detachEvent(Component child, String? bikeId, DateTime at) {
    final stamp = stampInstallationNow(child.installations, now: at);
    return Installation(parent: bikeId, dateTimeUTC: stamp.utc, dateTimeLocal: stamp.local);
  }

  static Future<void> duplicateComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final deepCopied = await _deepCopyWithFiles(component);

    if (!context.mounted) {
      await AttachmentActions.deleteAttachmentFiles(deepCopied.attachments);
      return;
    }

    final newComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage.duplicate(component: deepCopied),
      ),
    );
    if (newComponent == null) {
      await AttachmentActions.deleteAttachmentFiles(deepCopied.attachments);
      return;
    }

    await appRepository.addComponents([newComponent]);
    await AttachmentActions.deleteUnsaved(deepCopied.attachments, saved: newComponent.attachments);

    if (!context.mounted) return;
    await offerTaskRulesFor(context, source: component, target: newComponent);
  }

  static Future<Component> _deepCopyWithFiles(Component component) async {
    final deepCopied = component.deepCopy();
    return deepCopied.copyWith(attachments: await AttachmentActions.copyAttachmentFiles(deepCopied.attachments));
  }

  /// Offers copies of [source]'s task rules and, with task presets on, the
  /// recommended tasks for [target] in one sheet. Opens nothing when there is
  /// nothing to offer.
  @visibleForTesting
  static Future<void> offerTaskRulesFor(
    BuildContext context, {
    Component? source,
    required Component target,
  }) async {
    final appSettings = context.read<AppSettings>();
    if (!appSettings.enableTask) return;

    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final copyRules = source == null
        ? const <TaskRule>[]
        : appRepository.taskRules.values.where((rule) => rule.association.componentId == source.id).toList();
    final preset = target.preset;
    // Not deduplicated against copyRules: the sheet hides a suggestion only while its copy is selected.
    final suggestions = !appSettings.showTaskPresets
        ? const <TaskSuggestion>[]
        : taskSuggestionsFor(
            target,
            existingRules: appRepository.taskRules.values,
            hasStravaEntitlement: context.read<SubscriptionService>().hasStravaEntitlement,
            // ComponentPage has loaded the catalog of a component with a preset.
            overrides: preset == null
                ? const {}
                : context.read<ComponentCatalogRepository>().loadedTaskOverrides(preset),
          );
    if (copyRules.isEmpty && suggestions.isEmpty) return;

    final result = await showTaskRulesSheet(
      context,
      copyFrom: source?.name,
      copyRules: copyRules,
      suggestions: suggestions,
      componentName: target.name,
      componentTypeLabel: target.componentType.label,
    );
    if (result == null) return;
    unawaited(HapticFeedback.lightImpact());

    final created = [
      ...await taskRuleCopies(result.copied, componentId: target.id),
      for (final suggestion in result.suggested)
        suggestion.toTaskRule(target.id, distanceUnit: appSettings.distanceUnit, altitudeUnit: appSettings.altitudeUnit),
    ];
    await appRepository.addTaskRules(created);

    if (!context.mounted) return;
    final verb = result.suggested.isEmpty ? 'Copied' : 'Added';
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        "$verb ${created.length} task${created.length == 1 ? '' : 's'} to '${target.name}'.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeTaskRules(created),
        ),
      ),
    );
  }

  /// Copies of [rules] linked to [componentId], each with its own attachment files.
  @visibleForTesting
  static Future<List<TaskRule>> taskRuleCopies(Iterable<TaskRule> rules, {required String componentId}) async {
    return [
      for (final rule in rules)
        // deepCopy() keeps the original association, so it has to be re-pointed.
        rule.deepCopy().copyWith(
          association: ComponentTaskAssociation(componentId),
          attachments: await AttachmentActions.copyAttachmentFiles(rule.attachments),
        ),
    ];
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

    // Without an explicit move, subcomponents would stay on the retired parent.
    List<Component> subcomponentEdits(String replacementId) => [
      for (final child in result.movedSubcomponents)
        child.copyWith(installations: [
          ...child.installations,
          _stampedInstallation(child, result.replacementDate, parentComponentId: replacementId),
        ]),
      for (final child in result.uninstalledSubcomponents)
        child.copyWith(installations: [
          ...child.installations,
          _stampedInstallation(child, result.replacementDate),
        ]),
    ];

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
          ...subcomponentEdits(existingComponent.id),
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
        // Retiring the component can unmount the caller (e.g. its list card), so
        // the task-copy prompt needs a context that outlives this flow.
        final navigatorContext = Navigator.of(context).context;
        final deepCopied = await _deepCopyWithFiles(component);
        if (!context.mounted) {
          await AttachmentActions.deleteAttachmentFiles(deepCopied.attachments);
          return;
        }
        final newComponent = await Navigator.push<Component>(
          context,
          MaterialPageRoute(
            builder: (context) => ComponentPage.replace(
              component: deepCopied,
              replacementDate: replacementDate,
              replacedInstallation: currentInstallation,
              replacedComponentId: component.id,
            ),
          ),
        );
        if (newComponent == null) {
          await AttachmentActions.deleteAttachmentFiles(deepCopied.attachments);
          return;
        }

        await appRepository.addComponents([newComponent]);
        await AttachmentActions.deleteUnsaved(deepCopied.attachments, saved: newComponent.attachments);
        await appRepository.editComponents([
          component.copyWith(
            installations: [
              ...component.installations,
              uninstallation,
            ],
          ),
          ...subcomponentEdits(newComponent.id),
        ]);

        if (!navigatorContext.mounted) return;
        await offerTaskRulesFor(navigatorContext, source: component, target: newComponent);
    }
  }

  static Installation _stampedInstallation(Component component, DateTime at, {String? parentComponentId}) {
    final stamp = stampInstallationNow(component.installations, now: at);
    return parentComponentId == null
        ? Uninstallation(dateTimeUTC: stamp.utc, dateTimeLocal: stamp.local)
        : ComponentInstallation(
            parentComponentId: parentComponentId,
            dateTimeUTC: stamp.utc,
            dateTimeLocal: stamp.local,
          );
  }

  static Future<void> removeComponent(BuildContext context, {required Component component}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final hierarchy = appRepository.componentHierarchy;

    final descendants = appRepository.affectedDescendants(component.id);
    RemoveComponentChoice? choice;
    if (descendants.isNotEmpty) {
      choice = await showRemoveComponentSheet(context, component: component);
      if (choice == null || !context.mounted) return;
    }

    final withSubcomponents = choice?.withSubcomponents ?? false;
    final removed = [component, if (withSubcomponents) ...descendants];
    final bikeId = hierarchy.currentBike(component.id);
    final originalChildren = _componentsOf(appRepository, hierarchy.childrenOf(component.id));
    final detached = choice == null || withSubcomponents
        ? const <Component>[]
        : detachSubcomponents(
            originalChildren,
            mode: choice.detach,
            bikeId: bikeId,
            at: DateTime.now(),
          );

    final removedIds = removed.map((c) => c.id).toSet();
    final relatedTaskRules = appRepository.taskRules.values
        .where((rule) => removedIds.contains(rule.association.componentId))
        .toList();
    final selectedTaskRules = relatedTaskRules.isEmpty
        ? const <TaskRule>[]
        : await showDeleteTaskRulesSheet(context, taskRules: relatedTaskRules, rootComponentId: component.id) ??
            const <TaskRule>[];
    final selectedRuleIds = selectedTaskRules.map((rule) => rule.id).toSet();
    final obsoleteTaskEntries = appRepository.taskEntries.values
        .where((entry) => selectedRuleIds.contains(entry.taskRule))
        .toList();

    if (detached.isNotEmpty) await appRepository.editComponents(detached);
    await appRepository.removeComponents(removed);
    await appRepository.removeTaskRules(selectedTaskRules);
    await appRepository.removeTaskEntries(obsoleteTaskEntries);

    final subcomponentCount = withSubcomponents ? descendants.length : detached.length;
    final subcomponents = Intl.plural(
      subcomponentCount,
      one: '1 subcomponent',
      other: '$subcomponentCount subcomponents',
    );
    final subcomponentSummary = switch (choice) {
      _ when subcomponentCount == 0 => '',
      (withSubcomponents: true, detach: _) => '\nAlso moved to trash: $subcomponents.',
      (withSubcomponents: false, detach: SubcomponentDetach.uninstall) => '\n$subcomponents uninstalled.',
      (withSubcomponents: false, detach: SubcomponentDetach.installOnBike) =>
        "\n$subcomponents installed on '${appRepository.bikes[bikeId]?.name}'.",
      _ => '',
    };
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
        "Component '${component.name}' moved to trash.$subcomponentSummary$taskSummary",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final detachedIds = detached.map((c) => c.id).toSet();
            await appRepository.restoreComponents(removed);
            await appRepository.editComponents(originalChildren.where((c) => detachedIds.contains(c.id)));
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
      filteredComponentsList: appRepository.view.components.values.toList(),
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
        await appRepository.editComponents([component.copyWith(adjustments: [...component.adjustments, newAdjustment])]);
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
        await appRepository.editComponents([component.copyWith(adjustments: [...component.adjustments, newAdjustment])]);
      },
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
