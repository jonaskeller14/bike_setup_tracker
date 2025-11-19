import '../../models/adjustment.dart';
import 'package:flutter/material.dart';


class AddCategoricalAdjustmentPage extends StatefulWidget {
  const AddCategoricalAdjustmentPage({super.key});

  @override
  State<AddCategoricalAdjustmentPage> createState() => _AddCategoricalAdjustmentPageState();
}

class _AddCategoricalAdjustmentPageState extends State<AddCategoricalAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _optionControllers = [TextEditingController()];

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionField(int index) {
    if (_optionControllers.length == 1) return; // keep at least one field
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  bool _hasDuplicateOptions(List<String> options) {
    final seen = <String>{};
    for (final option in options) {
      if (seen.contains(option)) return true;
      seen.add(option);
    }
    return false;
  }

  String? _validateOptions() {
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    if (options.isEmpty) return 'At least one option is required.';
    if (_hasDuplicateOptions(options)) return 'Options must be unique.';
    return null;
  }

  void _saveCategoricalAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    Navigator.pop(
      context,
      CategoricalAdjustment(name: name, unit: null, options: options),
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
        title: const Text('Add Categorical Adjustment'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveCategoricalAdjustment),
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
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Name',
                    hintText: 'Enter Adjustment Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Name is required'
                          : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Options',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _addOptionField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(_optionControllers.length, (index) {
                    final controller = _optionControllers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Option ${index + 1}',
                                hintText: 'Enter option value',
                                border: const OutlineInputBorder(),
                                errorText: _validateOptions(),
                              ),
                              // Individual field validator
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Option is required';
                                }
                                if (_hasDuplicateOptions(_optionControllers
                                    .map((c) => c.text.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList())) {
                                  return 'Options must be unique';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_optionControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              tooltip: 'Remove option',
                              onPressed: () => _removeOptionField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
