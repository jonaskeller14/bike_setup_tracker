import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/adjustment/adjustment.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import 'adjustment/text_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/component_add_adjustment.dart';

class ComponentPage extends StatefulWidget {
  final Component? component;
  final Map<String, Bike> bikes;

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
  late String bike;
  late ComponentType? componentType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.component?.name);
    _nameController.addListener(_changeListener);
    adjustments = widget.component == null ? [] : List.from(widget.component!.adjustments);
    _initialAdjustments = List.from(adjustments);
    bike = widget.component?.bike ?? widget.bikes.keys.first;
    componentType = widget.component?.componentType;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.component?.name ?? '') || 
        bike != (widget.component?.bike ?? widget.bikes.keys.first) || 
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
    if (adjustment == null) return;
    setState(() {
      adjustments.add(adjustment);
    });
    _changeListener();
  }

  Future<void> _addNumericalAdjustment() async {
    final adjustment = await Navigator.push<NumericalAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const NumericalAdjustmentPage()),
    );
    if (adjustment == null) return;
    setState(() {
      adjustments.add(adjustment);
    });
    _changeListener();
  }

  Future<void> _addStepAdjustment() async {
    final adjustment = await Navigator.push<StepAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const StepAdjustmentPage()),
    );
    if (adjustment == null) return;
    setState(() {
      adjustments.add(adjustment);
    });
    _changeListener();
  }

  Future<void> _addCategoricalAdjustment() async {
    final adjustment = await Navigator.push<CategoricalAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const CategoricalAdjustmentPage()),
    );
    if (adjustment == null) return;
    setState(() {
      adjustments.add(adjustment);
    });
    _changeListener();
  }

  Future<void> _addTextAdjustment() async {
    final adjustment = await Navigator.push<TextAdjustment>(
      context,
      MaterialPageRoute(builder: (context) => const TextAdjustmentPage()),
    );
    if (adjustment == null) return;
    setState(() {
      adjustments.add(adjustment);
    });
    _changeListener();
  }

  Future<void> _addAdjustmentFromPreset(Adjustment adjustment) async {
    final newAdjustment = await _editAdjustment(adjustment.deepCopy());
    if (newAdjustment == null) return;
    setState(() {
      adjustments.add(newAdjustment);
    });
    _changeListener();
  }

  Future<Adjustment?> _editAdjustment(Adjustment adjustment) async {
    if (adjustment is BooleanAdjustment) {
      return await _editBooleanAdjustment(adjustment);
    } else if (adjustment is CategoricalAdjustment) {
      return _editCategoricalAdjustment(adjustment);
    } else if (adjustment is StepAdjustment) {
      return await _editStepAdjustment(adjustment);
    } else if (adjustment is NumericalAdjustment) {
      return await _editNumericalAdjustment(adjustment);
    } else if (adjustment is TextAdjustment) {
      return await _editTextAdjustment(adjustment);
    }
    return null;
  }

  Future<Adjustment?> _editBooleanAdjustment(BooleanAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<BooleanAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => BooleanAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return null;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
    if (widget.component != null) widget.component!.lastModified = DateTime.now();
    return editedAdjustment;
  }

  Future<Adjustment?> _editStepAdjustment(StepAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<StepAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => StepAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return null;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
    if (widget.component != null) widget.component!.lastModified = DateTime.now();
    return editedAdjustment;
  }

  Future<Adjustment?> _editCategoricalAdjustment(CategoricalAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<CategoricalAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoricalAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return null;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
    if (widget.component != null) widget.component!.lastModified = DateTime.now();
    return editedAdjustment;
  }

  Future<Adjustment?> _editNumericalAdjustment(NumericalAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<NumericalAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => NumericalAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return null;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
    if (widget.component != null) widget.component!.lastModified = DateTime.now();
    return editedAdjustment;
  }

  Future<Adjustment?> _editTextAdjustment(TextAdjustment adjustment) async {
    final editedAdjustment = await Navigator.push<TextAdjustment>(
      context,
      MaterialPageRoute(
        builder: (context) => TextAdjustmentPage(adjustment: adjustment)
      ),
    );
    if (editedAdjustment == null) return null;
    setState(() {
      final index = adjustments.indexOf(adjustment);
      if (index != -1) {
        adjustments[index] = editedAdjustment;
      }
    });
    if (widget.component != null) widget.component!.lastModified = DateTime.now();
    return editedAdjustment;
  }

  Future<void> removeAdjustment(Adjustment adjustment) async {
    setState(() {
      adjustments.remove(adjustment);
    });
    _changeListener();
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) return;
    if (adjustments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("You need to add at least one adjustment", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
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
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13, height: 1.3),
                children: [
                  TextSpan(
                    text: "$type: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  TextSpan(
                    text: example,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontStyle: FontStyle.italic)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _onReorderAdjustments(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    setState(() {
      final adjustment = adjustments.removeAt(oldIndex);
      adjustments.insert(adjustedNewIndex, adjustment);
    });
    _changeListener();
  }

  Widget _emptyAdjustmentsInfo() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              "No adjustments yet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Define what settings you can tweak on this component by tapping the button below.",
          style: TextStyle(height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        Text(
          "Examples:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 4),
        _buildGuideRow(Icons.speed, "Numerical", "Pressure (psi/bar), Length, Angle, Weight"),
        _buildGuideRow(Icons.rotate_right, "Step", "Rebound/Compression Clicks, Spacers"),
        _buildGuideRow(Icons.category, "Categorical", "Tire Compound (Soft/Hard), Model, Brand"),
        _buildGuideRow(Icons.toggle_on, "On/Off", "Lockout Lever, Climb Switch, Tire insert installed?"),
        if (context.read<AppSettings>().enableTextAdjustment)
          _buildGuideRow(Icons.text_snippet, "Text", "Flexible field for any other setup specifications"),
      ],
    ),
  );

  

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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  autofocus: widget.component == null,
                  decoration: InputDecoration(
                    labelText: 'Component Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter component name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.component != null && _nameController.text.trim() != widget.component?.name,
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Bike>(
                  initialValue: widget.bikes[bike],
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Bike',
                    border: OutlineInputBorder(),
                    hintText: "Choose a bike for this component",
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.component != null && bike != widget.component?.bike,
                  ),
                  validator: (Bike? newBike) {
                    if (newBike == null) return "Bike cannot be empty.";
                    if (!widget.bikes.values.contains(newBike)) return "Please select valid bike";
                    return null;
                  },
                  items: widget.bikes.values.map((b) {
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
                      bike = newBike.id;
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
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    hintText: "Choose a type for this component",
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.component != null && componentType != widget.component?.componentType,
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
                      return 'Component type cannot be empty. You can edit it later.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                adjustments.isNotEmpty
                    ? AdjustmentEditList(
                        adjustments: adjustments,
                        editAdjustment: _editAdjustment,
                        removeAdjustment: removeAdjustment,
                        onReorderAdjustments: _onReorderAdjustments,
                      ) 
                    : _emptyAdjustmentsInfo(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showComponentAddAdjustmentBottomSheet(
                      context: context,
                      componentType: componentType,
                      addAdjustmentFromPreset: _addAdjustmentFromPreset,
                      addNumericalAdjustment: _addNumericalAdjustment,
                      addStepAdjustment: _addStepAdjustment,
                      addCategoricalAdjustment: _addCategoricalAdjustment,
                      addBooleanAdjustment: _addBooleanAdjustment,
                      addTextAdjustment: _addTextAdjustment,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Adjustment"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
