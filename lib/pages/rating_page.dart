import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class RatingPage extends StatefulWidget {
  final Rating? rating;

  const RatingPage({super.key, this.rating});

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
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;
  late FilterFilterType _filterFilterType;
  late FilterFilterType _initialFilterFilterType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rating?.name);
    _nameController.addListener(_changeListener);
    _adjustments = widget.rating == null ? [] : List.from(widget.rating!.adjustments);
    _initialAdjustments = List.from(_adjustments);
    

    _initialFilterFilterType = FilterFilterType(
      widget.rating?.filter,
      widget.rating?.filterType ?? FilterType.global,
    );
    _filterFilterType = _initialFilterFilterType;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.rating?.name ?? '') ||
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
    super.dispose();
  }

  Future<void> _addAdjustment<T extends Adjustment>(Widget page) async {
    final adjustment = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (adjustment == null) return;

    setState(() {
      _adjustments.add(adjustment);
    });
    
    _changeListener();
  }

  Future<void> _addAdjustmentFromPreset(Adjustment adjustment) async {
    final newAdjustment = await _editAdjustment(adjustment.deepCopy());
    if (newAdjustment == null) return;
    setState(() {
      _adjustments.add(newAdjustment);
    });
    _changeListener();
  }

  Future<Adjustment?> _editAdjustment(Adjustment adjustment) async {
    final Adjustment? editedAdjustment;
    if (adjustment is BooleanAdjustment) {
      editedAdjustment = await Navigator.push<BooleanAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => BooleanAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is CategoricalAdjustment) {
      editedAdjustment = await Navigator.push<CategoricalAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => CategoricalAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is StepAdjustment) {
      editedAdjustment = await Navigator.push<StepAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => StepAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is NumericalAdjustment) {
      editedAdjustment = await Navigator.push<NumericalAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => NumericalAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is TextAdjustment) {
      editedAdjustment = await Navigator.push<TextAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => TextAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else if (adjustment is DurationAdjustment) {
      editedAdjustment = await Navigator.push<DurationAdjustment>(
        context,
        MaterialPageRoute(
          builder: (context) => DurationAdjustmentPage(adjustment: adjustment)
        ),
      );
    } else {
      throw Exception("Not implemented.");
    }
    if (editedAdjustment == null) return null;
    setState(() {
      final index = _adjustments.indexOf(adjustment);
      if (index != -1) {
        _adjustments[index] = editedAdjustment!;
      }
    });
    _changeListener();
    return editedAdjustment;
  }

  Future<void> _duplicateAdjustment(Adjustment adjustment) async {
    final newAdjustment = adjustment.deepCopy();
    setState(() {
      _adjustments.add(newAdjustment);
    });
    _editAdjustment(newAdjustment);
  }

  Future<void> removeAdjustment(Adjustment adjustment) async {
    setState(() {
      _adjustments.remove(adjustment);
    });
    _changeListener();
  }

  void _saveRating() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    _formHasChanges = false;
    
    Navigator.pop(context, Rating(
      id: widget.rating?.id,
      name: name, 
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

  void _onReorderAdjustments(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    setState(() {
      final adjustment = _adjustments.removeAt(oldIndex);
      _adjustments.insert(adjustedNewIndex, adjustment);
    });
    _changeListener();
  }

  Widget _emptyAdjustmentsInfo() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              "No rating items yet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Define what rating items you want to record by tapping the button below.",
          style: TextStyle(height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        Text(
          "Examples:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 4),
        _buildGuideRow(NumericalAdjustment.iconData, "Numerical", "How many times did the fork bottom out?"),
        _buildGuideRow(StepAdjustment.iconData, "Step", "Rate grip or confidence (on 1-10 scale)"),
        _buildGuideRow(CategoricalAdjustment.iconData, "Categorical", "Rate based on categories (good/bad/acceptable)"),
        _buildGuideRow(BooleanAdjustment.iconData, "On/Off", "Did the fork bottom out? (Yes/No)"),
        if (context.read<AppSettings>().enableTextAdjustment)
          _buildGuideRow(TextAdjustment.iconData, "Text", "General notes about feel or observations"),
        _buildGuideRow(DurationAdjustment.iconData, "Duration", "Laptime of track xyz"),
      ],
    ),
  );

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
          title: widget.rating == null ? const Text('Add Rating') : const Text('Edit Rating'),
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
                  autofocus: widget.rating == null,
                  onChanged: (value) => setState(() {}), // see filled/fillColor
                  decoration: InputDecoration(
                    labelText: 'Rating Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter rating name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.rating != null && _nameController.text.trim() != widget.rating?.name,
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
                    filled: widget.rating != null && _filterFilterType.filter != widget.rating?.filter,
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
                                    bikes[object.bike]?.name ?? "BIKE NOT FOUND",
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
                const SizedBox(height: 16),
                _adjustments.isNotEmpty
                    ? AdjustmentEditList(
                        adjustments: _adjustments,
                        initialAdjustments: widget.rating != null ? Map.fromEntries(widget.rating!.adjustments.map((a) => MapEntry(a.id, a))) : null,
                        editAdjustment: _editAdjustment,
                        duplicateAdjustment: _duplicateAdjustment,
                        removeAdjustment: removeAdjustment,
                        onReorderAdjustments: _onReorderAdjustments,
                      ) 
                    : _emptyAdjustmentsInfo(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showRatingAddAdjustmentBottomSheet(
                      context: context,
                      addAdjustmentFromPreset: _addAdjustmentFromPreset,
                      addAdjustment: _addAdjustment,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Attribute"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
