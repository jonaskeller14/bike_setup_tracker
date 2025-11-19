import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class AddNumericalAdjustmentPage extends StatefulWidget {
  const AddNumericalAdjustmentPage({super.key});

  @override
  State<AddNumericalAdjustmentPage> createState() => _AddNumericalAdjustmentPageState();
}

class _AddNumericalAdjustmentPageState extends State<AddNumericalAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final unitText = _unitController.text.trim();

    final min = minText.isNotEmpty ? double.tryParse(minText) : null;
    final max = maxText.isNotEmpty ? double.tryParse(maxText) : null;
    final unit = unitText.isNotEmpty ? unitText : null;

    Navigator.pop(context, NumericalAdjustment(name: name, min: min, max: max, unit: unit));
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateMin(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final v = double.tryParse(value);
    if (v == null) return 'Valid number required';
    return null;
  }

  String? _validateMax(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final v = double.tryParse(value);
    final minText = _minController.text.trim();
    final min = minText.isNotEmpty ? double.tryParse(minText) : null;
    if (v == null) return 'Valid number required';
    if (min != null && v <= min) return 'Max must be greater than min';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Numerical Adjustment'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNumericalAdjustment),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Name',
                    hintText: 'Enter Adjustment Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                // Min value
                TextFormField(
                  controller: _minController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Min Value (optional)',
                    hintText: 'Enter minimum value',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateMin,
                ),
                const SizedBox(height: 12),
                // Max value
                TextFormField(
                  controller: _maxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Max Value (optional)',
                    hintText: 'Enter maximum value',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateMax,
                ),
                const SizedBox(height: 12),
                // Unit
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    hintText: 'Enter unit (e.g., mm, psi)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
