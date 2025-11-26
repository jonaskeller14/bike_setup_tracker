import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';

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
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _unitController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min == double.infinity || widget.adjustment?.min == double.negativeInfinity ? null : widget.adjustment?.min.toString());
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max == double.infinity || widget.adjustment?.max == double.negativeInfinity ? null : widget.adjustment?.max.toString());
    _maxController.addListener(_changeListener);
    _unitController = TextEditingController(text: widget.adjustment?.unit);
    _unitController.addListener(_changeListener);
  }

  void _changeListener() {
    final nameHasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '');
    final unitHasChanges = _unitController.text.trim() != (widget.adjustment?.unit ?? '');
    final minHasChanges = (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != (widget.adjustment?.min ?? double.negativeInfinity);
    final maxHasChanges = (double.tryParse(_maxController.text.trim()) ?? double.infinity) != (widget.adjustment?.max ?? double.infinity);
    final hasChanges = nameHasChanges || unitHasChanges || minHasChanges || maxHasChanges;
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
    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final unitText = _unitController.text.trim();

    final min = double.tryParse(minText) ?? double.negativeInfinity;
    final max = double.tryParse(maxText) ?? double.infinity;
    final unit = unitText.isNotEmpty ? unitText : null;
    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, NumericalAdjustment(name: name, min: min, max: max, unit: unit));
    } else {
      widget.adjustment!.name = name;
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
                    controller: _unitController,
                    onFieldSubmitted: (_) => _saveNumericalAdjustment(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Unit (optional)',
                      hintText: 'Enter unit (e.g., mm, psi)',
                      border: OutlineInputBorder(),
                    ),
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
                      decoration: const InputDecoration(
                        labelText: 'Min Value (optional)',
                        hintText: 'Enter minimum value',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateMin,
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
                      decoration: const InputDecoration(
                        labelText: 'Max Value (optional)',
                        hintText: 'Enter maximum value',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateMax,
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
