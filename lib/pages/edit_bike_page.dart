import 'package:flutter/material.dart';
import '../models/bike.dart';


class EditBikePage extends StatefulWidget {
  final Bike bike;

  const EditBikePage({super.key, required this.bike});

  @override
  State<EditBikePage> createState() => _EditBikePageState();
}

class _EditBikePageState extends State<EditBikePage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bike.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBike() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(context, Bike(id: widget.bike.id, name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Bike'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveBike),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
