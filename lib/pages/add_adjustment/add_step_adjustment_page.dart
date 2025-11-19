import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class AddStepAdjustmentPage extends StatefulWidget {
  const AddStepAdjustmentPage({super.key});

  @override
  State<AddStepAdjustmentPage> createState() => _AddStepAdjustmentPageState();
}

class _AddStepAdjustmentPageState extends State<AddStepAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stepController = TextEditingController(text: '1');
  final TextEditingController _minController = TextEditingController(text: '0');
  final TextEditingController _maxController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _stepController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _saveStepAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final step = int.parse(_stepController.text.trim());
    final min = int.parse(_minController.text.trim());
    final max = int.parse(_maxController.text.trim());

    Navigator.pop(
      context,
      StepAdjustment(name: name, unit: null, step: step, min: min, max: max),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateStep(String? value) {
    if (value == null || value.trim().isEmpty) return 'Step is required';
    final v = int.tryParse(value);
    if (v == null || v <= 0) return 'Valid step greater than zero is required';
    return null;
  }

  String? _validateMin(String? value) {
    if (value == null || value.trim().isEmpty) return 'Min is required';
    final v = int.tryParse(value);
    if (v == null) return 'Valid min value is required';
    return null;
  }

  String? _validateMax(String? value) {
    if (value == null || value.trim().isEmpty) return 'Max is required';
    final v = int.tryParse(value);
    final minValue = int.tryParse(_minController.text.trim());
    if (v == null) return 'Valid max value is required';
    if (minValue != null && v <= minValue) return 'Max must be greater than min';
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
        title: const Text('Add Step Adjustment'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveStepAdjustment),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Adjustment Name
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
                // Step
                TextFormField(
                  controller: _stepController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Step',
                    hintText: 'Enter step value',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateStep,
                ),
                const SizedBox(height: 12),
                // Min
                TextFormField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
                  decoration: const InputDecoration(
                    labelText: 'Min Value',
                    hintText: 'Enter minimum value',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateMin,
                ),
                const SizedBox(height: 12),
                // Max
                TextFormField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
                  decoration: const InputDecoration(
                    labelText: 'Max Value',
                    hintText: 'Enter maximum value',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateMax,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
