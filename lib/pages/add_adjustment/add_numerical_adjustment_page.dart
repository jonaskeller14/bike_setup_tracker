import 'package:flutter/services.dart';
import '../../models/adjustment.dart';
import 'package:flutter/material.dart';


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

  bool _showNameError = false;
  bool _showMinError = false;
  bool _showMaxError = false;

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
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    final minText = _minController.text.trim();
    final min = minText.isNotEmpty ? double.tryParse(minText) : null;
    

    final maxText = _maxController.text.trim();
    final max = maxText.isNotEmpty ? double.tryParse(maxText) : null;
    
    if (min != null && max != null && max <= min) {
      setState(() => _showMaxError = true);
      return;
    }

    final unitText = _unitController.text.trim();
    final unit = unitText.isNotEmpty ? unitText : null;

    Navigator.pop(context, NumericalAdjustment(name: name, min: min, max: max, unit: unit));
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
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                onChanged: (_) {
                  if (_showNameError && _nameController.text.isNotEmpty) {
                    setState(() => _showNameError = false);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Adjustment Name',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _showNameError ? Colors.red : Colors.grey,
                      width: _showNameError ? 2 : 1,
                    ),
                  ),
                  hintText: 'Enter Adjustment Name',
                  errorText: _showNameError ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minController,
                onChanged: (_) {
                  if (_showMinError && _minController.text.isNotEmpty) {
                    setState(() => _showMinError = false);
                  }
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),],
                decoration: InputDecoration(
                  labelText: 'Min Value (optional)',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _showMinError ? Colors.red : Colors.grey,
                      width: _showMinError ? 2 : 1,
                    ),
                  ),
                  hintText: 'Enter minimum value',
                  errorText: _showMinError ? 'Valid min value is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxController,
                onChanged: (_) {
                  if (_showMaxError && _maxController.text.isNotEmpty) {
                    setState(() => _showMaxError = false);
                  }
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),],
                decoration: InputDecoration(
                  labelText: 'Max Value (optional)',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _showMaxError ? Colors.red : Colors.grey,
                      width: _showMaxError ? 2 : 1,
                    ),
                  ),
                  hintText: 'Enter maximum value',
                  errorText: _showMaxError ? 'Valid max value greater than min value is required' : null,
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
