import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/rating_metric.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/metric_weight_field.dart';
import '../../widgets/set_adjustment/set_duration_adjustment.dart';
import '../../widgets/sheets/set_duration.dart';
import 'metric_page.dart';

/// Duration metrics default to a negative weight (lower lap time is better).
const double _defaultWeight = -1.0;

class DurationMetricPage extends StatefulWidget {
  final RatingMetric? metric;
  final MetricPageMode mode;

  const DurationMetricPage._({
    super.key,
    this.metric,
    required this.mode,
  });

  factory DurationMetricPage.add({Key? key}) =>
      DurationMetricPage._(key: key, mode: MetricPageMode.add);

  factory DurationMetricPage.edit({Key? key, required RatingMetric metric}) =>
      DurationMetricPage._(key: key, metric: metric, mode: MetricPageMode.edit);

  factory DurationMetricPage.duplicate({Key? key, required RatingMetric metric}) =>
      DurationMetricPage._(key: key, metric: metric, mode: MetricPageMode.duplicate);

  factory DurationMetricPage.template({Key? key, required RatingMetric metric}) =>
      DurationMetricPage._(key: key, metric: metric, mode: MetricPageMode.template);

  @override
  State<DurationMetricPage> createState() => _DurationMetricPageState();
}

class _DurationMetricPageState extends State<DurationMetricPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _weightController;

  final FocusNode _minFocusNode = FocusNode(canRequestFocus: false);
  final FocusNode _maxFocusNode = FocusNode(canRequestFocus: false);

  late DurationAdjustment? _initialAdj;
  late double _initialWeight;

  Duration _previewValue = Duration.zero;
  late DurationAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _initialAdj = widget.metric?.adjustment as DurationAdjustment?;
    _initialWeight = widget.metric?.weight ?? _defaultWeight;

    _nameController = TextEditingController(text: _initialAdj?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: _initialAdj?.notes);
    _notesController.addListener(_changeListener);
    _minController = TextEditingController(text: _initialAdj?.min == null ? null : Adjustment.formatValue(_initialAdj?.min));
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: _initialAdj?.max == null ? null : Adjustment.formatValue(_initialAdj?.max));
    _maxController.addListener(_changeListener);
    _weightController = TextEditingController(text: MetricWeightField.formatWeight(_initialWeight));
    _weightController.addListener(_changeListener);

    _previewAdjustment = _initialAdj ?? DurationAdjustment(
      name: '',
      notes: null,
      unit: null,
    );
    _previewValue = _previewAdjustment.min ?? Duration.zero;
    if (widget.mode != MetricPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (_initialAdj?.name ?? '') ||
        _notesController.text.trim() != (_initialAdj?.notes ?? '') ||
        _previewAdjustment.min != _initialAdj?.min ||
        _previewAdjustment.max != _initialAdj?.max ||
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
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
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
      adjustment: DurationAdjustment(
        id: widget.mode == MetricPageMode.edit ? _initialAdj!.id : null,
        name: name,
        notes: notes.isEmpty ? null : notes,
        min: _previewAdjustment.min,
        max: _previewAdjustment.max,
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

  String? _validateMin(String? _) {
    if (_previewAdjustment.min == null) return 'Min is required';
    return null;
  }

  String? _validateMax(String? _) {
    if (_previewAdjustment.max == null) return 'Max is required';
    final min = _previewAdjustment.min;
    if (min != null && _previewAdjustment.max! <= min) return 'Max must be greater than min';
    return null;
  }

  void _updatePreview({required Duration? min, required Duration? max}) {
    final notes = _notesController.text.trim();
    setState(() {
      _previewAdjustment = DurationAdjustment(
        id: _previewAdjustment.id,
        name: _nameController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        unit: _previewAdjustment.unit,
        min: min,
        max: max,
      );
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
            MetricPageMode.template => const Text('Add Duration Metric'),
            MetricPageMode.edit => const Text('Edit Duration Metric'),
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
                                onChanged: (_) => _updatePreview(
                                  min: _previewAdjustment.min,
                                  max: _previewAdjustment.max,
                                ),
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
                                readOnly: true,
                                enableInteractiveSelection: false,
                                focusNode: _minFocusNode,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  showSetDurationSheet(
                                    context: context,
                                    adjustment: DurationAdjustment(name: 'Min', notes: null, unit: null, max: _previewAdjustment.max),
                                    value: _previewAdjustment.min,
                                    onChanged: (Duration newValue) {
                                      _minController.text = Adjustment.formatValue(newValue);
                                      _updatePreview(min: newValue, max: _previewAdjustment.max);
                                    }
                                  );
                                },
                                decoration: InputDecoration(
                                  labelText: 'Min Duration',
                                  hintText: 'Select minimum duration',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vertical_align_bottom),
                                  suffixIcon: _minController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _minController.clear();
                                            _updatePreview(min: null, max: _previewAdjustment.max);
                                          },
                                        )
                                      : null,
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && _previewAdjustment.min != _initialAdj?.min,
                                ),
                                validator: _validateMin,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _maxController,
                                readOnly: true,
                                enableInteractiveSelection: false,
                                focusNode: _maxFocusNode,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  showSetDurationSheet(
                                    context: context,
                                    adjustment: DurationAdjustment(name: 'Max', notes: null, unit: null, min: _previewAdjustment.min),
                                    value: _previewAdjustment.max,
                                    onChanged: (Duration newValue) {
                                      _maxController.text = Adjustment.formatValue(newValue);
                                      _updatePreview(min: _previewAdjustment.min, max: newValue);
                                    }
                                  );
                                },
                                decoration: InputDecoration(
                                  labelText: 'Max Duration',
                                  hintText: 'Select maximum duration',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.vertical_align_top),
                                  suffixIcon: _maxController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _maxController.clear();
                                            _updatePreview(min: _previewAdjustment.min, max: null);
                                          },
                                        )
                                      : null,
                                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                  filled: widget.mode == MetricPageMode.edit && _previewAdjustment.max != _initialAdj?.max,
                                ),
                                validator: _validateMax,
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
                                    TextFormField(
                                      controller: _notesController,
                                      minLines: 2,
                                      maxLines: null,
                                      onChanged: (_) => _updatePreview(
                                        min: _previewAdjustment.min,
                                        max: _previewAdjustment.max,
                                      ),
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
                  child: SetDurationAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: Duration.zero,
                    value: _previewValue,
                    onChanged: (Duration? newValue) {
                      setState(() {
                        _previewValue = newValue ?? Duration.zero;
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
