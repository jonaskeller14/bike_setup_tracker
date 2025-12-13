import 'package:flutter/material.dart';
import '../../models/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_categorical_adjustment.dart';

class CategoricalAdjustmentPage extends StatefulWidget {
  final CategoricalAdjustment? adjustment;
  const CategoricalAdjustmentPage({super.key, this.adjustment});

  @override
  State<CategoricalAdjustmentPage> createState() => _CategoricalAdjustmentPageState();
}

class _CategoricalAdjustmentPageState extends State<CategoricalAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late List<TextEditingController> _optionControllers;

  String? _previewValue;
  CategoricalAdjustment _previewAdjustment = CategoricalAdjustment(
    name: '',
    notes: null,
    unit: null,
    options: [],
  );
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    if (widget.adjustment == null) {
      _optionControllers = [TextEditingController()];
    } else {
      _optionControllers = widget.adjustment!.options.map((option) => TextEditingController(text: option)).toList();
    }
    for (final optionController in _optionControllers) {
      optionController.addListener(_changeListener);
    }

    if (widget.adjustment != null) {
      _previewAdjustment = widget.adjustment!;
      _expanded = true;
    }
  }

  void _changeListener() {
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet();
    final initialOptions = widget.adjustment?.options.toSet() ?? {};
    
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') || 
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        options.length != initialOptions.length || 
        !options.containsAll(initialOptions);
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
      _previewValue = null;
      _previewAdjustment = CategoricalAdjustment(
        name: _nameController.text.trim(),
        notes: _previewAdjustment.notes,
        unit: null, 
        options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
      );
    });
  }

  void _removeOptionField(int index) {
    if (_optionControllers.length == 1) return; // keep at least one field
    setState(() {
      _optionControllers[index].removeListener(_changeListener);
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _previewValue = null;
      _previewAdjustment = CategoricalAdjustment(
        name: _nameController.text.trim(),
        notes: null,
        unit: null, 
        options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
      );
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

  void _saveCategoricalAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    _formHasChanges = false;
    if (!mounted) return;
    if (widget.adjustment == null) {
      Navigator.pop(context, CategoricalAdjustment(
        name: name, 
        notes: notes.isEmpty ? null : notes, 
        unit: null, 
        options: options
      ));
    } else {
      widget.adjustment!.name = name;
      widget.adjustment!.notes = notes.isEmpty ? null : notes;
      widget.adjustment!.options = options;
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
    
  @override
  Widget build(BuildContext context) {
    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: widget.adjustment == null ? const Text('Add Categorical Adjustment') : const Text('Edit Categorical Adjustment'),
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveCategoricalAdjustment),
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
                              _previewAdjustment = CategoricalAdjustment(
                                name: _nameController.text.trim(),
                                notes: _previewAdjustment.notes,
                                unit: null, 
                                options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
                              );
                            });
                          },
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
                                      onFieldSubmitted: (_) => _saveCategoricalAdjustment(),
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: InputDecoration(
                                        labelText: 'Option ${index + 1}',
                                        hintText: 'Enter option value',
                                        border: const OutlineInputBorder(),
                                        errorText: _validateOptions(),
                                        fillColor: Colors.orange.withValues(alpha: 0.08),
                                        filled: widget.adjustment != null && !widget.adjustment!.options.contains(controller.text.trim()),
                                      ),
                                      validator: _validateOption,
                                      onChanged: (String value) {
                                        setState(() {
                                          _previewValue = null;
                                          _previewAdjustment = CategoricalAdjustment(
                                            name: _nameController.text.trim(),
                                            notes: _previewAdjustment.notes,
                                            unit: null, 
                                            options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
                                          );
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
                        if (!_expanded) ...[
                          Divider(),
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
                            controller: _notesController,
                            minLines: 2,
                            maxLines: null,
                            onChanged: (String? value) {
                              setState(() {
                                _previewAdjustment = CategoricalAdjustment(
                                  name: _previewAdjustment.name, 
                                  notes: (value == null || value.isEmpty) ? null : value,
                                  options: _previewAdjustment.options,
                                  unit: null
                                );
                              });
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'Enter measuring procedure/instrument/...',
                              border: OutlineInputBorder(),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.adjustment != null && _notesController.text.trim() != (widget.adjustment?.notes ?? ""),
                            ),
                          ),
                        ],
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
                    child: SetCategoricalAdjustmentWidget(
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
