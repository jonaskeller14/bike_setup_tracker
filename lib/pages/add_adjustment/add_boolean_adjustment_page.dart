import 'package:flutter/services.dart';
import '../../models/adjustment.dart';
import 'package:flutter/material.dart';


class AddBooleanAdjustmentPage extends StatefulWidget {
  const AddBooleanAdjustmentPage({super.key});

  @override
  State<AddBooleanAdjustmentPage> createState() => _AddBooleanAdjustmentPageState();
}

class _AddBooleanAdjustmentPageState extends State<AddBooleanAdjustmentPage> {
  final TextEditingController _nameController = TextEditingController();

  bool _showNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBooleanAdjustment() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

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
            ],
          ),
        ),
      ),
    );
  }
}
