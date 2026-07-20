import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/rating_metric.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/dialogs/unit_conversion_dialog.dart';
import '../../widgets/metric_weight_field.dart';
import '../../widgets/set_adjustment/set_numerical_adjustment.dart';
import '../../widgets/sheets/unit_picker_sheet.dart';
import 'metric_page.dart';

const double _defaultWeight = 1.0;

class NumericalMetricPage extends StatefulWidget {
  final RatingMetric? metric;
  final MetricPageMode mode;

  const NumericalMetricPage._({
    super.key,
    this.metric,
    required this.mode,
  });

  factory NumericalMetricPage.add({Key? key}) =>
      NumericalMetricPage._(key: key, mode: MetricPageMode.add);

  factory NumericalMetricPage.edit({Key? key, required RatingMetric metric}) =>
      NumericalMetricPage._(key: key, metric: metric, mode: MetricPageMode.edit);

  factory NumericalMetricPage.duplicate({Key? key, required RatingMetric metric}) =>
      NumericalMetricPage._(key: key, metric: metric, mode: MetricPageMode.duplicate);

  factory NumericalMetricPage.template({Key? key, required RatingMetric metric}) =>
      NumericalMetricPage._(key: key, metric: metric, mode: MetricPageMode.template);

  @override
  State<NumericalMetricPage> createState() => _NumericalMetricPageState();
}

class _NumericalMetricPageState extends State<NumericalMetricPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  AdjustmentUnit? _unit;
  late TextEditingController _weightController;

  late NumericalAdjustment? _initialAdj;
  late double _initialWeight;

  String? _previewValue;
  late NumericalAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _initialAdj = widget.metric?.adjustment as NumericalAdjustment?;
    _initialWeight = widget.metric?.weight ?? _defaultWeight;

    _nameController = TextEditingController(text: _initialAdj?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: _initialAdj?.notes);
    _notesController.addListener(_changeListener);
    _minController = TextEditingController(text: _initialAdj?.min == double.infinity || _initialAdj?.min == double.negativeInfinity ? null : _initialAdj?.min.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: _initialAdj?.max == double.infinity || _initialAdj?.max == double.negativeInfinity ? null : _initialAdj?.max.toString());
    _maxController.addListener(_changeListener);
    _unit = _initialAdj?.unit;
    _weightController = TextEditingController(text: MetricWeightField.formatWeight(_initialWeight));
    _weightController.addListener(_changeListener);

    _previewAdjustment = _initialAdj ?? NumericalAdjustment(
      name: '',
      notes: null,
      unit: null,
    );
    if (widget.mode != MetricPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (_initialAdj?.name ?? '') ||
        _notesController.text.trim() != (_initialAdj?.notes ?? '') ||
        _unit != _initialAdj?.unit ||
        (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != (_initialAdj?.min ?? double.negativeInfinity) ||
        (double.tryParse(_maxController.text.trim()) ?? double.infinity) != (_initialAdj?.max ?? double.infinity) ||
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
    _minController.removeListener(_changeListener);
    _minController.dispose();
    _maxController.removeListener(_changeListener);
    _maxController.dispose();
    _weightController.removeListener(_changeListener);
    _weightController.dispose();
    super.dispose();
  }

  void _pickUnit() {
    showUnitPickerSheet(
      context: context,
      current: _unit,
      onSelected: (unit) {
        setState(() {
          _unit = unit;
          _changeListener();
          _updatePreview();
        });
      },
    );
  }

  Future<void> _saveMetric() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();

    final min = double.parse(_minController.text.trim());
    final max = double.parse(_maxController.text.trim());
    final weight = double.parse(_weightController.text.trim());

    // On an edit between two compatible units (same quantity), ask whether to
    // convert existing stored rating-entry values. Min/max are left exactly as
    // typed — only the historical values are rewritten, and only if opted in.
    ValueUnitConversion? conversion;
    final oldUnit = _initialAdj?.unit;
    final newUnit = _unit;
    if (widget.mode == MetricPageMode.edit &&
        oldUnit is KnownUnit &&
        newUnit is KnownUnit &&
        oldUnit != newUnit &&
        oldUnit.quantity == newUnit.quantity) {
      final choice = await showUnitConversionDialog(context, from: oldUnit, to: newUnit);
      if (choice == null) return; // dismissed — stay on the page
      if (choice == UnitEditChoice.convert) {
        conversion = ValueUnitConversion(adjustmentId: _initialAdj!.id, from: oldUnit, to: newUnit);
      }
    }

    _formHasChanges = false;
    if (!mounted) return;
    final metric = RatingMetric(
      adjustment: NumericalAdjustment(
        id: widget.mode == MetricPageMode.edit ? _initialAdj!.id : null,
        name: name,
        notes: notes.isEmpty ? null : notes,
        min: min,
        max: max,
        unit: _unit,
      ),
      weight: weight,
    );
    Navigator.pop(
      context,
      widget.mode == MetricPageMode.edit
          ? EditResult<RatingMetric>(metric, conversions: conversion == null ? const [] : [conversion])
          : metric,
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

  String? _validateMin(String? value) {
    if (value == null || value.trim().isEmpty) return 'Min is required';
    final v = double.tryParse(value);
    if (v == null) return 'Valid number required';
    return null;
  }

  String? _validateMax(String? value) {
    if (value == null || value.trim().isEmpty) return 'Max is required';
    final v = double.tryParse(value);
    if (v == null) return 'Valid number required';
    final minText = _minController.text.trim();
    final min = minText.isNotEmpty ? double.tryParse(minText) : null;
    if (min != null && v <= min) return 'Max must be greater than min';
    return null;
  }

  /// A note shown when the unit is edited: an info hint for compatible units
  /// (values can be converted on save) or a warning for incompatible ones
  /// (numbers are reinterpreted, not converted).
  List<Widget> _unitChangeNotice() {
    if (widget.mode != MetricPageMode.edit) return const [];
    final oldUnit = _initialAdj?.unit;
    final newUnit = _unit;
    if (newUnit == oldUnit) return const [];

    final scheme = Theme.of(context).colorScheme;
    final convertible = oldUnit is KnownUnit &&
        newUnit is KnownUnit &&
        oldUnit.quantity == newUnit.quantity;
    return [
      ListTile(
        leading: Icon(
          convertible ? Icons.swap_horiz : Icons.warning,
          color: convertible ? scheme.primary : scheme.error,
        ),
        title: Text(
          convertible
              ? "You'll be asked whether to convert existing values when saving."
              : 'WARNING: existing values keep their numbers and are reinterpreted in the new unit.',
          style: TextStyle(color: convertible ? scheme.primary : scheme.error),
        ),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 12),
    ];
  }

  NumericalAdjustment _composePreview() {
    final min = _validateMin(_minController.text) == null
        ? double.tryParse(_minController.text.trim())
        : null;
    final max = _validateMax(_maxController.text) == null
        ? double.tryParse(_maxController.text.trim())
        : null;

    final notes = _notesController.text.trim();
    return NumericalAdjustment(
      id: _previewAdjustment.id,
      name: _nameController.text.trim(),
      notes: notes.isEmpty ? null : notes,
      unit: _unit,
      min: min,
      max: max,
    );
  }

  void _updatePreview({bool resetValue = false}) {
    setState(() {
      _previewAdjustment = _composePreview();
      if (resetValue) _previewValue = null;
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
            MetricPageMode.template => const Text('Add Numerical Metric'),
            MetricPageMode.edit => const Text('Edit Numerical Metric'),
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
                                controller: _minController,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Min Value',
                                  hintText: 'Enter minimum value',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vertical_align_bottom),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != _initialAdj?.min,
                                ),
                                validator: _validateMin,
                                onChanged: (_) => _updatePreview(resetValue: true),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _maxController,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Max Value',
                                  hintText: 'Enter maximum value',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vertical_align_top),
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && (double.tryParse(_maxController.text.trim()) ?? double.infinity) != _initialAdj?.max,
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
                                    ..._unitChangeNotice(),
                                    InkWell(
                                      key: const Key('unit_picker_field'),
                                      onTap: _pickUnit,
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Unit (optional)',
                                          hintText: 'Choose a unit',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.straighten),
                                          suffixIcon: _unit != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    setState(() {
                                                      _unit = null;
                                                      _changeListener();
                                                      _updatePreview();
                                                    });
                                                  },
                                                )
                                              : const Icon(Icons.arrow_drop_down),
                                          fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                          filled: widget.mode == MetricPageMode.edit && _unit != _initialAdj?.unit,
                                        ),
                                        child: Text(_unit?.label ?? 'None'),
                                      ),
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
                                        helperMaxLines: 2,
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
                  child: SetNumericalAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: null,
                    value: _previewValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        _previewValue = newValue;
                      });
                    },
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
