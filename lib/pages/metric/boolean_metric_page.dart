import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/rating_metric.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/metric_weight_field.dart';
import '../../widgets/set_adjustment/set_boolean_adjustment.dart';
import 'metric_page.dart';

const double _defaultWeight = 1.0;

class BooleanMetricPage extends StatefulWidget {
  final RatingMetric? metric;
  final MetricPageMode mode;

  const BooleanMetricPage._({
    super.key,
    this.metric,
    required this.mode,
  });

  factory BooleanMetricPage.add({Key? key}) =>
      BooleanMetricPage._(key: key, mode: MetricPageMode.add);

  factory BooleanMetricPage.edit({Key? key, required RatingMetric metric}) =>
      BooleanMetricPage._(key: key, metric: metric, mode: MetricPageMode.edit);

  factory BooleanMetricPage.duplicate({Key? key, required RatingMetric metric}) =>
      BooleanMetricPage._(key: key, metric: metric, mode: MetricPageMode.duplicate);

  factory BooleanMetricPage.template({Key? key, required RatingMetric metric}) =>
      BooleanMetricPage._(key: key, metric: metric, mode: MetricPageMode.template);

  @override
  State<BooleanMetricPage> createState() => _BooleanMetricPageState();
}

class _BooleanMetricPageState extends State<BooleanMetricPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _weightController;

  late BooleanAdjustment? _initialAdj;
  late double _initialWeight;

  bool? _previewValue = false;
  late BooleanAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _initialAdj = widget.metric?.adjustment as BooleanAdjustment?;
    _initialWeight = widget.metric?.weight ?? _defaultWeight;

    _nameController = TextEditingController(text: _initialAdj?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: _initialAdj?.notes);
    _notesController.addListener(_changeListener);
    _weightController = TextEditingController(text: MetricWeightField.formatWeight(_initialWeight));
    _weightController.addListener(_changeListener);

    _previewAdjustment = _initialAdj ?? BooleanAdjustment(
      name: '',
      notes: null,
      unit: null,
    );
    if (widget.mode != MetricPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (_initialAdj?.name ?? '') ||
        _notesController.text.trim() != (_initialAdj?.notes ?? '') ||
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
    final weight = double.parse(_weightController.text.trim());
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, RatingMetric(
      adjustment: BooleanAdjustment(
        id: widget.mode == MetricPageMode.edit ? _initialAdj!.id : null,
        name: name,
        notes: notes.isEmpty ? null : notes,
        unit: _initialAdj?.unit,
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
            MetricPageMode.template => const Text('Add On/Off Metric'),
            MetricPageMode.edit => const Text('Edit On/Off Metric'),
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
                                onChanged: (String newValue) {
                                  setState(() {
                                    _previewAdjustment = BooleanAdjustment(
                                      name: newValue,
                                      notes: _previewAdjustment.notes,
                                      unit: null,
                                    );
                                  });
                                },
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
                                    TextFormField(
                                      controller: _notesController,
                                      minLines: 2,
                                      maxLines: null,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _previewAdjustment = BooleanAdjustment(
                                            name: _previewAdjustment.name,
                                            notes: (value == null || value.isEmpty) ? null : value,
                                            unit: null,
                                          );
                                        });
                                      },
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
                  child: SetBooleanAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: false,
                    value: _previewValue,
                    onChanged: (bool? newValue) {
                      unawaited(HapticFeedback.lightImpact());
                      setState(() {
                        _previewValue = newValue ?? false;
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
