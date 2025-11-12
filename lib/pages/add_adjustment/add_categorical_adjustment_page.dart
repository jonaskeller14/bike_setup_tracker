import '../../models/adjustment.dart';
import 'package:flutter/material.dart';


class AddCategoricalAdjustmentPage extends StatefulWidget {
  const AddCategoricalAdjustmentPage({super.key});

  @override
  State<AddCategoricalAdjustmentPage> createState() => _AddCategoricalAdjustmentPageState();
}

class _AddCategoricalAdjustmentPageState extends State<AddCategoricalAdjustmentPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _optionControllers = [TextEditingController()];

  bool _showNameError = false;
  bool _showOptionsError = false;

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
      _showOptionsError = false;
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

  void _saveCategoricalAdjustment() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    if (options.isEmpty || _hasDuplicateOptions(options)) {
      setState(() => _showOptionsError = true);
      return;
    }
      
    Navigator.pop(context, CategoricalAdjustment(name: name, options: options));
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _showOptionsError ? Colors.red : Colors.grey,
                                  width: _showOptionsError ? 2 : 1,
                                ),
                              ),
                            hintText: 'Enter option value',
                            errorText: _showOptionsError ? 'At least one option is required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // show remove button when more than one field
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
    );
  }
}
