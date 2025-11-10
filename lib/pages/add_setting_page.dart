import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddSettingPage extends StatefulWidget {
  const AddSettingPage({super.key});

  @override
  State<AddSettingPage> createState() => _AddSettingPageState();
}

class _AddSettingPageState extends State<AddSettingPage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
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
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, {
                  'name': name,
                  'datetime': _selectedDateTime,
                });
              }
            },
          ),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _pickDateTime,
                child: Chip(
                  avatar: const Icon(Icons.calendar_today, size: 20),
                  label: Text(DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
