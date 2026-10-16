import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../models/app_settings.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../repositories/app_repository.dart';
import '../services/component_hierarchy_resolver.dart';
import '../theme.dart';
import '../utils/installation_timeline_validation.dart';
import 'installation_parent_field.dart';
import 'text/section_title.dart';

class SetInstallationTimeline extends StatefulWidget {
  final String title;
  final String? componentId;  // The component being edited if existing
  final ComponentType? componentType;
  final List<Installation> initialInstallations;
  final List<Installation>? originalInstallations;
  final void Function(List<Installation>) onChanged;
  final bool Function(Installation installation)? isEntryEditable;

  const SetInstallationTimeline({
    super.key,
    this.title = 'Installation Timeline',
    this.componentId,
    this.componentType,
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

  /// The bike this entry belongs to, or the nearest earlier entry's bike; its
  /// components come first in the picker sheet.
  String? _entryBikeId(int index, ComponentHierarchyResolver hierarchy) {
    for (var i = index; i >= 0; i--) {
      final bikeId = InstallationParentField.bikeIdOf(_installations[i], hierarchy);
      if (bikeId != null) return bikeId;
    }
    return null;
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
    final hierarchy = appRepository.componentHierarchy;
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
                              Expanded(
                                flex: 1,
                                child: InstallationParentField(
                                  installation: installation,
                                  initial: originalInstallation,
                                  componentId: widget.componentId,
                                  componentType: widget.componentType,
                                  currentBikeId: _entryBikeId(index, hierarchy),
                                  tint: parentColor,
                                  enabled: isEditable,
                                  changed: bikeChanged,
                                  invalidBorder: parentInvalid ? invalidBorder : null,
                                  onChanged: (picked) => _updateEntry(index, picked),
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
