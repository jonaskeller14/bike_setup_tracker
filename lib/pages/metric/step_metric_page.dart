import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/rating_metric.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/metric_weight_field.dart';
import '../../widgets/set_adjustment/set_step_adjustment.dart';
import 'metric_page.dart';

const int _defaultStep = 1;
const int _defaultMin = 0;
const double _defaultWeight = 1.0;
const StepAdjustmentVisualization _defaultVisualization = StepAdjustmentVisualization.slider;

/// Metric step visualizations are restricted to the dial-free options.
const List<StepAdjustmentVisualization> _metricVisualizations = [
  StepAdjustmentVisualization.slider,
  StepAdjustmentVisualization.minusButtonValuePlusButton,
];

/// Maps any stored visualization (incl. legacy dial variants) onto its
/// dial-free base so the dropdown's value is always one of [_metricVisualizations].
StepAdjustmentVisualization _normalizeVisualization(StepAdjustmentVisualization? v) {
  return switch (v) {
    StepAdjustmentVisualization.minusButtonValuePlusButton ||
    StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial ||
    StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial =>
      StepAdjustmentVisualization.minusButtonValuePlusButton,
    StepAdjustmentVisualization.slider ||
    StepAdjustmentVisualization.sliderWithClockwiseDial ||
    StepAdjustmentVisualization.sliderWithCounterclockwiseDial ||
    null =>
      StepAdjustmentVisualization.slider,
  };
}

class StepMetricPage extends StatefulWidget {
  final RatingMetric? metric;
  final MetricPageMode mode;

  const StepMetricPage._({
    super.key,
    this.metric,
    required this.mode,
  });

  factory StepMetricPage.add({Key? key}) =>
      StepMetricPage._(key: key, mode: MetricPageMode.add);

  factory StepMetricPage.edit({Key? key, required RatingMetric metric}) =>
      StepMetricPage._(key: key, metric: metric, mode: MetricPageMode.edit);

  factory StepMetricPage.duplicate({Key? key, required RatingMetric metric}) =>
      StepMetricPage._(key: key, metric: metric, mode: MetricPageMode.duplicate);

  factory StepMetricPage.template({Key? key, required RatingMetric metric}) =>
      StepMetricPage._(key: key, metric: metric, mode: MetricPageMode.template);

  @override
  State<StepMetricPage> createState() => _StepMetricPageState();
}

class _StepMetricPageState extends State<StepMetricPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _stepController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _weightController;
  late StepAdjustmentVisualization visualization;

  late StepAdjustment? _initialAdj;
  late double _initialWeight;
  late StepAdjustmentVisualization _initialVisualization;

  late double _previewValue;
  late StepAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _initialAdj = widget.metric?.adjustment as StepAdjustment?;
    _initialWeight = widget.metric?.weight ?? _defaultWeight;
    _initialVisualization = _normalizeVisualization(_initialAdj?.visualization);

    _nameController = TextEditingController(text: _initialAdj?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: _initialAdj?.notes);
    _notesController.addListener(_changeListener);
    _stepController = TextEditingController(text: _initialAdj?.step.toString() ?? _defaultStep.toString());
    _stepController.addListener(_changeListener);
    _minController = TextEditingController(text: _initialAdj?.min.toString() ?? _defaultMin.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: _initialAdj?.max.toString());
    _maxController.addListener(_changeListener);
    _weightController = TextEditingController(text: MetricWeightField.formatWeight(_initialWeight));
    _weightController.addListener(_changeListener);
    visualization = _initialVisualization;

    _previewAdjustment = _initialAdj ?? StepAdjustment(
      name: '',
      notes: null,
      unit: null,
      step: _defaultStep,
      min: _defaultMin,
      max: 5,
      visualization: _defaultVisualization,
    );
    _previewValue = _previewAdjustment.min.toDouble();
    if (widget.mode != MetricPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (_initialAdj?.name ?? '') ||
        _notesController.text.trim() != (_initialAdj?.notes ?? '') ||
        int.tryParse(_stepController.text.trim()) != (_initialAdj?.step ?? _defaultStep) ||
        int.tryParse(_minController.text.trim()) != (_initialAdj?.min ?? _defaultMin) ||
        int.tryParse(_maxController.text.trim()) != _initialAdj?.max ||
        visualization != _initialVisualization ||
        (double.tryParse(_weightController.text.trim()) ?? _initialWeight) != _initialWeight;

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
    _weightController.removeListener(_changeListener);
    _weightController.dispose();
    super.dispose();
  }

  void _saveMetric() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final step = int.parse(_stepController.text.trim());
    final min = int.parse(_minController.text.trim());
    final max = int.parse(_maxController.text.trim());
    final weight = double.parse(_weightController.text.trim());
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, RatingMetric(
      adjustment: StepAdjustment(
        id: widget.mode == MetricPageMode.edit ? _initialAdj!.id : null,
        name: name,
        notes: notes.isEmpty ? null : notes,
        unit: _initialAdj?.unit,
        step: step,
        min: min,
        max: max,
        visualization: visualization,
      ),
      weight: weight,
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

  StepAdjustment _composePreview() {
    final step = _validateStep(_stepController.text) == null
        ? int.parse(_stepController.text.trim())
        : _defaultStep;
    final min = _validateMin(_minController.text) == null
        ? int.parse(_minController.text.trim())
        : _defaultMin;
    final typedMax = int.tryParse(_maxController.text.trim());
    final lowestValidMax = min + step;
    final max = (typedMax != null && typedMax >= lowestValidMax) ? typedMax : lowestValidMax;

    final notes = _notesController.text.trim();
    return StepAdjustment(
      id: _previewAdjustment.id,
      name: _nameController.text.trim(),
      notes: notes.isEmpty ? null : notes,
      unit: _initialAdj?.unit,
      step: step,
      min: min,
      max: max,
      visualization: visualization,
    );
  }

  /// Recomputes the preview from the fields. [resetValue] re-seeds the preview
  /// value to `min` whenever the range (step/min/max) changes, keeping it within
  /// the slider's valid bounds.
  void _updatePreview({bool resetValue = false}) {
    setState(() {
      _previewAdjustment = _composePreview();
      if (resetValue) _previewValue = _previewAdjustment.min.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            MetricPageMode.add ||
            MetricPageMode.duplicate ||
            MetricPageMode.template => const Text('Add Step Metric'),
            MetricPageMode.edit => const Text('Edit Step Metric'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveMetric),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: MetricWeightField(controller: _weightController),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                onChanged: (_) => _updatePreview(),
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                autofocus: widget.mode == MetricPageMode.add,
                                decoration: InputDecoration(
                                  labelText: 'Metric Name',
                                  hintText: 'Enter Metric Name',
                                  border: const OutlineInputBorder(),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && _nameController.text.trim() != _initialAdj?.name,
                                ),
                                validator: validateMetricName,
                              ),
                              const SizedBox(height: 16),
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
                                  prefixIcon: const Icon(StepAdjustment.iconData),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && int.tryParse(_stepController.text.trim()) != _initialAdj?.step,
                                ),
                                validator: _validateStep,
                                onChanged: (_) => _updatePreview(resetValue: true),
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
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && int.tryParse(_minController.text.trim()) != _initialAdj?.min,
                                ),
                                validator: _validateMin,
                                onChanged: (_) => _updatePreview(resetValue: true),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _maxController,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))],
                                decoration: InputDecoration(
                                  labelText: 'Max Value',
                                  hintText: 'Enter maximum value',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vertical_align_top),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && int.tryParse(_maxController.text.trim()) != _initialAdj?.max,
                                ),
                                validator: _validateMax,
                                onChanged: (_) => _updatePreview(resetValue: true),
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
                                        hintText: "Choose a visualization for this metric",
                                        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                        filled: widget.mode == MetricPageMode.edit && visualization != _initialVisualization,
                                      ),
                                      items: _metricVisualizations.map((v) {
                                        return DropdownMenuItem<StepAdjustmentVisualization>(
                                          value: v,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              if (v == StepAdjustmentVisualization.slider)
                                                const Icon(Icons.linear_scale),
                                              if (v == StepAdjustmentVisualization.minusButtonValuePlusButton)
                                                const Icon(Icons.exposure_plus_1),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(v.value)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (StepAdjustmentVisualization? newVisualization) {
                                        if (newVisualization == null) return;
                                        visualization = newVisualization;
                                        _updatePreview();
                                        _changeListener();
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Visualization cannot be empty';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _notesController,
                                      minLines: 2,
                                      maxLines: null,
                                      onChanged: (_) => _updatePreview(),
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: InputDecoration(
                                        labelText: 'Notes (optional)',
                                        hintText: 'Enter measuring procedure/instrument/...',
                                        helperText: _notesController.text.trim().isEmpty ? null : "View these notes by tapping the ⓘ icon next to the name.",
                                        border: const OutlineInputBorder(),
                                        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                        filled: widget.mode == MetricPageMode.edit && _notesController.text.trim() != (_initialAdj?.notes ?? ""),
                                      ),
                                    ),
                                  ],
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
              CollapsibleMetricPreview(
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
