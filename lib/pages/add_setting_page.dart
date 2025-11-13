import 'package:bike_setup_tracker/models/adjustment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/setting.dart';
import '../models/component.dart';
import '../widgets/adjustment_set_list.dart';

class AddSettingPage extends StatefulWidget {
  final List<Component> components;

  const AddSettingPage({super.key, required this.components});

  @override
  State<AddSettingPage> createState() => _AddSettingPageState();
}

class _AddSettingPageState extends State<AddSettingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  Map<Adjustment, dynamic> adjustmentValues = {};

  @override
  void initState() {
    for (final component in widget.components) {
      if (component.currentSetting == null) continue;
      final componentAdjustmentValues = component.currentSetting?.adjustmentValues;
      if (componentAdjustmentValues == null) continue;
      for (final adjustmentValue in componentAdjustmentValues.entries) {
        adjustmentValues[adjustmentValue.key] = adjustmentValue.value;
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    // Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    // Pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _saveSetting() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notesText = _notesController.text.trim();
    final notes = notesText.isEmpty ? null : notesText;

    //TODO: Check if at least one value has changed from current setting. Or set adjustmentValues

    // Return updated setting to previous screen
    Navigator.pop(
      context,
      Setting(name: name, datetime: _selectedDateTime, notes: notes, adjustmentValues: adjustmentValues),
    );
  }

  void _onAdjustmentValueChanged(Adjustment adjustment, dynamic newValue) {
    adjustmentValues[adjustment] = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Setting'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSetting),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Setting Name',
              border: OutlineInputBorder(),
              hintText: 'Enter setting name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Add notes (optional)',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.calendar_today, size: 20),
              label: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: Colors.blue.shade50,
              onPressed: _pickDateTime,
            ),
          ),
          const SizedBox(height: 24),
          if (widget.components.isEmpty)
            const Center(
              child: Text(
                'No components available.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...widget.components.map((component) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(component.name),
                      subtitle: Text('${component.adjustments.length} adjustments'),
                      leading: const Icon(Icons.casino),
                    ),
                    AdjustmentSetList(
                      adjustments: component.adjustments,
                      initialAdjustmentValues: component.currentSetting?.adjustmentValues ?? <Adjustment, dynamic>{},
                      onAdjustmentValueChanged: _onAdjustmentValueChanged,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
