import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';

class StepAdjustmentPage extends StatefulWidget {
  final StepAdjustment? adjustment;
  const StepAdjustmentPage({super.key, this.adjustment});

  @override
  State<StepAdjustmentPage> createState() => _StepAdjustmentPageState();
}

class _StepAdjustmentPageState extends State<StepAdjustmentPage> {
  static const int _DEFAULT_STEP = 1;
  static const int _DEFAULT_MIN = 0;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _stepController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _stepController = TextEditingController(text: widget.adjustment?.step.toString() ?? _DEFAULT_STEP.toString());
    _stepController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min.toString() ?? _DEFAULT_MIN.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max.toString());
    _maxController.addListener(_changeListener);
  }

  void _changeListener() {
    final nameHasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '');
    final stepHasChanges = int.tryParse(_stepController.text.trim()) != (widget.adjustment?.step ?? _DEFAULT_STEP);
    final minHasChanges = int.tryParse(_minController.text.trim()) != (widget.adjustment?.min ?? _DEFAULT_MIN);
    final maxHasChanges = int.tryParse(_maxController.text.trim()) != (widget.adjustment?.max);
    final hasChanges = nameHasChanges || stepHasChanges || minHasChanges || maxHasChanges;
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
    _stepController.removeListener(_changeListener);
    _stepController.dispose();
    _minController.removeListener(_changeListener);
    _minController.dispose();
    _maxController.removeListener(_changeListener);
    _maxController.dispose();
    super.dispose();
  }

  void _saveStepAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final step = int.parse(_stepController.text.trim());
    final min = int.parse(_minController.text.trim());
    final max = int.parse(_maxController.text.trim());
    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, StepAdjustment(name: name, unit: null, step: step, min: min, max: max));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.min = min;
      widget.adjustment!.max = max;
      Navigator.pop(context, widget.adjustment);
    }
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

  String? _validateStep(String? value) {
    if (value == null || value.trim().isEmpty) return 'Step is required';
    final v = int.tryParse(value);
    if (v == null || v <= 0) return 'Valid step greater than zero is required';
    return null;
  }

  String? _validateMin(String? value) {
    if (value == null || value.trim().isEmpty) return 'Min is required';
    final v = int.tryParse(value);
    if (v == null) return 'Valid min value is required';
    return null;
  }

  String? _validateMax(String? value) {
    if (value == null || value.trim().isEmpty) return 'Max is required';
    final v = int.tryParse(value);
    final minValue = int.tryParse(_minController.text.trim());
    final stepValue = int.tryParse(_stepController.text.trim());
    if (v == null) return 'Valid max value is required';
    if (minValue != null && v <= minValue) return 'Max must be greater than min';
    if (minValue != null && stepValue != null && minValue + stepValue > v) return "Max must be greater than min+step ";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.adjustment == null ? const Text('Add Step Adjustment') : const Text('Edit Step Adjustment'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveStepAdjustment),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    autofocus: widget.adjustment == null,
                    decoration: const InputDecoration(
                      labelText: 'Adjustment Name',
                      hintText: 'Enter Adjustment Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stepController,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Step',
                      hintText: 'Enter step value',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateStep,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _minController,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
                    decoration: const InputDecoration(
                      labelText: 'Min Value',
                      hintText: 'Enter minimum value',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateMin,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxController,
                    onFieldSubmitted: (_) => _saveStepAdjustment(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
                    decoration: const InputDecoration(
                      labelText: 'Max Value',
                      hintText: 'Enter maximum value',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateMax,
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
