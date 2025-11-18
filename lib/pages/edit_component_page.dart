import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/adjustment.dart';


class EditComponentPage extends StatefulWidget {
  final Component component;

  const EditComponentPage({super.key, required this.component});

  @override
  State<EditComponentPage> createState() => _EditComponentPageState();
}

class _EditComponentPageState extends State<EditComponentPage> {
  late TextEditingController _nameController;
  late List<Adjustment> adjustments;

  @override
  void initState() {
    super.initState();
    // Initialize with existing setting values
    _nameController = TextEditingController(text: widget.component.name);
    adjustments = widget.component.adjustments;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveComponent() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Return updated setting to previous screen
    Navigator.pop(
      context,
      Component(
        id: widget.component.id,
        name: name,
        bike: widget.component.bike,
        adjustments: adjustments,
        currentSetting: widget.component.currentSetting,
      ),
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
        title: const Text('Edit Component'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveComponent),
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
            labelText: 'Component Name',
            border: OutlineInputBorder(),
            hintText: 'Enter component name',
          ),
            ),
            const SizedBox(height: 12),
            // adjustments list
            Expanded(
              child: adjustments.isEmpty
                  ? Center(
                      child: Text(
                        'No adjustments yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: adjustments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final adj = adjustments[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          title: Text(
                            adj.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
