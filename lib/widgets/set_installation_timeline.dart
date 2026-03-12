import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../models/installation.dart';
import '../models/bike.dart';
import '../repositories/app_repository.dart';
import '../models/app_settings.dart';

class SetInstallationTimeline extends StatefulWidget {
  final List<Installation> initialInstallations;
  final List<Installation>? originalInstallations;
  final Function(List<Installation>) onChanged;

  const SetInstallationTimeline({
    super.key,
    required this.initialInstallations,
    this.originalInstallations,
    required this.onChanged,
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
      _installations.add(Installation(
        parent: null,
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
          final isFromBeginning = current.dateTimeUTC.millisecondsSinceEpoch == 0;

          if (isFromBeginning && current.parent == null) {
            return '"From beginning" entries must be associated with a bike';
          }

          if (i < _installations.length - 1) {
            final next = _installations[i + 1];
            if (current.parent == null && next.parent == null) {
              return 'Cannot have consecutive deinstallations';
            }
            if (current.parent != null && current.parent == next.parent) {
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Installation Timeline', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addEntry,
                    tooltip: 'Add Timeline Entry',
                  ),
                ],
              ),
            ),
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
                  final formattedDateTime = isFromBeginning
                      ? 'From beginning'
                      : "${DateFormat(appSettings.dateFormat).format(installation.dateTimeLocal)} ${DateFormat(appSettings.timeFormat).format(installation.dateTimeLocal)}";

                  final originalInstallation = (_originalInstallations != null && index < _originalInstallations!.length)
                      ? _originalInstallations![index]
                      : null;

                  final bool dateChanged = _originalInstallations != null &&
                      (originalInstallation == null || installation.dateTimeUTC != originalInstallation.dateTimeUTC);

                  final bool bikeChanged = _originalInstallations != null &&
                      (originalInstallation == null || installation.parent != originalInstallation.parent);
                  
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
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                              ),
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  // Fix height to match DropdownButtonFormField
                                  height: 48,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            formattedDateTime,
                                            style: theme.textTheme.bodyMedium,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down, size: 24, color: colorScheme.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                                onSelected: (value) async {
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
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bike selection
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String?>(
                            initialValue: installation.parent,
                            hint: const Text('Select Bike'),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              filled: bikeChanged,
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: const Row(
                                  spacing: 8,
                                  children: [
                                    Icon(Icons.shelves, size: 20),
                                    Expanded(child: Text('DEINSTALLED', overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              ...bikes.values.map((bike) => DropdownMenuItem<String?>(
                                    value: bike.id,
                                    child: Row(
                                      spacing: 8,
                                      children: [
                                        const Icon(Bike.iconData, size: 20),
                                        Expanded(child: Text(bike.name, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  )),
                            ],
                            onChanged: (val) {
                              _updateEntry(index, installation.copyWith(parent: val));
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                          onPressed: _installations.length > 1 ? () => _removeEntry(index) : null,
                          color: _installations.length > 1 ? null : theme.disabledColor,
                        ),
                      ],
                    ),
                  );
                },
                indicatorBuilder: (context, index) {
                  final installation = _installations[index];
                  return OutlinedDotIndicator(
                    borderWidth: 2.5,
                    color: installation.parent != null ? colorScheme.primary : colorScheme.outline,
                    child: installation.parent == null ? Icon(Icons.close, size: 10, color: colorScheme.outline) : null,
                  );
                },
                connectorBuilder: (context, index, type) {
                  final installation = _installations[index];
                  if (installation.parent == null) {
                    return DashedLineConnector(color: colorScheme.outlineVariant);
                  }
                  return SolidLineConnector(color: colorScheme.primary.withValues(alpha: 0.6));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}