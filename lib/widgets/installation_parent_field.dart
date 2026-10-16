import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_hint.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import '../models/component/component_parent_types.dart';
import '../models/component/installation.dart';
import '../repositories/app_repository.dart';
import '../services/app_hint_service.dart';
import '../services/component_hierarchy_resolver.dart';
import '../theme.dart';
import 'component_ancestor_display.dart';
import 'hints/installation_timeline_hint.dart';
import 'hints/subcomponents_hint.dart';
import 'sheets/installation_parent_picker.dart';

extension _ParentOptionWidgets on InstallationParentOption {
  Widget fieldContent(BuildContext context, {Color? tint}) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? tint;
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: effectiveColor, height: 1.1, fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor ?? tint ?? theme.hintColor,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "Installed on" field of one installation entry. It opens the parent
/// picker sheet, which offers bikes and, with Subcomponents enabled, components.
class InstallationParentField extends StatelessWidget {
  final Installation installation;

  /// The saved entry: marked in the sheet and kept pickable.
  final Installation? initial;

  /// The component being edited, if it already exists.
  final String? componentId;
  final ComponentType? componentType;

  /// Components on this bike come first in the sheet.
  final String? currentBikeId;
  final bool allowArchive;
  final bool enabled;
  final bool changed;
  final Color? tint;
  final InputBorder? invalidBorder;
  final String? labelText;
  final String? helperText;
  final String? errorText;

  /// The edited component's saved history. When set, the sheet may suggest the
  /// Installation Timeline for moving it.
  final List<Installation>? timelineOfferInstallations;
  final ValueChanged<Installation> onChanged;

  const InstallationParentField({
    super.key,
    required this.installation,
    this.initial,
    this.componentId,
    this.componentType,
    this.currentBikeId,
    this.allowArchive = true,
    this.enabled = true,
    this.changed = false,
    this.tint,
    this.invalidBorder,
    this.labelText,
    this.helperText,
    this.errorText,
    this.timelineOfferInstallations,
    required this.onChanged,
  });

  /// The bike [installation] puts a component on, directly or through its parent.
  static String? bikeIdOf(Installation installation, ComponentHierarchyResolver hierarchy) => switch (installation) {
    BikeInstallation(:final bikeId) => bikeId,
    ComponentInstallation(:final parentComponentId) => hierarchy.currentBike(parentComponentId),
    Uninstallation() || Archival() => null,
  };

  /// Nesting depth is capped at one level in this picker:
  /// `Bike > Component > Component` is allowed,
  /// `Bike > Component > Component > Component` is not.
  ///
  /// Enforced from both ends:
  /// - a parent must be top-level (its latest installation is not on a component);
  /// - the edited component must be a leaf (no current descendants), otherwise
  ///   no component parents are offered at all.
  ///
  /// Caveats: both checks use the current state, not the entry's date, so a
  /// backdated entry can still create a deeper chain in the past. The cap is
  /// UI-only; the model, validation, import, hierarchy resolver and Strava
  /// credit all support arbitrary depth, so deeper existing data keeps working.
  Iterable<Component> _parentComponentCandidates(AppRepository appRepository, AppSettings appSettings) {
    if (!appSettings.enableInstallOnComponent) return const [];
    final componentId = this.componentId;
    if (componentId != null && appRepository.affectedDescendantIds(componentId).isNotEmpty) return const [];
    return appRepository.components.values.where(
      (c) => c.id != componentId && !c.isArchived && c.latestInstallation is! ComponentInstallation,
    );
  }

  List<InstallationParentOption> _options(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final bikes = appRepository.bikes;
    final components = appRepository.components;
    final hierarchy = appRepository.componentHierarchy;
    final parentComponentCandidates = _parentComponentCandidates(appRepository, appSettings).toList();
    final errorColor = Theme.of(context).colorScheme.error;
    final initial = this.initial;

    // The chain the component would effectively hang off at this entry's date.
    // "From beginning" (epoch 0) predates every installation, so show the current chain.
    List<ComponentAncestor> ancestorsOf(String componentId) => installation.isFromBeginning
        ? hierarchy.currentAncestors(componentId)
        : hierarchy.ancestorsAt(componentId, installation.dateTimeUTC);

    // The current and saved parents always stay suggested, so an unusual
    // existing parent is never tucked away behind "Show all".
    bool isSuggested(Component? component, String parentComponentId) =>
        component == null ||
        parentComponentId == installation.parent ||
        (initial is ComponentInstallation && parentComponentId == initial.parent) ||
        isSuggestedParent(componentType, component.componentType);

    InstallationParentOption componentOption(ComponentInstallation value) {
      final component = components[value.parentComponentId];
      final ancestors = ancestorsOf(value.parentComponentId);
      return InstallationParentOption(
        isSuggested: isSuggested(component, value.parentComponentId),
        value: value,
        icon: component?.componentType.getIconData() ?? Component.iconData,
        label: component?.name ?? 'COMPONENT NOT FOUND',
        subtitle: ancestors.isEmpty ? null : ancestors.map((a) => a.label(bikes)).join(' · '),
        subtitleColor: ancestors.any((a) => a.isMissing(bikes)) ? errorColor : null,
        typeLabel: component?.componentType.label,
        color: component == null ? errorColor : null,
        ancestors: ancestors,
        isMissing: component == null,
      );
    }

    InstallationParentOption missingBikeOption(BikeInstallation value) => InstallationParentOption(
      value: value,
      icon: Bike.iconData,
      label: 'BIKE NOT FOUND',
      color: errorColor,
      isMissing: true,
    );

    bool isOffered(String parentComponentId) => parentComponentCandidates.any((c) => c.id == parentComponentId);

    return [
      InstallationParentOption(
        value: Uninstallation(
          id: installation.id,
          dateTimeUTC: installation.dateTimeUTC,
          dateTimeLocal: installation.dateTimeLocal,
        ),
        icon: Icons.shelves,
        label: 'UNINSTALLED',
      ),
      if (allowArchive || installation is Archival)
        InstallationParentOption(
          value: Archival(
            id: installation.id,
            dateTimeUTC: installation.dateTimeUTC,
            dateTimeLocal: installation.dateTimeLocal,
          ),
          icon: Icons.inventory_2_outlined,
          label: 'ARCHIVED',
        ),
      for (final bike in bikes.values)
        InstallationParentOption(
          value: BikeInstallation(
            bikeId: bike.id,
            id: installation.id,
            dateTimeUTC: installation.dateTimeUTC,
            dateTimeLocal: installation.dateTimeLocal,
          ),
          icon: Bike.iconData,
          label: bike.name,
        ),
      if (installation case final BikeInstallation current when !bikes.containsKey(current.parent))
        missingBikeOption(current),
      if (initial case final BikeInstallation saved
          when !bikes.containsKey(saved.bikeId) && saved.parent != installation.parent)
        missingBikeOption(
          BikeInstallation(
            bikeId: saved.bikeId,
            id: installation.id,
            dateTimeUTC: installation.dateTimeUTC,
            dateTimeLocal: installation.dateTimeLocal,
          ),
        ),
      for (final component in parentComponentCandidates)
        componentOption(
          ComponentInstallation(
            parentComponentId: component.id,
            id: installation.id,
            dateTimeUTC: installation.dateTimeUTC,
            dateTimeLocal: installation.dateTimeLocal,
          ),
        ),
      if (installation case final ComponentInstallation current when !isOffered(current.parentComponentId))
        componentOption(current),
      // Keeps the saved parent pickable (and marked as the previous value) after
      // the entry was moved elsewhere.
      if (initial case final ComponentInstallation saved
          when !isOffered(saved.parentComponentId) && saved.parent != installation.parent)
        componentOption(
          ComponentInstallation(
            parentComponentId: saved.parentComponentId,
            id: installation.id,
            dateTimeUTC: installation.dateTimeUTC,
            dateTimeLocal: installation.dateTimeLocal,
          ),
        ),
    ];
  }

  /// At most one suggestion, Subcomponents first. Runs in the sheet's context,
  /// so the card disappears once handled.
  Widget? _hint(BuildContext context) {
    final hintService = context.watch<AppHintService>();
    final mountParent = hintService.subcomponentsMountParent(
      componentType,
      componentId: componentId,
      currentBikeId: currentBikeId,
    );
    if (mountParent != null) {
      return SubcomponentsHint(
        parentName: mountParent.name,
        onDismiss: () => unawaited(hintService.dismiss(AppHint.subcomponentsV1)),
        onActivate: () async {
          // The sheet stays open and lists the components right away.
          context.read<AppSettings>().enableInstallOnComponent = true;
          await hintService.complete(AppHint.subcomponentsV1);
        },
      );
    }

    final saved = timelineOfferInstallations;
    if (saved != null && hintService.shouldOfferInstallationTimelineOnMove(saved)) {
      return InstallationTimelineHint(
        message:
            'Keep a dated history of where this part was installed, so setups and ride stats match '
            'the parts that were really on the bike.',
        onDismiss: () => unawaited(hintService.dismiss(AppHint.installationTimelineV1)),
        onActivate: () async {
          final navigator = Navigator.of(context);
          context.read<AppSettings>().enableInstallationTimeline = true;
          await hintService.complete(AppHint.installationTimelineV1);
          // The form now shows the timeline, where the move gets its date.
          navigator.pop();
        },
      );
    }
    return null;
  }

  Future<void> _pick(BuildContext context) async {
    final appRepository = context.read<AppRepository>();
    final appSettings = context.read<AppSettings>();
    final componentId = this.componentId;
    final descendantCount = appSettings.enableInstallOnComponent && componentId != null
        ? appRepository.affectedDescendantIds(componentId).length
        : 0;
    final picked = await showInstallationParentPickerSheet(
      context: context,
      optionsBuilder: _options,
      hintBuilder: _hint,
      bikes: appRepository.bikes,
      selected: installation,
      initial: initial,
      currentBikeId: currentBikeId,
      depthCapHint: descendantCount == 0
          ? null
          : "Can't mount on a component while it carries $descendantCount ${descendantCount == 1 ? 'part' : 'parts'}",
      componentTypeLabel: componentType?.label,
    );
    if (picked == null || !context.mounted) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = _options(context).where((o) => o.value == installation).firstOrNull;
    return InkWell(
      onTap: enabled ? () => unawaited(_pick(context)) : null,
      // Matches OutlineInputBorder's radius so the ink stays inside the field.
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: InputDecorator(
        decoration: InputDecoration(
          enabled: enabled,
          labelText: labelText,
          helperText: helperText,
          errorText: errorText,
          border: const OutlineInputBorder(),
          enabledBorder: invalidBorder,
          disabledBorder: invalidBorder,
          focusedBorder: invalidBorder,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: changed,
          fillColor: theme.extension<ValueHighlightColors>()!.changedFill,
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child:
                    option?.fieldContent(context, tint: tint) ??
                    Text('Select Bike', style: TextStyle(color: theme.hintColor)),
              ),
              Icon(Icons.arrow_drop_down, size: 24, color: tint ?? theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
