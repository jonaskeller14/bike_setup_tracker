import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import 'add_adjustment/add_boolean_adjustment_page.dart';
import 'add_adjustment/add_numerical_adjustment_page.dart';
import 'add_adjustment/add_step_adjustment_page.dart';
import 'add_adjustment/add_categorical_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';

class AddComponentPage extends StatefulWidget {
  final List<Bike> bikes;

  const AddComponentPage({super.key, required this.bikes});

  @override
  State<AddComponentPage> createState() => _AddComponentPageState();
}

class _AddComponentPageState extends State<AddComponentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<Adjustment> adjustments = [];
  late Bike bike;

  @override
  void initState() {
    super.initState();
    bike = widget.bikes.first;
  }

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
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    Navigator.pop(
      context,
      Component(
        name: name,
        bike: bike,
        adjustments: adjustments,
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
        title: const Text('Add Component'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveComponent),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Component Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter component name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Component name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Bike>(
                initialValue: bike,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bike',
                  border: OutlineInputBorder(),
                  hintText: "Choose a bike for this component",
                ),
                items: widget.bikes.map((b) {
                  return DropdownMenuItem<Bike>(
                    value: b,
                    child: Text(b.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (Bike? newBike) {
                  if (newBike == null) return;
                  setState(() {
                    bike = newBike;
                  });
                },
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
      ),
    );
  }
}
