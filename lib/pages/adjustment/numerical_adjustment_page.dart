import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_numerical_adjustment.dart';

class NumericalAdjustmentPage extends StatefulWidget {
  final NumericalAdjustment? adjustment;
  const NumericalAdjustmentPage({super.key, this.adjustment});

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
  late TextEditingController _unitController;

  String? _previewValue;
  NumericalAdjustment _previewAdjustment = NumericalAdjustment(
    name: '', 
    notes: null,
    unit: null,
  );
  
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
    _unitController = TextEditingController(text: widget.adjustment?.unit);
    _unitController.addListener(_changeListener);

    if (widget.adjustment != null) {
      _previewAdjustment = widget.adjustment!;
      
      _expanded = true;
    }
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') || 
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        _unitController.text.trim() != (widget.adjustment?.unit ?? '') || 
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
    _unitController.removeListener(_changeListener);
    _unitController.dispose();
    super.dispose();
  }

  void _saveNumericalAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final unitText = _unitController.text.trim();

    final min = double.tryParse(minText) ?? double.negativeInfinity;
    final max = double.tryParse(maxText) ?? double.infinity;
    final unit = unitText.isNotEmpty ? unitText : null;
    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, NumericalAdjustment(
        name: name, 
        notes: notes.isEmpty ? null : notes, 
        min: min, 
        max: max, 
        unit: unit
      ));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.notes = notes.isEmpty ? null : notes;
      widget.adjustment!.unit = unit;
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

  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.adjustment == null ? const Text('Add Numerical Adjustment') : const Text('Edit Numerical Adjustment'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveNumericalAdjustment),
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
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          autofocus: widget.adjustment == null,
                          decoration: InputDecoration(
                            labelText: 'Adjustment Name',
                            hintText: 'Enter Adjustment Name',
                            border: OutlineInputBorder(),
                            fillColor: Colors.orange.withValues(alpha: 0.08),
                            filled: widget.adjustment != null && _nameController.text.trim() != widget.adjustment?.name,
                          ),
                          validator: _validateName,
                          onChanged: (String value) {
                            setState(() {
                              _previewAdjustment = NumericalAdjustment(
                                name: _nameController.text.trim(),
                                notes: _previewAdjustment.notes,
                                unit: _unitController.text.trim(),
                                min: double.tryParse(_minController.text.trim()),
                                max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _unitController,
                          maxLength: 10,
                          onFieldSubmitted: (_) => _saveNumericalAdjustment(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Unit (optional)',
                            hintText: 'Enter unit (e.g., mm, psi)',
                            border: OutlineInputBorder(),
                            fillColor: Colors.orange.withValues(alpha: 0.08),
                            filled: widget.adjustment != null && _unitController.text.trim() != (widget.adjustment?.unit ?? ""),
                          ),
                          validator: (value) => (value != null && value.length > 10) ? "Too many characters" : null,
                          onChanged: (String value) {
                            setState(() {
                              _previewAdjustment = NumericalAdjustment(
                                name: _nameController.text.trim(),
                                notes: _previewAdjustment.notes,
                                unit: _unitController.text.trim(), 
                                min: double.tryParse(_minController.text.trim()),
                                max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                              );
                            });
                          },
                        ),
                        if (!_expanded) ...[
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (!_expanded) _expanded = !_expanded;
                                });
                              },
                              icon: Icon(
                                _expanded ? Icons.expand_less : Icons.expand_more,
                              ),
                              label: Text(_expanded ? "Show less" : "Show more"),
                            ),
                          ),
                        ],
                        if (_expanded) ...[
                          const SizedBox(height: 12),
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
                              border: OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.adjustment != null && (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != widget.adjustment?.min,
                            ),
                            validator: _validateMin,
                            onChanged: (String value) {
                              setState(() {
                                _previewValue = null;
                                _previewAdjustment = NumericalAdjustment(
                                  name: _nameController.text.trim(),
                                  notes: _previewAdjustment.notes,
                                  unit: _unitController.text.trim(), 
                                  min: double.tryParse(_minController.text.trim()),
                                  max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                                );
                              });
                            },
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
                              border: OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.adjustment != null && (double.tryParse(_maxController.text.trim()) ?? double.infinity) != widget.adjustment?.max,
                            ),
                            validator: _validateMax,
                            onChanged: (String value) {
                              setState(() {
                                _previewValue = null;
                                _previewAdjustment = NumericalAdjustment(
                                  name: _nameController.text.trim(),
                                  notes: _previewAdjustment.notes,
                                  unit: _unitController.text.trim(), 
                                  min: double.tryParse(_minController.text.trim()),
                                  max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            minLines: 2,
                            maxLines: null,
                            onChanged: (String? value) {
                              setState(() {
                                _previewAdjustment = NumericalAdjustment(
                                  name: _nameController.text.trim(),
                                  notes: (value == null || value.isEmpty) ? null : value,
                                  unit: _unitController.text.trim(), 
                                  min: double.tryParse(_minController.text.trim()),
                                  max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                                );
                              });
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'Enter measuring procedure/instrument/...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ]
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
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor)), color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
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
                    child: Text(
                      'Preview only — changes won’t be saved',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
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
