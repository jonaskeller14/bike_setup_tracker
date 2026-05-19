import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_boolean_adjustment.dart';
import 'adjustment_page.dart';

class BooleanAdjustmentPage extends StatefulWidget {
  final BooleanAdjustment? adjustment;
  final AdjustmentPageMode mode;
  final Set<AdjustmentCategory> categories;
  final bool showCategorySelection;

  const BooleanAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
    required this.categories,
    this.showCategorySelection = false,
  });

  factory BooleanAdjustmentPage.add({Key? key, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    BooleanAdjustmentPage._(key: key, mode: AdjustmentPageMode.add, categories: categories, showCategorySelection: showCategorySelection);

  factory BooleanAdjustmentPage.edit({Key? key, required BooleanAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    BooleanAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit, categories: categories, showCategorySelection: showCategorySelection);

  factory BooleanAdjustmentPage.duplicate({Key? key, required BooleanAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    BooleanAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate, categories: categories, showCategorySelection: showCategorySelection);

  factory BooleanAdjustmentPage.template({Key? key, required BooleanAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    BooleanAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template, categories: categories, showCategorySelection: showCategorySelection);

  @override
  State<BooleanAdjustmentPage> createState() => _BooleanAdjustmentPageState();
}

class _BooleanAdjustmentPageState extends State<BooleanAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late AdjustmentCategory _category;

  bool? _previewValue = false;
  late BooleanAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);

    _category = widget.adjustment?.category 
        ?? widget.categories.firstOrNull 
        ?? AdjustmentCategory.component;

    _previewAdjustment = widget.adjustment ?? BooleanAdjustment(
      name: '', 
      notes: null,
      unit: null,
      category: _category,
    );
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') || 
        _notesController.text.trim() != (widget.adjustment?.notes ?? '');
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
    super.dispose();
  }

  void _saveBooleanAdjustment() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, BooleanAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name, 
      notes: notes.isEmpty ? null : notes, 
      unit: widget.adjustment?.unit,
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
            AdjustmentPageMode.template => const Text('Add On/Off Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit On/Off Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveBooleanAdjustment),
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
                                _previewAdjustment = BooleanAdjustment(
                                  name: newValue,
                                  notes: _previewAdjustment.notes,
                                  unit: null,
                                  category: _category,
                                );
                              });
                            },
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _saveBooleanAdjustment(),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofocus: widget.mode == AdjustmentPageMode.add,
                            decoration: InputDecoration(
                              labelText: 'Adjustment Name',
                              hintText: 'Enter Adjustment Name',
                              border: const OutlineInputBorder(),
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
                                border: const OutlineInputBorder(),
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
                                    _previewAdjustment = BooleanAdjustment(
                                      name: _nameController.text.trim(),
                                      notes: _previewAdjustment.notes,
                                      unit: null,
                                      category: newValue,
                                    );
                                  });
                                  _changeListener();
                                }
                              },
                            ),
                          ],
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
                                        category: _category,
                                      );
                                    });
                                  },
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    hintText: 'Enter measuring procedure/instrument/...',
                                    helperText: _notesController.text.trim().isEmpty ? null : "View these notes by tapping the ⓘ icon next to the name.",
                                    border: const OutlineInputBorder(),
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
