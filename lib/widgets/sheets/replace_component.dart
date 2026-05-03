import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/component.dart';
import 'sheet.dart';

Future<DateTime?> showReplaceComponentSheet(BuildContext context, {
  required Component component,
}) async {
  return showModalBottomSheet<DateTime?>(
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

  @override
  void initState() {
    super.initState();
    _replaceDate = DateTime.now();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    
    Navigator.pop(context, _replaceDate);
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

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  sheetTitle(context, "Replace '${widget.component.name}'"),
                  sheetCloseButton(context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Set the replacement date. This is when the current component will be retired and a new one installed. In the next step, you can configure the new component, which will be pre-filled with details from this one.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    FormField<DateTime>(
                      initialValue: _replaceDate,
                      validator: (value) {
                        if (value == null) return null;
                        final lastInstall = widget.component.installations.map((i) => i.dateTimeUTC).maxOrNull;
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
