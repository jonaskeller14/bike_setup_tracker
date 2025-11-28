import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_step_adjustment.dart';

const int _defaultStep = 1;
const int _defaultMin = 0;

class StepAdjustmentPage extends StatefulWidget {
  final StepAdjustment? adjustment;
  const StepAdjustmentPage({super.key, this.adjustment});

  @override
  State<StepAdjustmentPage> createState() => _StepAdjustmentPageState();
}

class _StepAdjustmentPageState extends State<StepAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _stepController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  double _previewValue = _defaultMin.toDouble();
  StepAdjustment _previewAdjustment = StepAdjustment(
    name: '',
    unit: null,
    step: _defaultStep, 
    min: _defaultMin,
    max: 5,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _stepController = TextEditingController(text: widget.adjustment?.step.toString() ?? _defaultStep.toString());
    _stepController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min.toString() ?? _defaultMin.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max.toString());
    _maxController.addListener(_changeListener);
  }

  void _changeListener() {
    final nameHasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '');
    final stepHasChanges = int.tryParse(_stepController.text.trim()) != (widget.adjustment?.step ?? _defaultStep);
    final minHasChanges = int.tryParse(_minController.text.trim()) != (widget.adjustment?.min ?? _defaultMin);
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          onChanged: (String? value) {
                            setState(() {
                              _previewAdjustment = StepAdjustment(
                                name: value ?? '', 
                                min: _previewAdjustment.min, 
                                max: _previewAdjustment.max, 
                                step: _previewAdjustment.step, 
                                unit: null
                              );
                            });
                          },
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
                          onChanged: (String value) {
                            setState(() {
                              final newStep = _validateStep(value) == null ? int.parse(value) : _defaultStep;
                              _previewAdjustment = StepAdjustment(
                                name: _previewAdjustment.name, 
                                min: _previewAdjustment.min, 
                                max: math.max(_previewAdjustment.max, _previewAdjustment.min + newStep), 
                                step: newStep, 
                                unit: null
                              );
                              _previewValue = _previewAdjustment.min.toDouble();
                            });
                          },
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
                          onChanged: (String value) {
                            setState(() {
                              final newMin = _validateMin(value) == null ? int.parse(value) : _defaultMin;
                              _previewAdjustment = StepAdjustment(
                                name: _previewAdjustment.name, 
                                min: math.min(newMin, _previewAdjustment.max - _previewAdjustment.step), 
                                max: _previewAdjustment.max, //FIXME: if previously max was set wrong and now with the new min it becomes valid -> it does not update here 
                                step: _previewAdjustment.step, 
                                unit: null
                              );
                              _previewValue = _previewAdjustment.min.toDouble();
                            });
                          },
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
                          onChanged: (String value) {
                            setState(() {
                              final newMax = _validateMax(value) == null ? int.parse(value) : _previewAdjustment.min+_previewAdjustment.step;
                              _previewAdjustment = StepAdjustment(
                                name: _previewAdjustment.name, 
                                min: _previewAdjustment.min, 
                                max: math.max(newMax, _previewAdjustment.min + _previewAdjustment.step), 
                                step: _previewAdjustment.step, 
                                unit: null
                              );
                              _previewValue = _previewAdjustment.min.toDouble();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                Container(
                  padding: EdgeInsetsGeometry.fromLTRB(16, 32, 16, 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor)), color: Colors.blueGrey.shade100),
                  child: Card(
                    child: SetStepAdjustmentWidget(
                      key: ValueKey(_previewAdjustment),
                      adjustment: _previewAdjustment,
                      initialValue: 0.0,
                      value: _previewValue,
                      onChanged: (double newValue) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _previewValue = newValue;
                        });
                      },
                      onChangedEnd: (_) => {},
                      highlighting: false,
                    ),
                  ),
                ),
                Positioned(
                  top: -1, 
                  left: -1, 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        bottomRight: const Radius.circular(6),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: const Text(
                      'Preview only — changes won’t be saved',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
