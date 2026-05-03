import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/set_adjustment/set_duration_adjustment.dart';
import '../../widgets/sheets/set_duration.dart';
import 'adjustment_page.dart';

class DurationAdjustmentPage extends StatefulWidget {
  final DurationAdjustment? adjustment;
  final AdjustmentPageMode mode;
  final Set<AdjustmentCategory> categories;
  final bool showCategorySelection;

  const DurationAdjustmentPage._({
    super.key,
    this.adjustment,
    required this.mode,
    required this.categories,
    this.showCategorySelection = false,
  });

  factory DurationAdjustmentPage.add({Key? key, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    DurationAdjustmentPage._(key: key, mode: AdjustmentPageMode.add, categories: categories, showCategorySelection: showCategorySelection);

  factory DurationAdjustmentPage.edit({Key? key, required DurationAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    DurationAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.edit, categories: categories, showCategorySelection: showCategorySelection);

  factory DurationAdjustmentPage.duplicate({Key? key, required DurationAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    DurationAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.duplicate, categories: categories, showCategorySelection: showCategorySelection);

  factory DurationAdjustmentPage.template({Key? key, required DurationAdjustment adjustment, required Set<AdjustmentCategory> categories, bool showCategorySelection = false}) => 
    DurationAdjustmentPage._(key: key, adjustment: adjustment, mode: AdjustmentPageMode.template, categories: categories, showCategorySelection: showCategorySelection);

  @override
  State<DurationAdjustmentPage> createState() => _DurationAdjustmentPageState();
}

class _DurationAdjustmentPageState extends State<DurationAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  final FocusNode _minFocusNode = FocusNode(canRequestFocus: false);
  final FocusNode _maxFocusNode = FocusNode(canRequestFocus: false);

  Duration _previewValue = Duration.zero;
  late AdjustmentCategory _category;
  late DurationAdjustment _previewAdjustment;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adjustment?.name);
    _nameController.addListener(_changeListener);
    _notesController = TextEditingController(text: widget.adjustment?.notes);
    _notesController.addListener(_changeListener);
    _minController = TextEditingController(text: widget.adjustment?.min == null ? null : Adjustment.formatValue(widget.adjustment?.min));
    _minController.addListener(_changeListener);
    _maxController = TextEditingController(text: widget.adjustment?.max == null ? null : Adjustment.formatValue(widget.adjustment?.max));
    _maxController.addListener(_changeListener);

    _category = widget.adjustment?.category 
        ?? widget.categories.firstOrNull 
        ?? AdjustmentCategory.component;

    _previewAdjustment = widget.adjustment ?? DurationAdjustment(
      name: '', 
      notes: null,
      unit: null,
      category: _category,
    );
    _previewValue = _previewAdjustment.min ?? Duration.zero;
    if (widget.mode != AdjustmentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.adjustment?.name ?? '') || 
        _notesController.text.trim() != (widget.adjustment?.notes ?? '') ||
        _previewAdjustment.min != widget.adjustment?.min ||
        _previewAdjustment.max != widget.adjustment?.max;
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
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  void _saveDurationAdjustment() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    if (!mounted) return;
    Navigator.pop(context, DurationAdjustment(
      id: widget.mode == AdjustmentPageMode.edit ? widget.adjustment!.id : null,
      name: name, 
      notes: notes.isEmpty ? null : notes, 
      min: _previewAdjustment.min, 
      max: _previewAdjustment.max, 
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
            AdjustmentPageMode.template => const Text('Add Duration Adjustment'),
            AdjustmentPageMode.edit => const Text('Edit Duration Adjustment'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveDurationAdjustment),
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
                                _previewAdjustment = DurationAdjustment(
                                  name: newValue,
                                  notes: _previewAdjustment.notes,
                                  unit: _previewAdjustment.unit,
                                  min: _previewAdjustment.min,
                                  max: _previewAdjustment.max,
                                  category: _category,
                                );
                              });
                            },
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _saveDurationAdjustment(),
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
                                    _previewAdjustment = DurationAdjustment(
                                      name: _nameController.text.trim(),
                                      notes: _previewAdjustment.notes,
                                      unit: _previewAdjustment.unit,
                                      min: _previewAdjustment.min,
                                      max: _previewAdjustment.max,
                                      category: newValue,
                                    );
                                  });
                                  _changeListener();
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
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
                                  controller: _minController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  focusNode: _minFocusNode,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    showSetDurationSheet(
                                      context: context,
                                      adjustment: DurationAdjustment(name: 'Min', notes: null, unit: null, max: _previewAdjustment.max, category: _category),
                                      value: _previewAdjustment.min,
                                      onChanged: (Duration newValue) {
                                        setState(() {
                                          _previewAdjustment = DurationAdjustment(
                                            id: _previewAdjustment.id,
                                            name: _previewAdjustment.name,
                                            notes: _previewAdjustment.notes,
                                            unit: _previewAdjustment.unit,
                                            min: newValue,
                                            max: _previewAdjustment.max,
                                            category: _category,
                                          );
                                          _minController.text = Adjustment.formatValue(newValue);
                                        });
                                      }
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Min Duration (optional)',
                                    hintText: 'Select minimum duration',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.vertical_align_bottom),
                                    suffixIcon: _minController.text.isNotEmpty
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
                                    filled: widget.mode == AdjustmentPageMode.edit && _previewAdjustment.min != widget.adjustment?.min,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _maxController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  focusNode: _maxFocusNode,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    showSetDurationSheet(
                                      context: context,
                                      adjustment: DurationAdjustment(name: 'Max', notes: null, unit: null, min: _previewAdjustment.min, category: _category),
                                      value: _previewAdjustment.max,
                                      onChanged: (Duration newValue) {
                                        setState(() {
                                          _previewAdjustment = DurationAdjustment(
                                            id: _previewAdjustment.id,
                                            name: _previewAdjustment.name,
                                            notes: _previewAdjustment.notes,
                                            unit: _previewAdjustment.unit,
                                            min: _previewAdjustment.min,
                                            max: newValue,
                                            category: _category,
                                          );
                                          _maxController.text = Adjustment.formatValue(newValue);
                                        });
                                      }
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Max Duration (optional)',
                                    hintText: 'Select maximum duration',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.vertical_align_top),
                                    suffixIcon: _maxController.text.isNotEmpty
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
                                    filled: widget.mode == AdjustmentPageMode.edit && _previewAdjustment.max != widget.adjustment?.max,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _notesController,
                                  minLines: 2,
                                  maxLines: null,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _previewAdjustment = DurationAdjustment(
                                        name: _nameController.text.trim(),
                                        notes: (value == null || value.isEmpty) ? null : value,
                                        unit: _previewAdjustment.unit, 
                                        min: _previewAdjustment.min,
                                        max: _previewAdjustment.max,
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
