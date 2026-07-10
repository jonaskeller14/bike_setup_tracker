import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/dialogs/unit_conversion_dialog.dart';
import '../../widgets/set_adjustment/set_numerical_adjustment.dart';
import '../../widgets/sheets/unit_picker_sheet.dart';
import 'adjustment_page.dart';

class NumericalAdjustmentPage extends StatefulWidget {
  final NumericalAdjustment? adjustment;
  final AdjustmentPageMode mode;

  const NumericalAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
  });

  factory NumericalAdjustmentPage.add({Key? key}) =>
      NumericalAdjustmentPage._(key: key, mode: AdjustmentPageMode.add);

  factory NumericalAdjustmentPage.edit({Key? key, required NumericalAdjustment adjustment}) =>
      NumericalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit);

  factory NumericalAdjustmentPage.duplicate({Key? key, required NumericalAdjustment adjustment}) =>
      NumericalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate);

  factory NumericalAdjustmentPage.template({Key? key, required NumericalAdjustment adjustment}) =>
      NumericalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template);

  @override
  State<NumericalAdjustmentPage> createState() => _NumericalAdjustmentPageState();
}

class _NumericalAdjustmentPageState extends State<NumericalAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  AdjustmentUnit? _unit;
  late AdjustmentUnit? _initialUnit;

  String? _previewValue;
  late NumericalAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min == double.infinity || widget.adjustment?.min == double.negativeInfinity ? null : widget.adjustment?.min.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max == double.infinity || widget.adjustment?.max == double.negativeInfinity ? null : widget.adjustment?.max.toString());
    _maxController.addListener(_changeListener);
    _unit = widget.adjustment?.unit;
    _initialUnit = widget.adjustment?.unit;

    _previewAdjustment = widget.adjustment ?? NumericalAdjustment(
      name: '',
      notes: null,
      unit: null,
    );
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') ||
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        _unit != widget.adjustment?.unit ||
        (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != (widget.adjustment?.min ?? double.negativeInfinity) ||
        (double.tryParse(_maxController.text.trim()) ?? double.infinity) != (widget.adjustment?.max ?? double.infinity);
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

  Future<void> _saveNumericalAdjustment() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();

    final min = double.tryParse(minText) ?? double.negativeInfinity;
    final max = double.tryParse(maxText) ?? double.infinity;

    // On an edit between two compatible units (same quantity), ask whether to
    // convert existing stored setup values. Min/max are left exactly as typed —
    // only the historical values are rewritten, and only if the user opts in.
    ValueUnitConversion? conversion;
    final oldUnit = widget.adjustment?.unit;
    final newUnit = _unit;
    if (widget.mode == AdjustmentPageMode.edit &&
        oldUnit is KnownUnit &&
        newUnit is KnownUnit &&
        oldUnit != newUnit &&
        oldUnit.quantity == newUnit.quantity) {
      final choice = await showUnitConversionDialog(context, from: oldUnit, to: newUnit);
      if (choice == null) return; // dismissed — stay on the page
      if (choice == UnitEditChoice.convert) {
        conversion = ValueUnitConversion(adjustmentId: widget.adjustment!.id, from: oldUnit, to: newUnit);
      }
    }

    _formHasChanges = false;
    if (!mounted) return;
    final adjustment = NumericalAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name,
      notes: notes.isEmpty ? null : notes,
      min: min,
      max: max,
      unit: _unit,
    );
    Navigator.pop(
      context,
      widget.mode == AdjustmentPageMode.edit
          ? EditResult<Adjustment>(adjustment, conversions: conversion == null ? const [] : [conversion])
          : adjustment,
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
    if (value == null || value.trim().isEmpty) return null; // optional
    final v = double.tryParse(value);
    if (v == null) return 'Valid number required';
    return null;
  }

  String? _validateMax(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final v = double.tryParse(value);
    final minText = _minController.text.trim();
    final min = minText.isNotEmpty ? double.tryParse(minText) : null;
    if (v == null) return 'Valid number required';
    if (min != null && v < min) return 'Max must be greater than min';
    return null;
  }

  List<Widget> _unitChangeNotice() {
    if (widget.mode != AdjustmentPageMode.edit) return const [];
    final oldUnit = _initialUnit;
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
            AdjustmentPageMode.add ||
            AdjustmentPageMode.duplicate ||
            AdjustmentPageMode.template => const Text('Add Numerical Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Numerical Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveNumericalAdjustment),
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
                            onChanged: (_) => _updatePreview(),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _saveNumericalAdjustment(),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofocus: widget.mode == AdjustmentPageMode.add,
                            decoration: InputDecoration(
                              labelText: 'Adjustment Name',
                              hintText: 'Enter Adjustment Name',
                              border: const OutlineInputBorder(),
                              fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                              filled: widget.mode == AdjustmentPageMode.edit && _nameController.text.trim() != widget.adjustment?.name,
                            ),
                            validator: validateAdjustmentName,
                          ),
                          const SizedBox(height: 12),
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
                                filled: widget.mode == AdjustmentPageMode.edit && _unit != widget.adjustment?.unit,
                              ),
                              child: Text(_unit?.label ?? 'None'),
                            ),
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
                                  controller: _minController,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Min Value (optional)',
                                    hintText: 'Enter minimum value',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.vertical_align_bottom),
                                    suffixIcon: _minController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _minController.clear();
                                              _updatePreview(resetValue: true);
                                            },
                                          )
                                        : null,
                                    fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    filled: widget.mode == AdjustmentPageMode.edit && (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != widget.adjustment?.min,
                                  ),
                                  validator: _validateMin,
                                  onChanged: (_) => _updatePreview(resetValue: true),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _maxController,
                                  onFieldSubmitted: (_) => _saveNumericalAdjustment(),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Max Value (optional)',
                                    hintText: 'Enter maximum value',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.vertical_align_top),
                                    suffixIcon: _maxController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _maxController.clear();
                                              _updatePreview(resetValue: true);
                                            },
                                          )
                                        : null,
                                    fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                    filled: widget.mode == AdjustmentPageMode.edit && (double.tryParse(_maxController.text.trim()) ?? double.infinity) != widget.adjustment?.max,
                                  ),
                                  validator: _validateMax,
                                  onChanged: (_) => _updatePreview(resetValue: true),
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
