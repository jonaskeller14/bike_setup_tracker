import 'package:flutter/material.dart';
import '../models/component.dart';

class EditComponentPage extends StatefulWidget {
  final Component component;

  const EditComponentPage({super.key, required this.component});

  @override
  State<EditComponentPage> createState() => _EditComponentPageState();
}

class _EditComponentPageState extends State<EditComponentPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Initialize with existing setting values
    _nameController = TextEditingController(text: widget.component.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveSetting() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Return updated setting to previous screen
    Navigator.pop(context, Component(name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Component'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSetting),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Component Name',
            border: OutlineInputBorder(),
            hintText: 'Enter component name',
          ),
        ),
      ),
    );
  }
}
