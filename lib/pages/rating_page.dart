import 'package:flutter/material.dart';
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
  final List<Component> components;
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;

  const RatingPage({
    super.key,
    required this.bikes,
    required this.components,
    required this.persons,
    this.rating,
  });

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
  static const _enableTextAdjustment = false;
  static const _enableDurationAdjustment = true;
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;

  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;
  late FilterFilterType _filterFilterType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rating?.name);
    _nameController.addListener(_changeListener);
    _adjustments = widget.rating == null ? [] : List.from(widget.rating!.adjustments);
    _initialAdjustments = List.from(_adjustments);
    
    _filterFilterType = FilterFilterType(
      widget.rating?.filter,
      widget.rating?.filterType ?? FilterType.global,
    );
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.rating?.name ?? '') ||
        _filterFilterType.filter != (widget.rating?.filter) ||
        _filterFilterType.filterType != (widget.rating?.filterType ?? FilterType.global) ||
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
    if (widget.rating != null) widget.rating!.lastModified = DateTime.now();
    return editedAdjustment;
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
    
    if (widget.rating == null) {
      Navigator.pop(context, Rating(
        name: name, 
        filter: _filterFilterType.filter, 
        filterType: _filterFilterType.filterType,
        adjustments: _adjustments,
      ));
    } else {
      widget.rating!.name = name;
      widget.rating!.lastModified = DateTime.now();
      widget.rating!.filter = _filterFilterType.filter;
      widget.rating!.filterType = _filterFilterType.filterType;
      widget.rating!.adjustments
          ..clear()
          ..addAll(_adjustments);
      Navigator.pop(context, widget.rating);
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
        _buildGuideRow(Icons.speed, "Numerical", "How many times did the fork bottom out?"),
        _buildGuideRow(Icons.rotate_right, "Step", "Rate grip or confidence (on 1-10 scale)"),
        _buildGuideRow(Icons.category, "Categorical", "Rate based on categories (good/bad/acceptable)"),
        _buildGuideRow(Icons.toggle_on, "On/Off", "Did the fork bottom out? (Yes/No)"),
        if (_enableTextAdjustment)
          _buildGuideRow(Icons.text_snippet, "Text", "General notes about feel or observations"),
        if (_enableDurationAdjustment)
          _buildGuideRow(Icons.timer_outlined, "Duration", "Laptime of track xyz"),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
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
                  decoration: InputDecoration(
                    labelText: 'Rating Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter rating name',
                    fillColor: Colors.orange.withValues(alpha: 0.08),
                    filled: widget.rating != null && _nameController.text.trim() != widget.rating?.name,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a rating name';
                    }
                    return null;
                  },
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
                    return null;
                  },
                  items: [
                    DropdownMenuItem<FilterFilterType>(
                      value: FilterFilterType(null, FilterType.global),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 8,
                        children: [
                          const Icon(Icons.circle_outlined),
                          Expanded(child: Text("Apply everywhere", overflow: TextOverflow.ellipsis))
                        ],
                      ),
                    ),
                    ...widget.bikes.values.map((b) => DropdownMenuItem<FilterFilterType>(
                      value: FilterFilterType(b.id, FilterType.bike),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 8,
                        children: [
                          const Icon(Icons.pedal_bike),
                          Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis))
                        ],
                      ),
                    )),
                    ...ComponentType.values.map((ct) => DropdownMenuItem<FilterFilterType>(
                      value: FilterFilterType(ct.toString(), FilterType.componentType),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Component.getIcon(ct),
                          Expanded(child: Text(ct.value, overflow: TextOverflow.ellipsis))
                        ],
                      ),
                    )),
                    ...widget.components.map((c) => DropdownMenuItem<FilterFilterType>(
                      value: FilterFilterType(c.id, FilterType.component),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Flexible(
                            fit: FlexFit.tight, 
                            flex: 2,
                            child: Row(
                              spacing: 8,
                              children: [
                                Component.getIcon(c.componentType),
                                Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Row(
                              spacing: 8,
                              children: [
                                const Icon(Icons.pedal_bike),
                                Expanded(child: Text(widget.bikes[c.bike]?.name ?? "-", overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    ...widget.persons.values.map((p) => DropdownMenuItem<FilterFilterType>(
                      value: FilterFilterType(p.id, FilterType.person),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 8,
                        children: [
                          const Icon(Icons.person),
                          Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis))
                        ],
                      ),
                    )),
                  ],
                  onChanged: (FilterFilterType? newValue) {
                    setState(() {
                      _filterFilterType = newValue ?? FilterFilterType(null, FilterType.global);
                    });
                    _changeListener();
                  },
                ),
                const SizedBox(height: 16),
                _adjustments.isNotEmpty
                    ? AdjustmentEditList(
                        adjustments: _adjustments,
                        editAdjustment: _editAdjustment,
                        removeAdjustment: removeAdjustment,
                        onReorderAdjustments: _onReorderAdjustments,
                      ) 
                    : _emptyAdjustmentsInfo(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showRatingAddAdjustmentBottomSheet(
                      context: context,
                      enableTextAdjustment: _enableTextAdjustment,
                      enableDurationAdjustment: _enableDurationAdjustment,
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
