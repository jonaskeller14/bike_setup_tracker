import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import 'add_adjustment/add_boolean_adjustment_page.dart';
import 'add_adjustment/add_numerical_adjustment_page.dart';
import 'add_adjustment/add_step_adjustment_page.dart';
import 'add_adjustment/add_categorical_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';

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

  Future<void> _addStepAdjustment() async {
    final adjustment = await Navigator.push<StepAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const AddStepAdjustmentPage()),
    );
    if (adjustment != null) {
      setState(() {
        adjustments.add(adjustment);
      });
    }
  }

  Future<void> _addCategoricalAdjustment() async {
    final adjustment = await Navigator.push<CategoricalAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const AddCategoricalAdjustmentPage()),
    );
    if (adjustment != null) {
      setState(() {
        adjustments.add(adjustment);
      });
    }
  }

  Future<void> removeAdjustment(Adjustment adjustment) async {
    setState(() {
      adjustments.remove(adjustment);
    });
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ActionChip(
                  avatar: Icon(Icons.add),
                  label: const Text('Add On/Off Adjustment'),
                  onPressed: _addBooleanAdjustment,
                ),
                ActionChip(
                  avatar: Icon(Icons.add),
                  label: const Text('Add Categorical Adjustment'),
                  onPressed: _addCategoricalAdjustment,
                ),
                ActionChip(
                  avatar: Icon(Icons.add),
                  label: const Text('Add Step Adjustment'),
                  onPressed: _addStepAdjustment,
                ),
                ActionChip(
                  avatar: Icon(Icons.add),
                  label: const Text('Add Numerical Adjustment'),
                  onPressed: _addNumericalAdjustment,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Adjustments list
            Expanded(
              child: adjustments.isEmpty
                  ? Center(
                      child: Text(
                        'No adjustments yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : AdjustmentEditList(
                      adjustments: adjustments,
                      // editAdjustment: () => {},
                      removeAdjustment: removeAdjustment,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
