import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class BooleanAdjustmentPage extends StatefulWidget {
  final BooleanAdjustment? adjustment;
  const BooleanAdjustmentPage({super.key, this.adjustment});

  @override
  State<BooleanAdjustmentPage> createState() => _BooleanAdjustmentPageState();
}

class _BooleanAdjustmentPageState extends State<BooleanAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBooleanAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, BooleanAdjustment(name: name, unit: null));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.unit = null;
      Navigator.pop(context, widget.adjustment);
    }
    
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
        title: widget.adjustment == null ? const Text('Add On/Off Adjustment') : const Text('Edit On/Off Adjustment'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: widget.adjustment == null,
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
