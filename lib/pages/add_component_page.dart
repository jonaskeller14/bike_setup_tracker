import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
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
      MaterialPageRoute(builder: (context) => const BooleanAdjustmentPage()),
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
      MaterialPageRoute(builder: (context) => const NumericalAdjustmentPage()),
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
      MaterialPageRoute(builder: (context) => const StepAdjustmentPage()),
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
      MaterialPageRoute(builder: (context) => const CategoricalAdjustmentPage()),
    );
    if (adjustment != null) {
      setState(() {
        adjustments.add(adjustment);
      });
    }
  }

  Future<void> _editAdjustment(Adjustment adjustment) async {
    if (adjustment is BooleanAdjustment) {
      return _editBooleanAdjustment(adjustment);
    } else if (adjustment is CategoricalAdjustment) {
      return _editCategoricalAdjustment(adjustment);
    } else if (adjustment is StepAdjustment) {
      return _editStepAdjustment(adjustment);
    } else if (adjustment is NumericalAdjustment) {
      return _editNumericalAdjustment(adjustment);
    }
  }

  Future<void> _editBooleanAdjustment(BooleanAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<BooleanAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => BooleanAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
  }

  Future<void> _editStepAdjustment(StepAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<StepAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => StepAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
  }
  
  Future<void> _editCategoricalAdjustment(CategoricalAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<CategoricalAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoricalAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
  }

  Future<void> _editNumericalAdjustment(NumericalAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<NumericalAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => NumericalAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
  }

  Future<void> removeAdjustment(Adjustment adjustment) async { //TODO Remove Adjustment in HomePage by supply RemoveAdjustment Function as argument
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
                      editAdjustment: _editAdjustment,
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
