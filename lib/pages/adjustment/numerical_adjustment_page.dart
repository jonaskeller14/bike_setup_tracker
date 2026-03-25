import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_numerical_adjustment.dart';
import 'adjustment_page.dart';

class NumericalAdjustmentPage extends StatefulWidget {
  final NumericalAdjustment? adjustment;
  final AdjustmentPageMode mode;
  final Set<AdjustmentCategory> categories;
  final bool showCategorySelection;

  const NumericalAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
    required this.categories,
    this.showCategorySelection = false,
  });

  factory NumericalAdjustmentPage.add({Key? key, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    NumericalAdjustmentPage._(key: key, mode: AdjustmentPageMode.add, categories: categories, showCategorySelection: showCategorySelection);

  factory NumericalAdjustmentPage.edit({Key? key, required NumericalAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    NumericalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit, categories: categories, showCategorySelection: showCategorySelection);

  factory NumericalAdjustmentPage.duplicate({Key? key, required NumericalAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    NumericalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate, categories: categories, showCategorySelection: showCategorySelection);

  factory NumericalAdjustmentPage.template({Key? key, required NumericalAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    NumericalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template, categories: categories, showCategorySelection: showCategorySelection);

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
  late AdjustmentCategory _category;

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
    _unitController = TextEditingController(text: widget.adjustment?.unit);
    _unitController.addListener(_changeListener);

    _category = widget.adjustment?.category 
        ?? widget.categories.firstOrNull 
        ?? AdjustmentCategory.component;

    _previewAdjustment = widget.adjustment ?? NumericalAdjustment(
      name: '', 
      notes: null,
      unit: null,
      category: _category,
    );
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
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
    Navigator.pop(context, NumericalAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name, 
      notes: notes.isEmpty ? null : notes, 
      min: min, 
      max: max, 
      unit: unit,
      category: _category,
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
                            onChanged: (String newValue) {
                              setState(() {
                                _previewAdjustment = NumericalAdjustment(
                                  name: newValue,
                                  notes: _previewAdjustment.notes,
                                  unit: _unitController.text.trim(),
                                  min: double.tryParse(_minController.text.trim()),
                                  max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                                  category: _category,
                                );
                              });
                            },
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _saveNumericalAdjustment(),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofocus: widget.mode == AdjustmentPageMode.add,
                            decoration: InputDecoration(
                              labelText: 'Adjustment Name',
                              hintText: 'Enter Adjustment Name',
                              border: OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.mode == AdjustmentPageMode.edit && _nameController.text.trim() != widget.adjustment?.name,
                            ),
                            validator: validateAdjustmentName,
                          ),
                          if (widget.showCategorySelection && widget.categories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<AdjustmentCategory>(
                              initialValue: _category,
                              isExpanded: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                hintText: "Choose a category for this adjustment",
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.mode == AdjustmentPageMode.edit && _category != widget.adjustment!.category
                              ),
                              validator: (AdjustmentCategory? newValue) {
                                if (newValue == null) return "Please select a category";
                                return null;
                              },
                              items: widget.categories.map((category) {
                                return DropdownMenuItem<AdjustmentCategory>(
                                  value: category,
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      Icon(category.getIconData()),
                                      Expanded(child: Text(category.value, overflow: TextOverflow.ellipsis))
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (AdjustmentCategory? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _category = newValue;
                                    _previewAdjustment = NumericalAdjustment(
                                      name: _nameController.text.trim(),
                                      notes: _previewAdjustment.notes,
                                      unit: _unitController.text.trim(),
                                      min: double.tryParse(_minController.text.trim()),
                                      max: _validateMax(_maxController.text.trim()) == null ? double.tryParse(_maxController.text.trim()) : null,
                                      category: newValue,
                                    );
                                  });
                                  _changeListener();
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (widget.mode == AdjustmentPageMode.edit) ...[
                            ListTile(
                              leading: const Icon(Icons.warning),
                              title: const Text('WARNING: Editing Unit will not update existing setup values!'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 12),
                          ],
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
                              filled: widget.mode == AdjustmentPageMode.edit && _unitController.text.trim() != (widget.adjustment?.unit ?? ""),
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
                                  category: _category,
                                );
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
                                prefixIcon: const Icon(Icons.vertical_align_bottom),
                                suffixIcon: _previewAdjustment.min != double.negativeInfinity
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _previewAdjustment = _previewAdjustment.copyWith(min: null);
                                            _minController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.mode == AdjustmentPageMode.edit && (double.tryParse(_minController.text.trim()) ?? double.negativeInfinity) != widget.adjustment?.min,
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
                                    category: _category,
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
                                prefixIcon: const Icon(Icons.vertical_align_top),
                                suffixIcon: _previewAdjustment.max != double.infinity
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _previewAdjustment = _previewAdjustment.copyWith(max: null);
                                            _maxController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.mode == AdjustmentPageMode.edit && (double.tryParse(_maxController.text.trim()) ?? double.infinity) != widget.adjustment?.max,
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
                                    category: _category,
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
                                    category: _category,
                                  );
                                });
                              },
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                hintText: 'Enter measuring procedure/instrument/...',
                                helperText: _notesController.text.trim().isEmpty ? null : "View these notes by tapping the ⓘ icon next to the name.",
                                border: OutlineInputBorder(),
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.mode == AdjustmentPageMode.edit && _notesController.text.trim() != (widget.adjustment?.notes ?? ""),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor)), color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                      child: SingleChildScrollView(
                        padding: EdgeInsetsGeometry.fromLTRB(16, 32, 16, 16 + MediaQuery.of(context).padding.bottom),
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
                    ),
                    previewLabel(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
