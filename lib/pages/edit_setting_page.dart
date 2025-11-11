import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/setting.dart';

class EditSettingPage extends StatefulWidget {
  final Setting setting;

  const EditSettingPage({super.key, required this.setting});

  @override
  State<EditSettingPage> createState() => _EditSettingPageState();
}

class _EditSettingPageState extends State<EditSettingPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    // Initialize with existing setting values
    _nameController = TextEditingController(text: widget.setting.name);
    _notesController = TextEditingController(text: widget.setting.notes ?? '');
    _selectedDateTime = widget.setting.datetime;
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

    // Return updated setting to previous screen
    Navigator.pop(
      context,
      Setting(name: name, datetime: _selectedDateTime, notes: notes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Setting'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSetting),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
          ],
        ),
      ),
    );
  }
}
