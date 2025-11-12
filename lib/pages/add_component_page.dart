import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import 'add_adjustment_page.dart';


class AddComponentPage extends StatefulWidget {
  const AddComponentPage({super.key});

  @override
  State<AddComponentPage> createState() => _AddComponentPageState();
}

class _AddComponentPageState extends State<AddComponentPage> {
  final TextEditingController _nameController = TextEditingController();
  final List<Adjustment> adjustments = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addBooleanAdjustment() async {
    final adjustment = await Navigator.push<BooleanAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const AddBooleanAdjustmentPage()),
    );
    if (adjustment != null) {
      setState(() {
        adjustments.add(adjustment);
      });
    }
  }

  Future<void> _addNumericalAdjustment() async {
    final adjustment = await Navigator.push<NumericalAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const AddNumericalAdjustmentPage()),
    );
    if (adjustment != null) {
      setState(() {
        adjustments.add(adjustment);
      });
    }
  }

  void _saveComponent() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Return updated setting to previous screen
    Navigator.pop(context, Component(name: name, adjustments: adjustments));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Component'),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "add BooleanAdjustment",
              onPressed: _addBooleanAdjustment,
              tooltip: 'Add On/Off Adjustment',
              label: const Text('Add On/Off Adjustment'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "add CategorialAdjustment",
              onPressed: () => {},
              tooltip: 'Add Categorical Adjustment',
              label: const Text('Add Categorical Adjustment'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "add StepAdjustment",
              onPressed: () => {},
              tooltip: 'Add Step Adjustment',
              label: const Text('Add Step Adjustment'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "add NumericalAdjustment",
              onPressed: _addNumericalAdjustment,
              tooltip: 'Add Numerical Adjustment',
              label: const Text('Add Numerical Adjustment'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
