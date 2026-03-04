import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dashed_border_painter.dart';
import '../models/app_settings.dart';
import '../models/filtered_data.dart';
import '../models/rating.dart';
import '../models/component.dart';
import '../models/bike.dart';
import '../models/person.dart';
import '../models/adjustment/adjustment.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import 'adjustment/text_adjustment_page.dart';
import 'adjustment/duration_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/rating_add_adjustment.dart';

enum RatingPageMode {
  add,
  edit,
  duplicate,
}

class RatingPage extends StatefulWidget {
  final Rating? rating;
  final RatingPageMode mode;

  const RatingPage._({super.key, this.rating, required this.mode});

  factory RatingPage.add({Key? key}) => 
    RatingPage._(key: key, mode: RatingPageMode.add);

  factory RatingPage.edit({Key? key, required Rating rating}) => 
    RatingPage._(key: key, rating: rating, mode: RatingPageMode.edit);

  factory RatingPage.duplicate({Key? key, required Rating rating}) => 
    RatingPage._(key: key, rating: rating, mode: RatingPageMode.duplicate);

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class FilterFilterType {
  final String? filter;
  final FilterType filterType;

  const FilterFilterType(this.filter, this.filterType);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterFilterType &&
          runtimeType == other.runtimeType &&
          filter == other.filter &&
          filterType == other.filterType;

  @override
  int get hashCode => filter.hashCode ^ filterType.hashCode;
}

class _RatingPageState extends State<RatingPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;

  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;
  late FilterFilterType _filterFilterType;
  late FilterFilterType _initialFilterFilterType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rating?.name);
    _nameController.addListener(_changeListener);
    _adjustments = widget.rating == null 
        ? [] 
        : List.from(widget.rating!.adjustments);
    _initialAdjustments = List.from(_adjustments);
    

    _initialFilterFilterType = FilterFilterType(
      widget.rating?.filter,
      widget.rating?.filterType ?? FilterType.global,
    );
    _filterFilterType = _initialFilterFilterType;
    _notesController = TextEditingController(text: widget.rating?.notes);
    _notesController.addListener(_changeListener);
    if (widget.mode != RatingPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.rating?.name ?? '') ||
        _notesController.text.trim() != (widget.rating?.notes ?? '') ||
        _filterFilterType != _initialFilterFilterType ||
        _initialAdjustments.length != _adjustments.length || 
        _adjustments.asMap().entries.any((entry) => entry.value != _initialAdjustments[entry.key]);
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

  Future<void> _addAdjustment<T extends Adjustment>({VoidCallback? onChanged}) async {
    final adjustment = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => switch(T) {
        const (BooleanAdjustment)       => BooleanAdjustmentPage.add(categories: {AdjustmentCategory.rating}),
        const (CategoricalAdjustment)   => CategoricalAdjustmentPage.add(categories: {AdjustmentCategory.rating}),
        const (StepAdjustment)          => StepAdjustmentPage.add(categories: {AdjustmentCategory.rating}),
        const (NumericalAdjustment)     => NumericalAdjustmentPage.add(categories: {AdjustmentCategory.rating}),
        const (TextAdjustment)          => TextAdjustmentPage.add(categories: {AdjustmentCategory.rating}),
        const (DurationAdjustment)      => DurationAdjustmentPage.add(categories: {AdjustmentCategory.rating}),
        Type() => throw UnimplementedError(),
      }),
    );
    if (adjustment == null) return;
    setState(() => _adjustments.add(adjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _addAdjustmentFromPreset(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final newAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment.deepCopy()) {
        BooleanAdjustment a     => BooleanAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.rating}),
        CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.rating}),
        StepAdjustment a        => StepAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.rating}),
        NumericalAdjustment a   => NumericalAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.rating}),
        TextAdjustment a        => TextAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.rating}),
        DurationAdjustment a    => DurationAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.rating}),
      }),
    );
    if (newAdjustment == null) return;
    setState(() => _adjustments.add(newAdjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _editAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final editedAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment) {
        BooleanAdjustment a     => BooleanAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.rating}),
        CategoricalAdjustment a => CategoricalAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.rating}),
        StepAdjustment a        => StepAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.rating}),
        NumericalAdjustment a   => NumericalAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.rating}),
        TextAdjustment a        => TextAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.rating}),
        DurationAdjustment a    => DurationAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.rating}),
      }),
    );
    if (editedAdjustment == null) return;
    setState(() {
      final index = _adjustments.indexOf(adjustment);
      if (index != -1) {
        _adjustments[index] = editedAdjustment;
      }
    });
    _changeListener();
    onChanged?.call();
  }

  Future<void> _duplicateAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final newAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment.deepCopy()) {
        BooleanAdjustment a     => BooleanAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.rating}),
        CategoricalAdjustment a => CategoricalAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.rating}),
        StepAdjustment a        => StepAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.rating}),
        NumericalAdjustment a   => NumericalAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.rating}),
        TextAdjustment a        => TextAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.rating}),
        DurationAdjustment a    => DurationAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.rating}),
      }),
    );
    if (newAdjustment == null) return;
    setState(() => _adjustments.add(newAdjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> removeAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    setState(() => _adjustments.remove(adjustment));
    _changeListener();
    onChanged?.call();
  }

  void _saveRating() {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    
    Navigator.pop(context, Rating(
      id: widget.mode == RatingPageMode.edit ? widget.rating?.id : null, 
      name: name,
      notes: notes.isEmpty ? null : notes,
      filter: _filterFilterType.filter, 
      filterType: _filterFilterType.filterType,
      adjustments: _adjustments,
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  Widget _buildGuideRow(IconData icon, String type, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13, height: 1.3),
                children: [
                  TextSpan(
                    text: "$type: ", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  TextSpan(
                    text: example,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontStyle: FontStyle.italic)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onReorderAdjustments(int oldIndex, int newIndex, {VoidCallback? onChanged}) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    setState(() {
      final adjustment = _adjustments.removeAt(oldIndex);
      _adjustments.insert(adjustedNewIndex, adjustment);
    });
    _changeListener();
    onChanged?.call();
  }

  Widget _emptyAdjustmentsInfo({String? errorText, VoidCallback? onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: errorText != null 
                  ? Theme.of(context).colorScheme.error 
                  : Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1.5,
              dashWidth: 6,
              dashSpace: 4,
              borderRadius: 12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    errorText != null ? Icons.warning_amber_rounded : Icons.add_circle_outline, 
                    size: 32, 
                    color: errorText != null 
                        ? Theme.of(context).colorScheme.error 
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorText ?? "No metrics yet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: errorText != null 
                          ? Theme.of(context).colorScheme.error 
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorText != null 
                        ? "Tap here to add the first metric" 
                        : "Tap 'Add Metric' to define metrics to evaluate setups",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: errorText != null 
                          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.7) 
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              _buildGuideRow(NumericalAdjustment.iconData, "Numerical", "How many times did the fork bottom out?"),
              _buildGuideRow(StepAdjustment.iconData, "Step", "Rate grip or confidence (on 1-10 scale)"),
              _buildGuideRow(CategoricalAdjustment.iconData, "Categorical", "Rate based on categories (good/bad/acceptable)"),
              _buildGuideRow(BooleanAdjustment.iconData, "On/Off", "Did the fork bottom out? (Yes/No)"),
              if (context.read<AppSettings>().enableTextAdjustment)
                _buildGuideRow(TextAdjustment.iconData, "Text", "General notes about feel or observations"),
              _buildGuideRow(DurationAdjustment.iconData, "Duration", "Laptime of track xyz"),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final bikes = filteredData.bikes;
    final persons = filteredData.persons;
    final components = filteredData.components;

    final Map<FilterFilterType, dynamic> filterOptions = Map.fromEntries([
      MapEntry(FilterFilterType(null, FilterType.global), null),
      ...bikes.values.map((b) => MapEntry(FilterFilterType(b.id, FilterType.bike), b)),
      ...ComponentType.values.map((ct) => MapEntry(FilterFilterType(ct.toString(), FilterType.componentType), ct)),
      ...components.values.map((c) => MapEntry(FilterFilterType(c.id, FilterType.component), c)),
      ...persons.values.map((p) => MapEntry(FilterFilterType(p.id, FilterType.person), p)),
    ]);

    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            RatingPageMode.add || RatingPageMode.duplicate => const Text('Add Rating'),
            RatingPageMode.edit => const Text('Edit Rating'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveRating),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  onFieldSubmitted: (_) => _saveRating(),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  autofocus: widget.mode == RatingPageMode.add,
                  onChanged: (value) => setState(() {}), // see filled/fillColor
                  decoration: InputDecoration(
                    labelText: 'Rating Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter rating name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == RatingPageMode.edit && _nameController.text.trim() != widget.rating?.name,
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FilterFilterType?>(
                  initialValue: _filterFilterType,
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Filter',
                    border: OutlineInputBorder(),
                    hintText: "Choose an object which the filter should be applied for",
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.mode == RatingPageMode.edit && _filterFilterType.filter != widget.rating?.filter,
                  ),
                  validator: (FilterFilterType? newValue) {
                    if (!filterOptions.containsKey(newValue)) return "Invalid Filter.";
                    return null;
                  },
                  items: filterOptions.entries.map((filterEntry) {
                    final fft = filterEntry.key;
                    final object = filterEntry.value;
                    return DropdownMenuItem<FilterFilterType>(
                      value: fft,
                      child: Row(
                        spacing: 8,
                        children: switch(fft.filterType) {
                          FilterType.global => [
                            const Icon(Icons.circle_outlined),
                            Expanded(child: Text("Apply everywhere", overflow: TextOverflow.ellipsis))
                          ],
                          FilterType.bike => [
                            const Icon(Bike.iconData),
                            Expanded(child: Text(object?.name, overflow: TextOverflow.ellipsis)),
                          ],
                          FilterType.component => [
                            Flexible(
                              fit: FlexFit.tight, 
                              child: Row(
                                spacing: 8,
                                children: [
                                  Icon(object.componentType.getIconData()),
                                  Expanded(child: Text(object.name, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.tight,
                              child: Row(
                                spacing: 8,
                                children: [
                                  Icon(
                                    object.bike != null ? Bike.iconData : Icons.shelves,
                                    color: object.bike == null || bikes.containsKey(object.bike) 
                                        ? null
                                        : Theme.of(context).colorScheme.error,
                                  ), 
                                  Expanded(child: Text(
                                    object.bike == null
                                        ? "Not installed"
                                        : bikes[object.bike]?.name ?? "BIKE NOT FOUND",
                                    style: object.bike == null || bikes.containsKey(object.bike) 
                                        ? null 
                                        : TextStyle(color: Theme.of(context).colorScheme.error), 
                                    overflow: TextOverflow.ellipsis
                                  )),
                                ],
                              ),
                            ),
                          ],
                          FilterType.componentType => [
                            Icon(object.getIconData()),
                            Expanded(child: Text(object.value, overflow: TextOverflow.ellipsis))
                          ],
                          FilterType.person => [
                            const Icon(Person.iconData),
                            Expanded(child: Text(object.name, overflow: TextOverflow.ellipsis))
                          ],
                        },
                      ),
                    );
                  }).toList() + [
                    if (!filterOptions.containsKey(_filterFilterType))
                      DropdownMenuItem<FilterFilterType>(
                        value: _filterFilterType,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(
                              switch (_filterFilterType.filterType) {
                                FilterType.bike => Bike.iconData,
                                FilterType.component => ComponentType.other.getIconData(),
                                FilterType.componentType => ComponentType.other.getIconData(),
                                FilterType.person => Person.iconData,
                                FilterType.global => Icons.error,
                              }, 
                              color: Theme.of(context).colorScheme.error
                            ),
                            Expanded(child: Text(
                              switch (_filterFilterType.filterType) {
                                FilterType.bike => "BIKE NOT FOUND",
                                FilterType.component => "COMPONENT NOT FOUND",
                                FilterType.componentType => "COMPONENTTYPE NOT FOUND",
                                FilterType.person => "PERSON NOT FOUND",
                                FilterType.global => "OBJECT NOT FOUND",
                              },
                              overflow: TextOverflow.ellipsis, 
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ))
                          ],
                        ),
                      ),
                  ],
                    onChanged: (FilterFilterType? newValue) {
                      setState(() => _filterFilterType = newValue ?? FilterFilterType(null, FilterType.global));
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
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Describe the rating procedure, guidelines, instructions, ...',
                      border: OutlineInputBorder(),
                      fillColor: Colors.orange.withValues(alpha: 0.08),
                      filled: widget.mode == RatingPageMode.edit && _notesController.text.trim() != (widget.rating?.notes ?? ""),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Text("Metrics", style: Theme.of(context).textTheme.titleMedium),
                ),
                FormField<List<Adjustment>>(
                  initialValue: _adjustments,
                  validator: (_) { // Evaluate _adjustments for robustness
                    if (_adjustments.isEmpty) {
                      return 'You need to add at least one metric';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  builder: (FormFieldState<List<Adjustment>> field) {
                    void notify() => field.didChange(List.from(_adjustments));
 
                    void showAddBottomSheet() => showRatingAddAdjustmentBottomSheet(
                      context: context,
                      addAdjustmentFromPreset: (a) => _addAdjustmentFromPreset(a, onChanged: notify),
                      addAdjustment: <T extends Adjustment>() => _addAdjustment<T>(onChanged: notify),
                    );
 
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _adjustments.isNotEmpty
                            ? AdjustmentEditList(
                                adjustments: _adjustments,
                                initialAdjustments: widget.mode == RatingPageMode.edit 
                                    ? Map.fromEntries(widget.rating!.adjustments.map((a) => MapEntry(a.id, a))) 
                                    : null,
                                editAdjustment: (a) => _editAdjustment(a, onChanged: notify),
                                duplicateAdjustment: (a) => _duplicateAdjustment(a, onChanged: notify),
                                removeAdjustment: (a) => removeAdjustment(a, onChanged: notify),
                                onReorderAdjustments: (oldIndex, newIndex) => _onReorderAdjustments(oldIndex, newIndex, onChanged: notify),
                              ) 
                            : _emptyAdjustmentsInfo(
                                errorText: field.errorText,
                                onTap: showAddBottomSheet,
                              ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: showAddBottomSheet,
                            icon: const Icon(Icons.add),
                            label: const Text("Add Metric"),
                          ),
                        ),
                        if (field.hasError && _adjustments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
