import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import '../models/component/installation.dart';
import '../repositories/app_repository.dart';
import '../services/component_hierarchy_resolver.dart';
import '../theme.dart';
import '../utils/installation_timeline_validation.dart';
import 'component_ancestor_display.dart';
import 'component_ancestors_column.dart';
import 'sheets/installation_parent_picker.dart';
import 'text/section_title.dart';

extension _ParentOptionWidgets on InstallationParentOption {
  Widget content() {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 20, color: color),
        Expanded(
          child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color)),
        ),
      ],
    );
  }

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
                style: TextStyle(color: effectiveColor, height: 1.1),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor ?? tint ?? theme.hintColor, height: 1.1),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget menuContent(Map<String, Bike> bikes, {bool showDivider = false}) {
    final body = ancestors.isEmpty
        ? content()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              spacing: 8,
              children: [
                Icon(icon, size: 20, color: color),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color)),
                      ComponentAncestorsColumn(ancestors: ancestors, bikes: bikes),
                    ],
                  ),
                ),
              ],
            ),
          );
    if (!showDivider) return body;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flutter bakes a fixed 16px horizontal padding into every dropdown
        LayoutBuilder(
          builder: (context, constraints) => OverflowBox(
            maxWidth: constraints.maxWidth + 32,
            minWidth: constraints.maxWidth + 32,
            fit: OverflowBoxFit.deferToChild,
            child: const Divider(height: 1),
          ),
        ),
        body,
      ],
    );
  }
}

class _ParentPickerField extends StatelessWidget {
  final InstallationParentOption? option;
  final Color? tint;
  final bool enabled;
  final bool changed;
  final InputBorder? invalidBorder;
  final VoidCallback onTap;

  const _ParentPickerField({
    required this.option,
    required this.tint,
    required this.enabled,
    required this.changed,
    required this.invalidBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      // Matches OutlineInputBorder's radius so the ink stays inside the field.
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: InputDecorator(
        decoration: InputDecoration(
          enabled: enabled,
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
                child: option?.fieldContent(context, tint: tint) ??
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

class SetInstallationTimeline extends StatefulWidget {
  final String title;
  final String? componentId;  // The component being edited if existing
  final List<Installation> initialInstallations;
  final List<Installation>? originalInstallations;
  final void Function(List<Installation>) onChanged;
  final bool Function(Installation installation)? isEntryEditable;

  const SetInstallationTimeline({
    super.key,
    this.title = 'Installation Timeline',
    this.componentId,
    required this.initialInstallations,
    this.originalInstallations,
    required this.onChanged,
    this.isEntryEditable,
  });

  @override
  State<SetInstallationTimeline> createState() => _SetInstallationTimelineState();
}

class _SetInstallationTimelineState extends State<SetInstallationTimeline> {
  late List<Installation> _installations;
  late List<Installation>? _originalInstallations;

  @override
  void initState() {
    super.initState();
    _installations = List.from(widget.initialInstallations);
    _installations.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    
    if (widget.originalInstallations != null) {
      _originalInstallations = List.from(widget.originalInstallations!);
      _originalInstallations!.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    } else {
      _originalInstallations = null;
    }
  }

  void _sortInstallations() {
    setState(() {
      _installations.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    });
    widget.onChanged(_installations);
  }

  void _addEntry() {
    final now = DateTime.now();
    setState(() {
      _installations.add(Uninstallation(
        dateTimeUTC: now.toUtc(),
        dateTimeLocal: now,
      ));
    });
    _sortInstallations();
  }

  void _removeEntry(int index) {
    setState(() {
      _installations.removeAt(index);
    });
    widget.onChanged(_installations);
  }

  void _updateEntry(int index, Installation newInstallation) {
    setState(() {
      _installations[index] = newInstallation;
    });
    _sortInstallations();
  }

  List<InstallationParentOption> _parentOptions(
    Installation installation,
    Installation? initial,
    Map<String, Bike> bikes,
    Map<String, Component> components,
    Iterable<Component> parentComponentCandidates,
    ComponentHierarchyResolver hierarchy,
  ) {
    // The chain the component would effectively hang off at this entry's date.
    // "From beginning" (epoch 0) predates every installation, so show the current chain.
    final isFromBeginning = installation.dateTimeUTC.millisecondsSinceEpoch == 0;
    List<ComponentAncestor> ancestorsOf(String componentId) => isFromBeginning
        ? hierarchy.currentAncestors(componentId)
        : hierarchy.ancestorsAt(componentId, installation.dateTimeUTC);

    InstallationParentOption componentOption(ComponentInstallation value) {
      final component = components[value.parentComponentId];
      final ancestors = ancestorsOf(value.parentComponentId);
      return InstallationParentOption(
        value: value,
        icon: component?.componentType.getIconData() ?? Component.iconData,
        label: component?.name ?? 'COMPONENT NOT FOUND',
        subtitle: ancestors.isEmpty ? null : ancestors.map((a) => a.label(bikes)).join(' · '),
        subtitleColor: ancestors.any((a) => a.isMissing(bikes)) ? Theme.of(context).colorScheme.error : null,
        typeLabel: component?.componentType.label,
        color: component == null ? Theme.of(context).colorScheme.error : null,
        ancestors: ancestors,
        isMissing: component == null,
      );
    }

    InstallationParentOption missingBikeOption(BikeInstallation value) => InstallationParentOption(
          value: value,
          icon: Bike.iconData,
          label: 'BIKE NOT FOUND',
          color: Theme.of(context).colorScheme.error,
          isMissing: true,
        );

    bool isOffered(String parentComponentId) =>
        parentComponentCandidates.any((c) => c.id == parentComponentId);

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
      if (installation is BikeInstallation && !bikes.containsKey(installation.parent))
        missingBikeOption(installation),
      if (initial case final BikeInstallation saved
          when !bikes.containsKey(saved.bikeId) && saved.parent != installation.parent)
        missingBikeOption(BikeInstallation(
          bikeId: saved.bikeId,
          id: installation.id,
          dateTimeUTC: installation.dateTimeUTC,
          dateTimeLocal: installation.dateTimeLocal,
        )),
      for (final component in parentComponentCandidates)
        componentOption(ComponentInstallation(
          parentComponentId: component.id,
          id: installation.id,
          dateTimeUTC: installation.dateTimeUTC,
          dateTimeLocal: installation.dateTimeLocal,
        )),
      if (installation case final ComponentInstallation current
          when !isOffered(current.parentComponentId))
        componentOption(current),
      // Keeps the saved parent pickable (and marked as the previous value) after
      // the entry was moved elsewhere.
      if (initial case final ComponentInstallation saved
          when !isOffered(saved.parentComponentId) && saved.parent != installation.parent)
        componentOption(ComponentInstallation(
          parentComponentId: saved.parentComponentId,
          id: installation.id,
          dateTimeUTC: installation.dateTimeUTC,
          dateTimeLocal: installation.dateTimeLocal,
        )),
    ];
  }

  /// The bike this entry belongs to, or the nearest earlier entry's bike; its
  /// components come first in the picker sheet.
  String? _entryBikeId(int index, ComponentHierarchyResolver hierarchy) {
    for (var i = index; i >= 0; i--) {
      final bikeId = switch (_installations[i]) {
        BikeInstallation(:final bikeId) => bikeId,
        ComponentInstallation(:final parentComponentId) => hierarchy.currentBike(parentComponentId),
        Uninstallation() || Archival() => null,
      };
      if (bikeId != null) return bikeId;
    }
    return null;
  }

  Future<void> _pickParent(
    int index,
    List<InstallationParentOption> options, {
    Installation? initial,
    String? depthCapHint,
  }) async {
    final appRepository = context.read<AppRepository>();
    final picked = await showInstallationParentPickerSheet(
      context: context,
      options: options,
      bikes: appRepository.bikes,
      selected: _installations[index],
      initial: initial,
      currentBikeId: _entryBikeId(index, appRepository.componentHierarchy),
      depthCapHint: depthCapHint,
    );
    if (picked == null || !mounted) return;
    _updateEntry(index, picked);
  }

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
    final componentId = widget.componentId;
    if (componentId != null && appRepository.affectedDescendantIds(componentId).isNotEmpty) return const [];
    return appRepository.components.values.where((c) =>
        c.id != componentId && !c.isArchived && c.latestInstallation is! ComponentInstallation);
  }

  InstallationTimelineIssue? _issue(AppRepository appRepository) =>
      installationTimelineIssue(
        _installations,
        componentId: widget.componentId,
        components: appRepository.components,
        bikes: appRepository.bikes,
      );

  Future<void> _pickDateTime(int index) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    // "From beginning" is epoch 0 in UTC, so its local value is not epoch 0 outside UTC.
    final installation = _installations[index];
    final current = installation.isFromBeginning ||
            installation.dateTimeLocal.isBefore(firstDate) ||
            installation.dateTimeLocal.isAfter(lastDate)
        ? DateTime.now()
        : installation.dateTimeLocal;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );
      if (pickedTime != null) {
        final newDateTimeLocal = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _updateEntry(index, _installations[index].copyWith(
          dateTimeUTC: newDateTimeLocal.toUtc(),
          dateTimeLocal: newDateTimeLocal,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final bikes = appRepository.bikes;
    final parentComponentCandidates = _parentComponentCandidates(appRepository, appSettings).toList();
    final hierarchy = appRepository.componentHierarchy;
    final descendantCount = appSettings.enableInstallOnComponent && widget.componentId != null
        ? appRepository.affectedDescendantIds(widget.componentId!).length
        : 0;
    final depthCapHint = descendantCount == 0
        ? null
        : "Can't mount on a component while it carries $descendantCount ${descendantCount == 1 ? 'part' : 'parts'}";
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FormField<List<Installation>>(
      initialValue: _installations,
      validator: (value) => _issue(appRepository)?.message,
      builder: (state) {
        final issue = state.hasError ? _issue(appRepository) : null;
        final invalidBorder = OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: widget.title,
              trailing: widget.isEntryEditable == null
                  ? IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _addEntry,
                      tooltip: 'Add Timeline Entry',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (issue != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        issue.message,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                      ),
                    ),
                  FixedTimeline.tileBuilder(
                    theme: TimelineThemeData(
                      nodePosition: 0,
                      indicatorTheme: IndicatorThemeData(
                        size: 15.0,
                        color: colorScheme.primary,
                      ),
                      connectorTheme: ConnectorThemeData(
                        thickness: 3.0,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    builder: TimelineTileBuilder.connected(
                      connectionDirection: ConnectionDirection.after,
                      itemCount: _installations.length,
                      contentsBuilder: (context, index) {
                        final installation = _installations[index];
                        final isFromBeginning = installation.dateTimeUTC.millisecondsSinceEpoch == 0;
                        final dateStr = isFromBeginning
                            ? 'From beginning'
                            : DateFormat(appSettings.dateFormat).format(installation.dateTimeLocal);
                        final timeStr = isFromBeginning
                            ? null
                            : DateFormat(appSettings.timeFormat).format(installation.dateTimeLocal);

                        final originalInstallation = (_originalInstallations != null && index < _originalInstallations!.length)
                            ? _originalInstallations![index]
                            : null;

                        final bool dateChanged = _originalInstallations != null &&
                            (originalInstallation == null || installation.dateTimeUTC != originalInstallation.dateTimeUTC);

                        final bool bikeChanged = _originalInstallations != null &&
                            (originalInstallation == null || installation.parentType != originalInstallation.parentType || installation.parent != originalInstallation.parent);
                        
                        final bool isEditable = widget.isEntryEditable?.call(installation) ?? true;

                        final bool dateInvalid = issue?.dateTimeIndices.contains(index) ?? false;
                        final bool parentInvalid = issue?.parentIndices.contains(index) ?? false;

                        // Null keeps each element's own default color.
                        final Color? dateColor = dateInvalid
                            ? colorScheme.error
                            : (!isEditable ? theme.disabledColor : null);
                        final Color? parentColor = parentInvalid
                            ? colorScheme.error
                            : (!isEditable ? theme.disabledColor : null);

                        final parentOptions = _parentOptions(installation, originalInstallation, bikes, appRepository.components, parentComponentCandidates, hierarchy);
                        final firstComponentOptionIndex = parentOptions.indexWhere((o) => o.value is ComponentInstallation);

                        return Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 4, bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Date selection
                              Expanded(
                                flex: 1,
                                child: Theme(
                                  data: theme.copyWith(
                                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    ),
                                  ),
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    enabled: isEditable,
                                    // Matches OutlineInputBorder's radius so the ink stays inside the field.
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    onSelected: (value) async {
                                      if (value == 'beginning') {
                                        _updateEntry(index, installation.copyWith(
                                          dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                                          dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
                                        ));
                                      } else if (value == 'now') {
                                        final now = DateTime.now();
                                        _updateEntry(index, installation.copyWith(
                                          dateTimeUTC: now.toUtc(),
                                          dateTimeLocal: now,
                                        ));
                                      } else if (value == 'select') {
                                        await _pickDateTime(index);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final othersHaveIt = _installations.where((e) => e.dateTimeUTC.millisecondsSinceEpoch == 0).isNotEmpty && !isFromBeginning;
                                      return [
                                        PopupMenuItem(
                                          value: 'beginning',
                                          enabled: !othersHaveIt,
                                          child: Text('From beginning', style: TextStyle(color: othersHaveIt ? theme.disabledColor : null)),
                                        ),
                                        const PopupMenuItem(value: 'now', child: Text('Now')),
                                        const PopupMenuItem(value: 'select', child: Text('Select date & time...')),
                                      ];
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        enabled: isEditable,
                                        border: const OutlineInputBorder(),
                                        enabledBorder: dateInvalid ? invalidBorder : null,
                                        disabledBorder: dateInvalid ? invalidBorder : null,
                                        focusedBorder: dateInvalid ? invalidBorder : null,
                                        isDense: true,
                                        filled: dateChanged,
                                        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                      ),
                                      child: Container(
                                        // Fix height to match DropdownButtonFormField
                                        height: 48,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    dateStr,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: dateColor,
                                                      height: 1.1,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (timeStr != null)
                                                    Text(
                                                      timeStr,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: dateColor ?? theme.hintColor,
                                                        height: 1.1,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down, size: 24, color: dateColor ?? colorScheme.onSurfaceVariant),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (appSettings.enableInstallOnComponent)
                                Expanded(
                                  flex: 1,
                                  child: _ParentPickerField(
                                    option: parentOptions.where((o) => o.value == installation).firstOrNull,
                                    tint: parentColor,
                                    enabled: isEditable,
                                    changed: bikeChanged,
                                    invalidBorder: parentInvalid ? invalidBorder : null,
                                    onTap: () => _pickParent(
                                      index,
                                      parentOptions,
                                      initial: originalInstallation,
                                      depthCapHint: depthCapHint,
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<Installation>(
                                    initialValue: installation,
                                    hint: const Text('Select Bike'),
                                    isExpanded: true,
                                    isDense: false,
                                    itemHeight: null,
                                    iconEnabledColor: parentColor,
                                    iconDisabledColor: parentColor,
                                    decoration: InputDecoration(
                                      enabled: isEditable,
                                      border: const OutlineInputBorder(),
                                      enabledBorder: parentInvalid ? invalidBorder : null,
                                      disabledBorder: parentInvalid ? invalidBorder : null,
                                      focusedBorder: parentInvalid ? invalidBorder : null,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      filled: bikeChanged,
                                      fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    ),
                                    items: [
                                      for (final (i, option) in parentOptions.indexed)
                                        DropdownMenuItem<Installation>(
                                          value: option.value,
                                          child: option.menuContent(bikes, showDivider: i == firstComponentOptionIndex),
                                        ),
                                    ],
                                    // The closed field, unlike the menu entries, is tinted when the
                                    // entry is locked or the validator flagged its parent.
                                    selectedItemBuilder: (context) => [
                                      for (final option in parentOptions)
                                        option.fieldContent(context, tint: parentColor),
                                    ],
                                    onChanged: !isEditable
                                        ? null
                                        : (Installation? newInstallation) {
                                            if (newInstallation == null) return;
                                            _updateEntry(index, newInstallation);
                                          },
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: (_installations.length > 1 && isEditable) ? () => _removeEntry(index) : null,
                                color: (_installations.length > 1 && isEditable) ? null : theme.disabledColor,
                              ),
                            ],
                          ),
                        );
                      },
                      indicatorBuilder: (context, index) {
                        final installation = _installations[index];
                        return switch (installation) {
                          BikeInstallation _ => OutlinedDotIndicator(
                              borderWidth: 2.5,
                              color: colorScheme.primary,
                            ),
                          ComponentInstallation() => OutlinedDotIndicator(
                              borderWidth: 2.5,
                              color: colorScheme.primary,
                            ),
                          Uninstallation _ => OutlinedDotIndicator(
                              borderWidth: 2.5,
                              color: colorScheme.outline,
                              child: Icon(Icons.close, size: 10, color: colorScheme.outline),
                            ),
                          Archival _ => OutlinedDotIndicator(
                              borderWidth: 2.5,
                              color: colorScheme.outline,
                              child: Icon(Icons.close, size: 10, color: colorScheme.outline),
                            ),
                        };
                      },
                      connectorBuilder: (context, index, type) {
                        final installation = _installations[index];
                        return switch (installation) {
                          BikeInstallation() => SolidLineConnector(color: colorScheme.primary.withValues(alpha: 0.6)),
                          ComponentInstallation() => SolidLineConnector(color: colorScheme.primary.withValues(alpha: 0.6)),
                          Uninstallation() || Archival() => DashedLineConnector(color: colorScheme.outline),
                        };
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
