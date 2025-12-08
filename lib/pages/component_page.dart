import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';
import '../widgets/dialogs/discard_changes.dart';

class ComponentPage extends StatefulWidget {
  final Component? component;
  final List<Bike> bikes;

  const ComponentPage({super.key, this.component, required this.bikes});

  @override
  State<ComponentPage> createState() => _ComponentPageState();
}

class _ComponentPageState extends State<ComponentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late List<Adjustment> adjustments;
  late List<Adjustment> _initialAdjustments;
  late Bike bike;
  late ComponentType? componentType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.component?.name);
    _nameController.addListener(_changeListener);
    adjustments = widget.component == null ? [] : List.from(widget.component!.adjustments);
    _initialAdjustments = List.from(adjustments);
    bike = widget.component?.bike ?? widget.bikes.first;
    componentType = widget.component?.componentType;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.component?.name ?? '') || 
        bike != (widget.component?.bike ?? widget.bikes.first) || 
        componentType != widget.component?.componentType;
        _initialAdjustments.length != adjustments.length || 
        adjustments.asMap().entries.any((entry) => entry.value != _initialAdjustments[entry.key]);

    if (_formHasChanges != hasChanges) {
      setState(() {
        _formHasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_changeListener);
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
    _changeListener();
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
    _changeListener();
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
    _changeListener();
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
    _changeListener();
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
    _changeListener();
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) return;
    if (adjustments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You need to add at least one adjustment"), 
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 2),
      ));
      return;
    }
    final name = _nameController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(
      context,
      Component(
        id: widget.component?.id,
        name: name,
        componentType: componentType!,
        bike: bike,
        adjustments: adjustments,
      ),
    );
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  Widget _buildGuideRow(IconData icon, String type, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.3),
                children: [
                  TextSpan(
                    text: "$type: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  TextSpan(
                    text: example,
                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.component == null ? const Text('Add Component') : const Text('Edit Component'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveComponent),
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    autofocus: widget.component == null,
                    decoration: const InputDecoration(
                      labelText: 'Component Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter component name',
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Bike>(
                    initialValue: bike,
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Bike',
                      border: OutlineInputBorder(),
                      hintText: "Choose a bike for this component",
                    ),
                    items: widget.bikes.map((b) {
                      return DropdownMenuItem<Bike>(
                        value: b,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          spacing: 8,
                          children: [
                            const Icon(Icons.pedal_bike),
                            Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis))
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Bike? newBike) {
                      if (newBike == null) return;
                      setState(() {
                        bike = newBike;
                      });
                      _changeListener();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ComponentType>(
                    initialValue: componentType,
                    isExpanded: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    hint: const Text("Please select type"),
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      hintText: "Choose a type for this component",
                    ),
                    items: ComponentType.values.map((componentType) {
                      return DropdownMenuItem<ComponentType>(
                        value: componentType,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Component.getIcon(componentType),
                            Expanded(child: Text(componentType.value, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (ComponentType? newComponentType) {
                      if (newComponentType == null) return;
                      setState(() {
                        componentType = newComponentType;
                      });
                      _changeListener();
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Component type cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.add),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            const Text('Add Numerical Adjustment'),
                            Container(height: 20, width: 1, color: Theme.of(context).colorScheme.surfaceDim),
                            Icon(Icons.speed, size: 18),
                          ],
                        ),
                        onPressed: _addNumericalAdjustment,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            const Text('Add Step Adjustment'),
                            Container(height: 20, width: 1, color: Theme.of(context).colorScheme.surfaceDim),
                            Icon(Icons.stairs_outlined, size: 18),
                          ],
                        ),
                        onPressed: _addStepAdjustment,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            const Text('Add Categorical Adjustment'),
                            Container(height: 20, width: 1, color: Theme.of(context).colorScheme.surfaceDim),
                            Icon(Icons.category, size: 18),
                          ],
                        ),
                        onPressed: _addCategoricalAdjustment,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            const Text('Add On/Off Adjustment'),
                            Container(height: 20, width: 1, color: Theme.of(context).colorScheme.surfaceDim),
                            Icon(Icons.toggle_on, size: 18),
                          ],
                        ),
                        onPressed: _addBooleanAdjustment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  adjustments.isNotEmpty 
                      ? AdjustmentEditList(
                          adjustments: adjustments,
                          editAdjustment: _editAdjustment,
                          removeAdjustment: removeAdjustment,
                          onReorderAdjustments: (List<Adjustment> tmpAdjustments) {
                            setState(() {
                              adjustments = tmpAdjustments;
                            });
                            _changeListener();
                          },
                        ) 
                      : Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.help_outline, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    "No adjustments yet",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                      fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Define what settings you can tweak on this component by tapping the buttons above.",
                                style: TextStyle(height: 1.4, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Examples:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              _buildGuideRow(Icons.speed, "Numerical", "Pressure (psi/bar), Length, Angle, Weight"),
                              _buildGuideRow(Icons.rotate_right, "Step", "Rebound/Compression Clicks, Spacers"),
                              _buildGuideRow(Icons.category, "Categorical", "Tire Compound (Soft/Hard), Model, Brand"),
                              _buildGuideRow(Icons.toggle_on, "On/Off", "Lockout Lever, Climb Switch, Tire insert installed?"),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
