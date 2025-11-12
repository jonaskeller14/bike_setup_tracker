import '../models/adjustment.dart';
import 'package:flutter/material.dart';


class AddBooleanAdjustmentPage extends StatefulWidget {
  const AddBooleanAdjustmentPage({super.key});

  @override
  State<AddBooleanAdjustmentPage> createState() => _AddBooleanAdjustmentPageState();
}

class _AddBooleanAdjustmentPageState extends State<AddBooleanAdjustmentPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBooleanAdjustment() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(context, BooleanAdjustment(name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add On/Off Adjustment'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveBooleanAdjustment),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Adjustment Name',
            border: OutlineInputBorder(),
            hintText: 'Enter Adjustment Name',
          ),
        ),
      ),
    );
  }
}