import 'package:flutter/services.dart';
import '../../models/adjustment.dart';
import 'package:flutter/material.dart';


class AddStepAdjustmentPage extends StatefulWidget {
  const AddStepAdjustmentPage({super.key});

  @override
  State<AddStepAdjustmentPage> createState() => _AddStepAdjustmentPageState();
}

class _AddStepAdjustmentPageState extends State<AddStepAdjustmentPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stepController = TextEditingController(text: '1');
  final TextEditingController _minController = TextEditingController(text: '0');
  final TextEditingController _maxController = TextEditingController();
  
  bool _showNameError = false;
  bool _showStepError = false;
  bool _showMinError = false;
  bool _showMaxError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stepController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _saveStepAdjustment() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    final minText = _minController.text.trim();
    final min = minText.isNotEmpty ? int.tryParse(minText) : null;
    if (minText.isEmpty || min == null) {
      setState(() => _showMinError = true);
      return;
    }

    final maxText = _maxController.text.trim();
    final max = maxText.isNotEmpty ? int.tryParse(maxText) : null;
    if (maxText.isEmpty || max == null || max <= min) {
      setState(() => _showMaxError = true);
      return;
    }

    final stepText = _stepController.text.trim();
    final step = stepText.isNotEmpty ? int.tryParse(stepText) : null;
    if (stepText.isEmpty || step == null || step <= 0) {
      setState(() => _showStepError = true);
      return;
    }
    
    Navigator.pop(context, StepAdjustment(name: name, unit: null, step: step, min: min, max: max));
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
                controller: _stepController,
                onChanged: (_) {
                  if (_showStepError && _stepController.text.isNotEmpty) {
                    setState(() => _showStepError = false);
                  }
                },
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Step',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _showStepError ? Colors.red : Colors.grey,
                      width: _showStepError ? 2 : 1,
                    ),
                  ),
                  hintText: 'Enter step value',
                  errorText: _showStepError ? 'Valid step greater than zero is required' : null,
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
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),],
                decoration: InputDecoration(
                  labelText: 'Min Value',
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
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),],
                decoration: InputDecoration(
                  labelText: 'Max Value',
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
            ],
          ),
        ),
      ),
    );
  }
}
