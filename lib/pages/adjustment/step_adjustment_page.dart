import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class StepAdjustmentPage extends StatefulWidget {
  final StepAdjustment? adjustment;
  const StepAdjustmentPage({super.key, this.adjustment});

  @override
  State<StepAdjustmentPage> createState() => _StepAdjustmentPageState();
}

class _StepAdjustmentPageState extends State<StepAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _stepController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _stepController = TextEditingController(text: widget.adjustment?.step.toString() ?? '1');
    _minController = TextEditingController(text: widget.adjustment?.min.toString() ?? '0');
    _maxController = TextEditingController(text: widget.adjustment?.max.toString());
  }

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
    if (!mounted) return;
    Navigator.pop(
      context,
      StepAdjustment(id: widget.adjustment?.id, name: name, unit: null, step: step, min: min, max: max),
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
        title: widget.adjustment == null ? const Text('Add Step Adjustment') : const Text('Edit Step Adjustment'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  onEditingComplete: _saveStepAdjustment,
                  autofocus: widget.adjustment == null,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Name',
                    hintText: 'Enter Adjustment Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stepController,
                  onEditingComplete: _saveStepAdjustment,
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
                TextFormField(
                  controller: _minController,
                  onEditingComplete: _saveStepAdjustment,
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
                TextFormField(
                  controller: _maxController,
                  onEditingComplete: _saveStepAdjustment,
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
