import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_text_adjustment.dart';
import 'adjustment_page.dart';

class TextAdjustmentPage extends StatefulWidget {
  final TextAdjustment? adjustment;
  final AdjustmentPageMode mode;
  final Set<AdjustmentCategory> categories;
  final bool showCategorySelection;

  const TextAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
    required this.categories,
    this.showCategorySelection = false,
  });

  factory TextAdjustmentPage.add({Key? key, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    TextAdjustmentPage._(key: key, mode: AdjustmentPageMode.add, categories: categories, showCategorySelection: showCategorySelection);

  factory TextAdjustmentPage.edit({Key? key, required TextAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    TextAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit, categories: categories, showCategorySelection: showCategorySelection);

  factory TextAdjustmentPage.duplicate({Key? key, required TextAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    TextAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate, categories: categories, showCategorySelection: showCategorySelection);

  factory TextAdjustmentPage.template({Key? key, required TextAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    TextAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template, categories: categories, showCategorySelection: showCategorySelection);

  @override
  State<TextAdjustmentPage> createState() => _TextAdjustmentPageState();
}

class _TextAdjustmentPageState extends State<TextAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late AdjustmentCategory _category;

  String _previewValue = '';
  late TextAdjustment _previewAdjustment;

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

    _previewAdjustment = widget.adjustment ?? TextAdjustment(
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

  void _saveTextAdjustment() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, TextAdjustment(
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
            AdjustmentPageMode.template => const Text('Add Text Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Text Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveTextAdjustment),
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
                          onChanged: (String? value) {
                            setState(() {
                              _previewAdjustment = TextAdjustment(
                                name: value ?? '',
                                notes: _previewAdjustment.notes,
                                unit: _previewAdjustment.unit,
                                category: _category,
                              );
                            });
                          },
                          onFieldSubmitted: (_) => _saveTextAdjustment(),
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
                                  _previewAdjustment = TextAdjustment(
                                    name: _nameController.text.trim(),
                                    notes: _previewAdjustment.notes,
                                    unit: _previewAdjustment.unit,
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
                        if (_expanded) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            minLines: 2,
                            maxLines: null,
                            onChanged: (String? value) {
                              setState(() {
                                _previewAdjustment = TextAdjustment(
                                  name: _previewAdjustment.name, 
                                  notes: (value == null || value.isEmpty) ? null : value,
                                  unit: _previewAdjustment.unit,
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
                    padding: const EdgeInsetsGeometry.fromLTRB(16, 32, 16, 16),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor)), color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                    child: SingleChildScrollView(
                      child: Card(
                        child: SetTextAdjustmentWidget(
                          key: ValueKey(_previewAdjustment),
                          adjustment: _previewAdjustment,
                          initialValue: null,
                          value: _previewValue, 
                          onChanged: (String newValue) {
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
    );
  }
}
