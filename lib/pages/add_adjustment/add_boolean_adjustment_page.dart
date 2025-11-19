import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class AddBooleanAdjustmentPage extends StatefulWidget {
  const AddBooleanAdjustmentPage({super.key});

  @override
  State<AddBooleanAdjustmentPage> createState() => _AddBooleanAdjustmentPageState();
}

class _AddBooleanAdjustmentPageState extends State<AddBooleanAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBooleanAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    Navigator.pop(context, BooleanAdjustment(name: name, unit: null));
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
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
        title: const Text('Add On/Off Adjustment'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveBooleanAdjustment),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
