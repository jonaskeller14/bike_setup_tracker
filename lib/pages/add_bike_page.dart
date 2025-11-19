import 'package:flutter/material.dart';
import '../models/bike.dart';

class AddBikePage extends StatefulWidget {
  const AddBikePage({super.key});

  @override
  State<AddBikePage> createState() => _AddBikePageState();
}

class _AddBikePageState extends State<AddBikePage> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBike() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    Navigator.pop(context, Bike(name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Bike'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveBike),
        ],
      ),
      body: Padding(
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
                  labelText: 'Bike Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter bike name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a bike name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
