import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/installation.dart';
import '../repositories/app_repository.dart';
import '../theme.dart';
import 'text/section_title.dart';

class SetInstallationTimeline extends StatefulWidget {
  final String title;
  final List<Installation> initialInstallations;
  final List<Installation>? originalInstallations;
  final Function(List<Installation>) onChanged;
  final bool Function(Installation installation)? isEntryEditable;

  const SetInstallationTimeline({
    super.key,
    this.title = 'Installation Timeline',
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
    setState(() {
      _installations.add(Uninstallation(
        dateTimeUTC: DateTime.now().toUtc(),
        dateTimeLocal: DateTime.now(),
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

  Future<void> _pickDateTime(int index) async {
    final current = _installations[index].dateTimeLocal;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.millisecondsSinceEpoch == 0 ? DateTime.now() : current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current.millisecondsSinceEpoch == 0 ? DateTime.now() : current),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FormField<List<Installation>>(
      initialValue: _installations,
      validator: (value) {
        if (_installations.isEmpty) {
          return 'At least one entry is required';
        }
        for (int i = 0; i < _installations.length; i++) {
          final current = _installations[i];

          if (i < _installations.length - 1) {
            if (current is Archival) {
              return 'Archival can only be the last entry in the timeline';
            }
            final next = _installations[i + 1];
            if (current is Uninstallation && next is Uninstallation) {
              return 'Cannot have consecutive uninstallations';
            }
            if (current is BikeInstallation && next is BikeInstallation && current.bikeId == next.bikeId) {
              return 'Cannot have consecutive installations on the same bike';
            }
          }
        }
        final fromBeginningCount = _installations.where((e) => e.dateTimeUTC.millisecondsSinceEpoch == 0).length;
        if (fromBeginningCount > 1) {
          return 'Multiple "From beginning" entries are not allowed';
        }

        return null;
      },
      builder: (state) {
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
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        state.errorText!,
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
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      filled: dateChanged,
                                      fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    ),
                                    child: PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      onSelected: !isEditable ? null : (value) async {
                                        if (value == 'beginning') {
                                          _updateEntry(index, Installation.sinceBeginning(parent: installation.parent));
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
                                                      color: !isEditable ? theme.disabledColor : null,
                                                      height: 1.1,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (timeStr != null)
                                                    Text(
                                                      timeStr,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: !isEditable ? theme.disabledColor : theme.hintColor,
                                                        height: 1.1,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down, size: 24, color: !isEditable ? theme.disabledColor : colorScheme.onSurfaceVariant),
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
                                child: DropdownButtonFormField<Installation>(
                                  initialValue: installation,
                                  hint: const Text('Select Bike'),
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    filled: bikeChanged,
                                    fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  ),
                                  items: [
                                    DropdownMenuItem<Installation>(
                                      value: Uninstallation(
                                        id: installation.id,
                                        componentId: installation.componentId,
                                        dateTimeUTC: installation.dateTimeUTC,
                                        dateTimeLocal: installation.dateTimeLocal,
                                      ),
                                      child: Row(
                                        spacing: 8,
                                        children: [
                                          Icon(Icons.shelves, size: 20, color: !isEditable ? theme.disabledColor : null),
                                          Expanded(child: Text('UNINSTALLED', overflow: TextOverflow.ellipsis, style: TextStyle(color: !isEditable ? theme.disabledColor : null))),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem<Installation>(
                                      value: Archival(
                                        id: installation.id,
                                        componentId: installation.componentId,
                                        dateTimeUTC: installation.dateTimeUTC,
                                        dateTimeLocal: installation.dateTimeLocal,
                                      ),
                                      child: Row(
                                        spacing: 8,
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 20, color: !isEditable ? theme.disabledColor : null),
                                          Expanded(child: Text('ARCHIVED', overflow: TextOverflow.ellipsis, style: TextStyle(color: !isEditable ? theme.disabledColor : null))),
                                        ],
                                      ),
                                    ),
                                    ...bikes.values.map((bike) => DropdownMenuItem<Installation>(
                                          value: BikeInstallation(
                                            bikeId: bike.id,
                                            id: installation.id,
                                            componentId: installation.componentId,
                                            dateTimeUTC: installation.dateTimeUTC,
                                            dateTimeLocal: installation.dateTimeLocal,
                                          ),
                                          child: Row(
                                            spacing: 8,
                                            children: [
                                              Icon(Bike.iconData, size: 20, color: !isEditable ? theme.disabledColor : null),
                                              Expanded(child: Text(bike.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: !isEditable ? theme.disabledColor : null))),
                                            ],
                                          ),
                                        )),
                                    if (installation is BikeInstallation && !bikes.containsKey(installation.parent))
                                      DropdownMenuItem<Installation>(
                                        value: installation,
                                        child: Row(
                                          spacing: 8,
                                          children: [
                                            Icon(Bike.iconData, size: 20, color: theme.colorScheme.error),
                                            Expanded(
                                              child: Text(
                                                'BIKE NOT FOUND',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: theme.colorScheme.error),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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