import 'package:flutter/services.dart';
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

class AddNumericalAdjustmentPage extends StatefulWidget {
  const AddNumericalAdjustmentPage({super.key});

  @override
  State<AddNumericalAdjustmentPage> createState() => _AddNumericalAdjustmentPageState();
}

class _AddNumericalAdjustmentPageState extends State<AddNumericalAdjustmentPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();


  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _saveNumericalAdjustment() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final unitText = _unitController.text.trim();

    final min = minText.isNotEmpty ? double.tryParse(minText) : null;
    final max = maxText.isNotEmpty ? double.tryParse(maxText) : null;
    final unit = unitText.isNotEmpty ? unitText : null;

    Navigator.pop(
      context,
      NumericalAdjustment(name: name, min: min, max: max, unit: unit),
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
        title: const Text('Add On/Off Adjustment'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNumericalAdjustment),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter Adjustment Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),],
                decoration: const InputDecoration(
                  labelText: 'Min Value (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter minimum value',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),],
                decoration: const InputDecoration(
                  labelText: 'Max Value (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter maximum value',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter unit (e.g., mm, psi)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}