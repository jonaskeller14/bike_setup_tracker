import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_step_adjustment.dart';
import 'adjustment_page.dart';

const int _defaultStep = 1;
const int _defaultMin = 0;
const StepAdjustmentVisualization _defaultVisualization = StepAdjustmentVisualization.slider;

class StepAdjustmentPage extends StatefulWidget {
  final StepAdjustment? adjustment;
  final AdjustmentPageMode mode;

  const StepAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
  });

  factory StepAdjustmentPage.add({Key? key}) =>
      StepAdjustmentPage._(key: key, mode: AdjustmentPageMode.add);

  factory StepAdjustmentPage.edit({Key? key, required StepAdjustment adjustment}) =>
      StepAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit);

  factory StepAdjustmentPage.duplicate({Key? key, required StepAdjustment adjustment}) =>
      StepAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate);

  factory StepAdjustmentPage.template({Key? key, required StepAdjustment adjustment}) =>
      StepAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template);

  @override
  State<StepAdjustmentPage> createState() => _StepAdjustmentPageState();
}

class _StepAdjustmentPageState extends State<StepAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _stepController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late StepAdjustmentVisualization visualization;

  late double _previewValue;
  late StepAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    _stepController = TextEditingController(text: widget.adjustment?.step.toString() ?? _defaultStep.toString());
    _stepController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min.toString() ?? _defaultMin.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max.toString());
    _maxController.addListener(_changeListener);
    visualization = widget.adjustment?.visualization ?? _defaultVisualization;

    _previewAdjustment = widget.adjustment ?? StepAdjustment(
      name: '',
      notes: null,
      unit: null,
      step: _defaultStep,
      min: _defaultMin,
      max: 5,
      visualization: _defaultVisualization,
    );
    _previewValue = _previewAdjustment.min.toDouble();
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') ||
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        int.tryParse(_stepController.text.trim()) != (widget.adjustment?.step ?? _defaultStep) ||
        int.tryParse(_minController.text.trim()) != (widget.adjustment?.min ?? _defaultMin) ||
        int.tryParse(_maxController.text.trim()) != widget.adjustment?.max ||
        visualization != (widget.adjustment?.visualization ?? _defaultVisualization);

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
    _notesController.removeListener(_changeListener);
    _notesController.dispose();
    _stepController.removeListener(_changeListener);
    _stepController.dispose();
    _minController.removeListener(_changeListener);
    _minController.dispose();
    _maxController.removeListener(_changeListener);
    _maxController.dispose();
    super.dispose();
  }

  void _saveStepAdjustment() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final step = int.parse(_stepController.text.trim());
    final min = int.parse(_minController.text.trim());
    final max = int.parse(_maxController.text.trim());
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, StepAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name,
      notes: notes.isEmpty ? null : notes,
      unit: widget.adjustment?.unit,
      step: step,
      min: min,
      max: max,
      visualization: visualization,
    ));
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
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
          title: switch (widget.mode) {
            AdjustmentPageMode.add ||
            AdjustmentPageMode.duplicate ||
            AdjustmentPageMode.template => const Text('Add Step Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Step Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveStepAdjustment),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
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
                                  notes: _previewAdjustment.notes,
                                  min: _previewAdjustment.min,
                                  max: _previewAdjustment.max,
                                  step: _previewAdjustment.step,
                                  unit: null,
                                  visualization: _previewAdjustment.visualization,
                                );
                              });
                            },
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofocus: widget.mode == AdjustmentPageMode.add,
                            decoration: InputDecoration(
                              labelText: 'Adjustment Name',
                              hintText: 'Enter Adjustment Name',
                              border: const OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.mode == AdjustmentPageMode.edit && _nameController.text.trim() != widget.adjustment?.name,
                            ),
                            validator: validateAdjustmentName,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _stepController,
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Step',
                              hintText: 'Enter step value',
                              border: const OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.mode == AdjustmentPageMode.edit && int.tryParse(_stepController.text.trim()) != widget.adjustment?.step,
                            ),
                            validator: _validateStep,
                            onChanged: (String value) {
                              setState(() {
                                final newStep = _validateStep(value) == null ? int.parse(value) : _defaultStep;
                                _previewAdjustment = StepAdjustment(
                                  name: _previewAdjustment.name,
                                  notes: _previewAdjustment.notes,
                                  min: _previewAdjustment.min,
                                  max: math.max(_previewAdjustment.max, _previewAdjustment.min + newStep),
                                  step: newStep,
                                  unit: null,
                                  visualization: _previewAdjustment.visualization,
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
                            decoration: InputDecoration(
                              labelText: 'Min Value',
                              hintText: 'Enter minimum value',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.vertical_align_bottom),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.mode == AdjustmentPageMode.edit && int.tryParse(_minController.text.trim()) != widget.adjustment?.min,
                            ),
                            validator: _validateMin,
                            onChanged: (String value) {
                              setState(() {
                                final newMin = _validateMin(value) == null ? int.parse(value) : _defaultMin;
                                _previewAdjustment = StepAdjustment(
                                  name: _previewAdjustment.name,
                                  notes: _previewAdjustment.notes,
                                  min: math.min(newMin, _previewAdjustment.max - _previewAdjustment.step), 
                                  max: _previewAdjustment.max, //FIXME: if previously max was set wrong and now with the new min it becomes valid -> it does not update here 
                                  step: _previewAdjustment.step, 
                                  unit: null,
                                  visualization: _previewAdjustment.visualization,
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
                            decoration: InputDecoration(
                              labelText: 'Max Value',
                              hintText: 'Enter maximum value',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.vertical_align_top),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.mode == AdjustmentPageMode.edit && int.tryParse(_maxController.text.trim()) != widget.adjustment?.max,
                            ),
                            validator: _validateMax,
                            onChanged: (String value) {
                              setState(() {
                                final newMax = _validateMax(value) == null ? int.parse(value) : _previewAdjustment.min + _previewAdjustment.step;
                                _previewAdjustment = StepAdjustment(
                                  name: _previewAdjustment.name,
                                  notes: _previewAdjustment.notes,
                                  min: _previewAdjustment.min,
                                  max: math.max(newMax, _previewAdjustment.min + _previewAdjustment.step),
                                  step: _previewAdjustment.step,
                                  unit: null,
                                  visualization: _previewAdjustment.visualization,
                                );
                                _previewValue = _previewAdjustment.min.toDouble();
                              });
                            },
                          ),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _expanded = !_expanded),
                              icon: Icon(_expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              ),
                              label: Text(_expanded
                                  ? "Hide Additional Fields"
                                  : "Show Additional Fields"
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _expanded,
                            maintainState: true,
                            child: Column(
                              children: [
                                DropdownButtonFormField<StepAdjustmentVisualization>(
                                  initialValue: visualization,
                                  isExpanded: true,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  hint: const Text("Please select visualization"),
                                  decoration: InputDecoration(
                                    labelText: 'Visualization',
                                    border: const OutlineInputBorder(),
                                    hintText: "Choose a visualization for this adjustment",
                                    fillColor: Colors.orange.withValues(alpha: 0.08),
                                    filled: widget.mode == AdjustmentPageMode.edit && visualization != widget.adjustment?.visualization,
                                  ),
                                  items: StepAdjustmentVisualization.values.map((v) {
                                    return DropdownMenuItem<StepAdjustmentVisualization>(
                                      value: v,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          if (v == StepAdjustmentVisualization.slider)
                                            const Icon(Icons.linear_scale),
                                          if (v == StepAdjustmentVisualization.sliderWithClockwiseDial) ...[
                                            const Icon(Icons.linear_scale),
                                            const Icon(Icons.rotate_right),
                                          ],
                                          if (v == StepAdjustmentVisualization.sliderWithCounterclockwiseDial) ...[
                                            const Icon(Icons.linear_scale),
                                            const Icon(Icons.rotate_left),
                                          ],
                                          if (v == StepAdjustmentVisualization.minusButtonValuePlusButton)
                                            const Icon(Icons.exposure_plus_1),
                                          if (v == StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial) ...[
                                            const Icon(Icons.exposure_plus_1),
                                            const Icon(Icons.rotate_right),
                                          ],
                                          if (v == StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial) ...[
                                            const Icon(Icons.exposure_plus_1),
                                            const Icon(Icons.rotate_left),
                                          ],
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(v.value)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (StepAdjustmentVisualization? newVisualization) {
                                    if (newVisualization == null) return;
                                    setState(() {
                                      visualization = newVisualization;
                                      _previewAdjustment = StepAdjustment(
                                        name: _previewAdjustment.name,
                                        notes: _previewAdjustment.notes,
                                        min: _previewAdjustment.min,
                                        max: _previewAdjustment.max,
                                        step: _previewAdjustment.step,
                                        unit: _previewAdjustment.unit,
                                        visualization: newVisualization,
                                      );
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
                                TextFormField(
                                  controller: _notesController,
                                  minLines: 2,
                                  maxLines: null,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _previewAdjustment = StepAdjustment(
                                        name: _previewAdjustment.name,
                                        notes: (value == null || value.isEmpty) ? null : value,
                                        min: _previewAdjustment.min,
                                        max: _previewAdjustment.max,
                                        step: _previewAdjustment.step,
                                        unit: _previewAdjustment.unit,
                                        visualization: _previewAdjustment.visualization,
                                      );
                                    });
                                  },
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    hintText: 'Enter measuring procedure/instrument/...',
                                    helperText: _notesController.text.trim().isEmpty ? null : "View these notes by tapping the ⓘ icon next to the name.",
                                    border: const OutlineInputBorder(),
                                    fillColor: Colors.orange.withValues(alpha: 0.08),
                                    filled: widget.mode == AdjustmentPageMode.edit && _notesController.text.trim() != (widget.adjustment?.notes ?? ""),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CollapsibleAdjustmentPreview(
                child: Card(
                  child: SetStepAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: 0.0,
                    value: _previewValue,
                    onChanged: (double? newValue) {
                      unawaited(HapticFeedback.lightImpact());
                      setState(() {
                        _previewValue = newValue ?? _previewAdjustment.min.toDouble();
                      });
                    },
                    onChangedEnd: (_) => {},
                    highlighting: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
