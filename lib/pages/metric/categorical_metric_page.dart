import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/rating_metric.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/metric_weight_field.dart';
import '../../widgets/set_adjustment/set_categorical_adjustment.dart';
import 'metric_page.dart';

class CategoricalMetricPage extends StatefulWidget {
  final RatingMetric? metric;
  final MetricPageMode mode;

  const CategoricalMetricPage._({
    super.key,
    this.metric,
    required this.mode,
  });

  factory CategoricalMetricPage.add({Key? key}) =>
      CategoricalMetricPage._(key: key, mode: MetricPageMode.add);

  factory CategoricalMetricPage.edit({Key? key, required RatingMetric metric}) =>
      CategoricalMetricPage._(key: key, metric: metric, mode: MetricPageMode.edit);

  factory CategoricalMetricPage.duplicate({Key? key, required RatingMetric metric}) =>
      CategoricalMetricPage._(key: key, metric: metric, mode: MetricPageMode.duplicate);

  factory CategoricalMetricPage.template({Key? key, required RatingMetric metric}) =>
      CategoricalMetricPage._(key: key, metric: metric, mode: MetricPageMode.template);

  @override
  State<CategoricalMetricPage> createState() => _CategoricalMetricPageState();
}

class _CategoricalMetricPageState extends State<CategoricalMetricPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late List<TextEditingController> _optionControllers;
  late Set<String> _initialOptions;

  late CategoricalAdjustment? _initialAdj;
  late double _weight; // inert (categorical metrics are not scored), preserved as-is

  bool _multiSelect = false;
  bool _counted = false;
  List<String>? _previewValues;
  late CategoricalAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _initialAdj = widget.metric?.adjustment as CategoricalAdjustment?;
    _weight = widget.metric?.weight ?? 1.0;
    _multiSelect = _initialAdj?.multiSelect ?? false;
    _counted = _initialAdj?.counted ?? false;

    _nameController = TextEditingController(text: _initialAdj?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: _initialAdj?.notes);
    _notesController.addListener(_changeListener);
    if (_initialAdj == null) {
      _optionControllers = [TextEditingController()];
    } else {
      _optionControllers = _initialAdj!.options.map((option) => TextEditingController(text: option)).toList();
    }
    for (final optionController in _optionControllers) {
      optionController.addListener(_changeListener);
    }
    _initialOptions = _initialAdj?.options.toSet() ?? {};

    _previewAdjustment = _initialAdj ?? _composePreview();
    if (widget.mode != MetricPageMode.add) _expanded = true;
  }

  CategoricalAdjustment _composePreview() {
    final notes = _notesController.text.trim();
    return CategoricalAdjustment(
      name: _nameController.text.trim(),
      notes: notes.isEmpty ? null : notes,
      unit: _initialAdj?.unit,
      options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
      multiSelect: _multiSelect,
      counted: _counted,
    );
  }

  void _changeListener() {
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet();

    final hasChanges = _nameController.text.trim() != (_initialAdj?.name ?? '') ||
        _notesController.text.trim() != (_initialAdj?.notes ?? '') ||
        _multiSelect != (_initialAdj?.multiSelect ?? false) ||
        _counted != (_initialAdj?.counted ?? false) ||
        !setEquals(_initialOptions, options);
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
    for (final c in _optionControllers) {
      c.removeListener(_changeListener);
      c.dispose();
    }
    super.dispose();
  }

  void _addOptionField() {
    setState(() {
      final newController = TextEditingController();
      newController.addListener(_changeListener);
      _optionControllers.add(newController);
      _previewValues = null;
      _previewAdjustment = _composePreview();
    });
  }

  void _removeOptionField(int index) {
    if (_optionControllers.length == 1) return; // keep at least one field
    setState(() {
      _optionControllers[index].removeListener(_changeListener);
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _previewValues = null;
      _previewAdjustment = _composePreview();
    });
  }

  bool _hasDuplicateOptions(List<String> options) {
    final seen = <String>{};
    for (final option in options) {
      if (seen.contains(option)) return true;
      seen.add(option);
    }
    return false;
  }

  String? _validateOptions() {
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (options.isEmpty) return 'At least one option is required.';
    if (_hasDuplicateOptions(options)) return 'Options must be unique.';
    return null;
  }

  String? _validateOption(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Option is required';
    }
    if (_hasDuplicateOptions(_optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList())) {
      return 'Options must be unique';
    }
    return null;
  }

  void _saveMetric() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, RatingMetric(
      adjustment: CategoricalAdjustment(
        id: widget.mode == MetricPageMode.edit ? _initialAdj!.id : null,
        name: name,
        notes: notes.isEmpty ? null : notes,
        unit: _initialAdj?.unit,
        options: options,
        multiSelect: _multiSelect,
        counted: _counted,
      ),
      weight: _weight,
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
    final appSettings = context.watch<AppSettings>();
    return PopScope(
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            MetricPageMode.add ||
            MetricPageMode.duplicate ||
            MetricPageMode.template => const Text('Add Categorical Metric'),
            MetricPageMode.edit => const Text('Edit Categorical Metric'),
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
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: MetricWeightField(scored: false),
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
                                    _previewAdjustment = _composePreview();
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Options',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextButton.icon(
                                    onPressed: _addOptionField,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add'),
                                  ),
                                ],
                              ),
                              if (widget.mode == MetricPageMode.edit && !_initialOptions.every((option) => _optionControllers.map((c) => c.text.trim()).contains(option))) ...[
                                ListTile(
                                  leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                                  title: Text(
                                    'WARNING: Renaming an option will not update existing values!',
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                const SizedBox(height: 8),
                              ],
                              const SizedBox(height: 8),
                              Column(
                                children: List.generate(_optionControllers.length, (index) {
                                  final controller = _optionControllers[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller,
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            decoration: InputDecoration(
                                              labelText: 'Option ${index + 1}',
                                              hintText: 'Enter option value',
                                              border: const OutlineInputBorder(),
                                              errorText: _validateOptions(),
                                              fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                              filled: widget.mode == MetricPageMode.edit && !(_initialAdj?.options.contains(controller.text.trim()) ?? false),
                                            ),
                                            validator: _validateOption,
                                            onChanged: (String value) {
                                              setState(() {
                                                _previewValues = null;
                                                _previewAdjustment = _composePreview();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_optionControllers.length > 1)
                                          IconButton(
                                            icon: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.error),
                                            tooltip: 'Remove option',
                                            onPressed: () => _removeOptionField(index),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              if (appSettings.enableMultiSelect || _multiSelect)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  tileColor: widget.mode == MetricPageMode.edit && _multiSelect != (_initialAdj?.multiSelect ?? false)
                                      ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                                      : null,
                                  title: const Text('Multi Select'),
                                  subtitle: const Text('Allow more than one selection'),
                                  value: _multiSelect,
                                  onChanged: (bool? newValue) {
                                    if (newValue == null) return;
                                    setState(() {
                                      _multiSelect = newValue;
                                      _previewValues = null;
                                      _previewAdjustment = _composePreview();
                                    });
                                    _changeListener();
                                  },
                                ),
                              if (appSettings.enableCountedSelect || _counted)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  tileColor: widget.mode == MetricPageMode.edit && _counted != (_initialAdj?.counted ?? false)
                                      ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
                                      : null,
                                  title: const Text('Count Occurrences'),
                                  subtitle: const Text('Allow the same option multiple times'),
                                  value: _counted,
                                  onChanged: (bool? newValue) {
                                    if (newValue == null) return;
                                    setState(() {
                                      _counted = newValue;
                                      _previewValues = null;
                                      _previewAdjustment = _composePreview();
                                    });
                                    _changeListener();
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
                                    TextFormField(
                                      controller: _notesController,
                                      minLines: 2,
                                      maxLines: null,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _previewAdjustment = _composePreview();
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
                  child: SetCategoricalAdjustmentWidget(
                    key: ValueKey(_previewAdjustment),
                    adjustment: _previewAdjustment,
                    initialValue: null,
                    value: _previewValues,
                    onChanged: (List<String>? newValue) {
                      setState(() {
                        _previewValues = newValue;
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
