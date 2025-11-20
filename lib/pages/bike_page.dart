import 'package:flutter/material.dart';
import '../models/bike.dart';

class BikePage extends StatefulWidget {
  final Bike? bike;

  const BikePage({super.key, this.bike});

  @override
  State<BikePage> createState() => _BikePageState();
}

class _BikePageState extends State<BikePage> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bike?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBike() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (widget.bike == null) {
      Navigator.pop(context, Bike(name: name));
    } else {
      Navigator.pop(context, Bike(id: widget.bike!.id, name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.bike == null ? const Text('Add Bike') : const Text('Edit Bike'),
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
