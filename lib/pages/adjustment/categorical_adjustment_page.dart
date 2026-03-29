import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_categorical_adjustment.dart';
import 'adjustment_page.dart';

class CategoricalAdjustmentPage extends StatefulWidget {
  final CategoricalAdjustment? adjustment;
  final AdjustmentPageMode mode;
  final Set<AdjustmentCategory> categories;
  final bool showCategorySelection;

  const CategoricalAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
    required this.categories,
    this.showCategorySelection = false,
  });

  factory CategoricalAdjustmentPage.add({Key? key, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    CategoricalAdjustmentPage._(key: key, mode: AdjustmentPageMode.add, categories: categories, showCategorySelection: showCategorySelection);

  factory CategoricalAdjustmentPage.edit({Key? key, required CategoricalAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    CategoricalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit, categories: categories, showCategorySelection: showCategorySelection);

  factory CategoricalAdjustmentPage.duplicate({Key? key, required CategoricalAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    CategoricalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate, categories: categories, showCategorySelection: showCategorySelection);

  factory CategoricalAdjustmentPage.template({Key? key, required CategoricalAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    CategoricalAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template, categories: categories, showCategorySelection: showCategorySelection);

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
  late AdjustmentCategory _category;

  String? _previewValue;
  late CategoricalAdjustment _previewAdjustment;

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

    _category = widget.adjustment?.category 
        ?? widget.categories.firstOrNull 
        ?? AdjustmentCategory.component;

    _previewAdjustment = widget.adjustment ?? CategoricalAdjustment(
      name: '',
      notes: null,
      unit: null,
      options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
      category: _category,
    );
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
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
        options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
        category: _category,
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
        options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
        category: _category,
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
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, CategoricalAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name, 
      notes: notes.isEmpty ? null : notes, 
      unit: widget.adjustment?.unit, 
      options: options,
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
            AdjustmentPageMode.template => const Text('Add Categorical Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Categorical Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveCategoricalAdjustment),
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
                                _previewAdjustment = CategoricalAdjustment(
                                  name: newValue,
                                  notes: _previewAdjustment.notes,
                                  unit: null,
                                  options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
                                  category: _category,
                                );
                              });
                            },
                            textInputAction: TextInputAction.next,
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
                                    _previewAdjustment = CategoricalAdjustment(
                                      name: _nameController.text.trim(),
                                      notes: _previewAdjustment.notes,
                                      unit: null,
                                      options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
                                      category: newValue,
                                    );
                                  });
                                  _changeListener();
                                }
                              },
                            ),
                          ],
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
                          if (widget.mode == AdjustmentPageMode.edit) ...[
                            ListTile(
                              leading: const Icon(Icons.warning),
                              title: const Text('WARNING: Renaming an option will not update existing setup values!'),
                              dense: true,
                              contentPadding: const EdgeInsets.all(0),
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
                                        onFieldSubmitted: (_) => _saveCategoricalAdjustment(),
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        decoration: InputDecoration(
                                          labelText: 'Option ${index + 1}',
                                          hintText: 'Enter option value',
                                          border: const OutlineInputBorder(),
                                          errorText: _validateOptions(),
                                          fillColor: Colors.orange.withValues(alpha: 0.08),
                                          filled: widget.mode == AdjustmentPageMode.edit && !widget.adjustment!.options.contains(controller.text.trim()),
                                        ),
                                        validator: _validateOption,
                                        onChanged: (String value) {
                                          setState(() {
                                            _previewValue = null;
                                            _previewAdjustment = CategoricalAdjustment(
                                              name: _nameController.text.trim(),
                                              notes: _previewAdjustment.notes,
                                              unit: null, 
                                              options: _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toSet(),
                                              category: _category,
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
                                        unit: null,
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
                            ),
                          ),
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
