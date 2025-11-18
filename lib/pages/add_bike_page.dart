import 'package:flutter/material.dart';
import '../models/bike.dart';

class AddBikePage extends StatefulWidget {
  const AddBikePage({super.key});

  @override
  State<AddBikePage> createState() => _AddBikePageState();
}

class _AddBikePageState extends State<AddBikePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBike() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Bike Name',
                border: OutlineInputBorder(),
                hintText: 'Enter bike name',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
