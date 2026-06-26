import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/component.dart';
import '../../repositories/app_repository.dart';
import 'sheet_header.dart';

sealed class ReplaceComponentResult {
  final DateTime replacementDate;
  const ReplaceComponentResult({required this.replacementDate});
}

class ReplaceComponentNewResult extends ReplaceComponentResult {
  const ReplaceComponentNewResult({required super.replacementDate});
}

class ReplaceComponentExistingResult extends ReplaceComponentResult {
  final Component existingComponent;
  const ReplaceComponentExistingResult({
    required super.replacementDate,
    required this.existingComponent,
  });
}

enum _ReplaceMode { existing, create }

Future<ReplaceComponentResult?> showReplaceComponentSheet(BuildContext context, {
  required Component component,
}) async {
  return showModalBottomSheet<ReplaceComponentResult?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return _ReplaceComponentSheet(component: component);
    }
  );
}

class _ReplaceComponentSheet extends StatefulWidget {
  final Component component;

  const _ReplaceComponentSheet({required this.component});

  @override
  State<StatefulWidget> createState() => _ReplaceComponentSheetState();
}

class _ReplaceComponentSheetState extends State<_ReplaceComponentSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _replaceDate;
  _ReplaceMode _mode = _ReplaceMode.create;
  String? _selectedComponentId;

  @override
  void initState() {
    super.initState();
    _replaceDate = DateTime.now();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final ReplaceComponentResult result = switch (_mode) {
      _ReplaceMode.existing => ReplaceComponentExistingResult(
        replacementDate: _replaceDate,
        existingComponent: context.read<AppRepository>().components[_selectedComponentId]!,
      ),
      _ReplaceMode.create => ReplaceComponentNewResult(
        replacementDate: _replaceDate,
      ),
    };

    Navigator.pop(context, result);
  }

  Future<DateTime?> _showDateTimePicker(DateTime initialDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      if (!mounted) return null;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  DropdownMenuItem<String> _componentSectionHeader(String label) {
    return DropdownMenuItem<String>(
      enabled: false,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  DropdownMenuItem<String> _componentDropdownItem(Component component) {
    return DropdownMenuItem<String>(
      value: component.id,
      child: Row(
        spacing: 8,
        children: [
          Icon(component.componentType.getIconData(), size: 20),
          Expanded(child: Text(component.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final deinstalledComponents = appRepository.components.values
        .where((c) => c.id != widget.component.id && c.bike == null)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Keep the selected component in the list even if it stops being
    // "deinstalled" (e.g. while the sheet animates away after the swap installed
    // it), so the dropdown always has exactly one item matching its value.
    final menuComponents = [...deinstalledComponents];
    final selected = appRepository.components[_selectedComponentId];
    if (selected != null && !menuComponents.any((c) => c.id == selected.id)) {
      menuComponents.add(selected);
    }
    final sameTypeComponents = menuComponents.where((c) => c.componentType == widget.component.componentType).toList();
    final otherTypeComponents = menuComponents.where((c) => c.componentType != widget.component.componentType).toList();
    final showComponentSections = sameTypeComponents.isNotEmpty && otherTypeComponents.isNotEmpty;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: "Replace '${widget.component.name}'"),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_ReplaceMode>(
                        segments: const [
                          ButtonSegment(
                            value: _ReplaceMode.existing,
                            label: Text("Existing"),
                            icon: Icon(Icons.inventory_2_outlined),
                          ),
                          ButtonSegment(
                            value: _ReplaceMode.create,
                            label: Text("New"),
                            icon: Icon(Icons.add),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() => _mode = selection.first);
                          _formKey.currentState?.validate();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      switch (_mode) {
                        _ReplaceMode.existing =>  "Pick an already deinstalled component to install in place of this one, and set the replacement date. This is when the current component is retired and the selected one installed.",
                        _ReplaceMode.create => "Set the replacement date. This is when the current component will be retired and a new one installed. In the next step, you can configure the new component, which will be pre-filled with details from this one.",
                      },
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_mode == _ReplaceMode.existing) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedComponentId,
                        isExpanded: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: "Replacement Component",
                          border: const OutlineInputBorder(),
                          isDense: true,
                          helperText: deinstalledComponents.isEmpty
                              ? "No deinstalled components available"
                              : null,
                        ),
                        hint: const Text("Select a component"),
                        items: [
                          if (showComponentSections) ...[
                            _componentSectionHeader(widget.component.componentType.label),
                            ...sameTypeComponents.map(_componentDropdownItem),
                            _componentSectionHeader("Other"),
                            ...otherTypeComponents.map(_componentDropdownItem),
                          ] else
                            ...menuComponents.map(_componentDropdownItem),
                        ],
                        onChanged: menuComponents.isEmpty
                            ? null
                            : (id) => setState(() => _selectedComponentId = id),
                        validator: (id) {
                          if (_mode == _ReplaceMode.existing && id == null) {
                            return "Please select a component";
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    FormField<DateTime>(
                      initialValue: _replaceDate,
                      validator: (value) {
                        if (value == null) return null;
                        DateTime? lastInstall = widget.component.installations.map((i) => i.dateTimeUTC).maxOrNull;
                        if (_mode == _ReplaceMode.existing && _selectedComponentId != null) {
                          // The chosen component must not be reinstalled before its own
                          // last (de)installation, or the timeline would be out of order.
                          final existingLast = appRepository.components[_selectedComponentId]
                              ?.installations.map((i) => i.dateTimeUTC).maxOrNull;
                          if (existingLast != null && (lastInstall == null || existingLast.isAfter(lastInstall))) {
                            lastInstall = existingLast;
                          }
                        }
                        if (lastInstall != null && !value.toUtc().isAfter(lastInstall)) {
                          final formatted = DateFormat("${appSettings.dateFormat} ${appSettings.timeFormat}")
                              .format(lastInstall.toLocal());
                          return "Must be after last installation ($formatted)";
                        }
                        return null;
                      },
                      builder: (state) {
                        return InkWell(
                          onTap: () async {
                            final picked = await _showDateTimePicker(state.value ?? DateTime.now());
                            if (picked != null) {
                              state.didChange(picked);
                              setState(() => _replaceDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Replacement Date",
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText: state.errorText,
                              suffixIcon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(appSettings.dateFormat).format(state.value ?? _replaceDate),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat(appSettings.timeFormat).format(state.value ?? _replaceDate),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _onContinue,
                label: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
