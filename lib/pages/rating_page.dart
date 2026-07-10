import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/rating_association.dart';
import '../models/rating_metric.dart';
import '../repositories/app_repository.dart';
import '../theme.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/empty_state_placeholder2.dart';
import '../widgets/lists/adjustment_edit_list.dart';
import '../widgets/sheets/rating_add_adjustment.dart';
import '../widgets/text/section_title.dart';
import 'metric/boolean_metric_page.dart';
import 'metric/categorical_metric_page.dart';
import 'metric/duration_metric_page.dart';
import 'metric/numerical_metric_page.dart';
import 'metric/step_metric_page.dart';
import 'metric/text_metric_page.dart';

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


class _RatingPageState extends State<RatingPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;

  late List<RatingMetric> _metrics;
  late List<RatingMetric> _initialMetrics;
  late RatingAssociation _ratingAssociation;
  late RatingAssociation _initialRatingAssociation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rating?.name);
    _nameController.addListener(_changeListener);
    _metrics = widget.rating == null
        ? []
        : List.from(widget.rating!.metrics);
    _initialMetrics = List.from(_metrics);

    _initialRatingAssociation = RatingAssociation.fromIds(
      componentId: widget.rating?.filterType == FilterType.component ? widget.rating?.filter : null,
      bikeId: widget.rating?.filterType == FilterType.bike ? widget.rating?.filter : null,
      personId: widget.rating?.filterType == FilterType.person ? widget.rating?.filter : null,
      componentTypeStr: widget.rating?.filterType == FilterType.componentType ? widget.rating?.filter : null,
    );
    _ratingAssociation = _initialRatingAssociation;
    _notesController = TextEditingController(text: widget.rating?.notes);
    _notesController.addListener(_changeListener);
    if (widget.mode != RatingPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.rating?.name ?? '') ||
        _notesController.text.trim() != (widget.rating?.notes ?? '') ||
        _ratingAssociation != _initialRatingAssociation ||
        !listEquals(_metrics, _initialMetrics);
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

  Future<void> _addMetric<T extends Adjustment>({VoidCallback? onChanged}) async {
    final metric = await Navigator.push<RatingMetric>(
      context,
      MaterialPageRoute(builder: (context) => switch (T) {
        const (BooleanAdjustment)     => BooleanMetricPage.add(),
        const (CategoricalAdjustment) => CategoricalMetricPage.add(),
        const (StepAdjustment)        => StepMetricPage.add(),
        const (NumericalAdjustment)   => NumericalMetricPage.add(),
        const (TextAdjustment)        => TextMetricPage.add(),
        const (DurationAdjustment)    => DurationMetricPage.add(),
        Type() => throw UnimplementedError(),
      }),
    );
    if (metric == null) return;
    setState(() => _metrics.add(metric));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _addMetricFromPreset(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final seed = RatingMetric(
      adjustment: adjustment.deepCopy(),
      weight: adjustment is DurationAdjustment ? -1.0 : 1.0,
    );
    final newMetric = await Navigator.push<RatingMetric>(
      context,
      MaterialPageRoute(builder: (context) => switch (seed.adjustment) {
        BooleanAdjustment()     => BooleanMetricPage.template(metric: seed),
        CategoricalAdjustment() => CategoricalMetricPage.template(metric: seed),
        StepAdjustment()        => StepMetricPage.template(metric: seed),
        NumericalAdjustment()   => NumericalMetricPage.template(metric: seed),
        TextAdjustment()        => TextMetricPage.template(metric: seed),
        DurationAdjustment()    => DurationMetricPage.template(metric: seed),
      }),
    );
    if (newMetric == null) return;
    setState(() => _metrics.add(newMetric));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _editMetric(RatingMetric metric, {VoidCallback? onChanged}) async {
    final editedMetric = await Navigator.push<RatingMetric>(
      context,
      MaterialPageRoute(builder: (context) => switch (metric.adjustment) {
        BooleanAdjustment()     => BooleanMetricPage.edit(metric: metric),
        CategoricalAdjustment() => CategoricalMetricPage.edit(metric: metric),
        StepAdjustment()        => StepMetricPage.edit(metric: metric),
        NumericalAdjustment()   => NumericalMetricPage.edit(metric: metric),
        TextAdjustment()        => TextMetricPage.edit(metric: metric),
        DurationAdjustment()    => DurationMetricPage.edit(metric: metric),
      }),
    );
    if (editedMetric == null) return;
    setState(() {
      final index = _metrics.indexOf(metric);
      if (index != -1) {
        _metrics[index] = editedMetric;
      }
    });
    _changeListener();
    onChanged?.call();
  }

  Future<void> _duplicateMetric(RatingMetric metric, {VoidCallback? onChanged}) async {
    final seed = metric.deepCopy();
    final newMetric = await Navigator.push<RatingMetric>(
      context,
      MaterialPageRoute(builder: (context) => switch (seed.adjustment) {
        BooleanAdjustment()     => BooleanMetricPage.duplicate(metric: seed),
        CategoricalAdjustment() => CategoricalMetricPage.duplicate(metric: seed),
        StepAdjustment()        => StepMetricPage.duplicate(metric: seed),
        NumericalAdjustment()   => NumericalMetricPage.duplicate(metric: seed),
        TextAdjustment()        => TextMetricPage.duplicate(metric: seed),
        DurationAdjustment()    => DurationMetricPage.duplicate(metric: seed),
      }),
    );
    if (newMetric == null) return;
    setState(() => _metrics.add(newMetric));
    _changeListener();
    onChanged?.call();
  }

  Future<void> removeMetric(RatingMetric metric, {VoidCallback? onChanged}) async {
    setState(() => _metrics.remove(metric));
    _changeListener();
    onChanged?.call();
  }

  void _saveRating() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;

    Navigator.pop(context, Rating(
      id: widget.mode == RatingPageMode.edit ? widget.rating?.id : null,
      name: name,
      notes: notes.isEmpty ? null : notes,
      filter: _ratingAssociation.filter,
      filterType: _ratingAssociation.filterType,
      metrics: List.from(_metrics),
      orderIndex: widget.rating?.orderIndex ?? 0,
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

  void _onReorderMetrics(int oldIndex, int newIndex, {VoidCallback? onChanged}) {
    setState(() {
      final metric = _metrics.removeAt(oldIndex);
      _metrics.insert(newIndex, metric);
    });
    _changeListener();
    onChanged?.call();
  }

  Widget _nameField() {
    return TextFormField(
      controller: _nameController,
      onFieldSubmitted: (_) => _saveRating(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: widget.mode == RatingPageMode.add,
      onChanged: (value) => setState(() {}), // see filled/fillColor
      decoration: InputDecoration(
        labelText: 'Rating Name',
        border: const OutlineInputBorder(),
        hintText: 'Enter rating name',
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == RatingPageMode.edit && _nameController.text.trim() != widget.rating?.name,
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return 'Name is required';
        return null;
      },
    );
  }

  DropdownMenuItem<RatingAssociation> _invalidFilterDropdownMenuItem(RatingAssociation ra) {
    return DropdownMenuItem<RatingAssociation>(
      value: ra,
      child: Row(
        spacing: 8,
        children: [
          Icon(
            switch (ra.filterType) {
              FilterType.bike => Bike.iconData,
              FilterType.component => ComponentType.other.getIconData(),
              FilterType.componentType => ComponentType.other.getIconData(),
              FilterType.person => Person.iconData,
              FilterType.global => Icons.error,
            },
            color: Theme.of(context).colorScheme.error
          ),
          Expanded(child: Text(
            switch (ra.filterType) {
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
    );
  }

  DropdownMenuItem<RatingAssociation?> _dropdownMenuSection(String label) {
    return DropdownMenuItem<RatingAssociation?>(
      enabled: false,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  DropdownMenuItem<RatingAssociation> _dropdownMenuItemGlobal(GlobalRatingAssociation gra) {
    return DropdownMenuItem<RatingAssociation>(
      value: gra,
      child: const Row(
        spacing: 8,
        children: [
          Icon(Icons.circle_outlined),
          Expanded(child: Text("Apply everywhere", overflow: TextOverflow.ellipsis))
        ],
      ),
    );
  }

  DropdownMenuItem<RatingAssociation> _dropdownMenuItemBike(
    BikeRatingAssociation bra,
    Map<String, Bike> bikes,
  ) {
    final bike = bikes[bra.bikeId];
    if (bike == null) return _invalidFilterDropdownMenuItem(bra);

    return DropdownMenuItem<RatingAssociation>(
      value: bra,
      child: Row(
        spacing: 8,
        children: [
          const Icon(Bike.iconData),
          Expanded(child: Text(bike.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  DropdownMenuItem<RatingAssociation> _dropdownMenuItemComponentType(
    ComponentTypeRatingAssociation ctra,
  ) {
    final componentType = ComponentType.values.firstWhere(
      (ct) => ct.toString() == ctra.componentTypeStr,
      orElse: () => ComponentType.frame,
    );
    return DropdownMenuItem<RatingAssociation>(
      value: ctra,
      child: Row(
        spacing: 8,
        children: [
          Icon(componentType.getIconData()),
          Expanded(child: Text(componentType.label, overflow: TextOverflow.ellipsis))
        ],
      ),
    );
  }

  DropdownMenuItem<RatingAssociation> _dropdownMenuItemComponent(
    ComponentRatingAssociation cra,
    Map<String, Bike> bikes,
    Map<String, Component> components,
  ) {
    final component = components[cra.componentId];
    if (component == null) return _invalidFilterDropdownMenuItem(cra);

    return DropdownMenuItem<RatingAssociation>(
      value: cra,
      child: Row(
        spacing: 8,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              spacing: 8,
              children: [
                Icon(component.componentType.getIconData()),
                Expanded(child: Text(component.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  switch (component.latestInstallation) {
                    Archival() => Icons.inventory_2_outlined,
                    BikeInstallation() => Bike.iconData,
                    Uninstallation() || null => Icons.shelves,
                  },
                  color: switch (component.latestInstallation) {
                    BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                    _ => null,
                  },
                ),
                Expanded(child: Text(
                  switch (component.latestInstallation) {
                    Archival() => "Archived",
                    BikeInstallation(:final bikeId) => bikes[bikeId]?.name ?? "BIKE NOT FOUND",
                    Uninstallation() || null => "Not installed",
                  },
                  style: switch (component.latestInstallation) {
                    BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => TextStyle(color: Theme.of(context).colorScheme.error),
                    _ => null,
                  },
                  overflow: TextOverflow.ellipsis
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<RatingAssociation> _dropdownMenuItemPerson(
    PersonRatingAssociation pra,
    Map<String, Person> persons,
  ) {
    final person = persons[pra.personId];
    if (person == null) return _invalidFilterDropdownMenuItem(pra);

    return DropdownMenuItem<RatingAssociation>(
      value: pra,
      child: Row(
        spacing: 8,
        children: [
          const Icon(Person.iconData),
          Expanded(child: Text(person.name, overflow: TextOverflow.ellipsis))
        ],
      ),
    );
  }

  Widget _notesField() {
    return TextFormField(
      controller: _notesController,
      minLines: 2,
      maxLines: null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) => setState(() {}), // see filled/fillColor
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Describe the rating procedure, guidelines, instructions, ...',
        border: const OutlineInputBorder(),
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == RatingPageMode.edit && _notesController.text.trim() != (widget.rating?.notes ?? ""),
      ),
    );
  }

  List<DropdownMenuItem<RatingAssociation?>> _buildFilterDropdownItems(
    List<RatingAssociation> filterOptions,
    Map<String, Bike> bikes,
    Map<String, Person> persons,
    Map<String, Component> components,
  ) {
    final items = <DropdownMenuItem<RatingAssociation?>>[];

    // Global
    items.add(_dropdownMenuSection("Global"));
    if (!filterOptions.contains(_ratingAssociation) && _ratingAssociation.filterType == FilterType.global) {
      items.add(_invalidFilterDropdownMenuItem(_ratingAssociation));
    }
    items.addAll(
      filterOptions.whereType<GlobalRatingAssociation>().map((gra) => _dropdownMenuItemGlobal(gra)),
    );

    // Bikes
    items.add(_dropdownMenuSection("Bikes"));
    if (!filterOptions.contains(_ratingAssociation) && _ratingAssociation.filterType == FilterType.bike) {
      items.add(_invalidFilterDropdownMenuItem(_ratingAssociation));
    }
    items.addAll(
      filterOptions.whereType<BikeRatingAssociation>().map((bra) => _dropdownMenuItemBike(bra, bikes)),
    );

    // Component Types
    items.add(_dropdownMenuSection("Component Types"));
    if (!filterOptions.contains(_ratingAssociation) && _ratingAssociation.filterType == FilterType.componentType) {
      items.add(_invalidFilterDropdownMenuItem(_ratingAssociation));
    }
    items.addAll(
      filterOptions.whereType<ComponentTypeRatingAssociation>().map((ctra) => _dropdownMenuItemComponentType(ctra)),
    );

    // Components
    items.add(_dropdownMenuSection("Components"));
    if (!filterOptions.contains(_ratingAssociation) && _ratingAssociation.filterType == FilterType.component) {
      items.add(_invalidFilterDropdownMenuItem(_ratingAssociation));
    }
    items.addAll(
      filterOptions.whereType<ComponentRatingAssociation>().map((cra) => _dropdownMenuItemComponent(cra, bikes, components)),
    );

    // Persons
    items.add(_dropdownMenuSection("Persons"));
    if (!filterOptions.contains(_ratingAssociation) && _ratingAssociation.filterType == FilterType.person) {
      items.add(_invalidFilterDropdownMenuItem(_ratingAssociation));
    }
    items.addAll(
      filterOptions.whereType<PersonRatingAssociation>().map((pra) => _dropdownMenuItemPerson(pra, persons)),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final persons = appRepository.persons;
    final components = appRepository.components;

    final preSelectedComponentId = (_ratingAssociation is ComponentRatingAssociation)
        ? (_ratingAssociation as ComponentRatingAssociation).componentId
        : null;

    final List<RatingAssociation> filterOptions = [
      const GlobalRatingAssociation(),
      ...bikes.values.map((b) => BikeRatingAssociation(b.id)),
      ...ComponentType.values.map((ct) => ComponentTypeRatingAssociation(ct.toString())),
      ...(() {
        final sortedComponents = components.values
          .where((c) => !c.isArchived || c.id == preSelectedComponentId)
          .toList()
          ..sort((a, b) => (a.bike ?? "").compareTo(b.bike ?? ""));
        return sortedComponents.map((c) => ComponentRatingAssociation(c.id));
      })(),
      ...persons.values.map((p) => PersonRatingAssociation(p.id)),
    ];

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
        body: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _nameField(),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<RatingAssociation?>(
                          initialValue: _ratingAssociation,
                          isExpanded: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Filter',
                            border: const OutlineInputBorder(),
                            hintText: "Choose an object which the filter should be applied for",
                            fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                            filled: widget.mode == RatingPageMode.edit && _ratingAssociation.filter != widget.rating?.filter,
                          ),
                          validator: (RatingAssociation? newValue) {
                            if (newValue == null || !filterOptions.contains(newValue)) return "Invalid Filter.";
                            return null;
                          },
                          items: _buildFilterDropdownItems(
                            filterOptions,
                            bikes,
                            persons,
                            components,
                          ),
                          onChanged: (RatingAssociation? newValue) {
                            setState(() => _ratingAssociation = newValue ?? const GlobalRatingAssociation());
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
                        Visibility(
                          visible: _expanded,
                          maintainState: true,
                          child: Column(
                            children: [
                              _notesField(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Divider(height: 1),
                  const SectionTitle(title: "Metrics"),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FormField<List<RatingMetric>>(
                      initialValue: _metrics,
                      validator: (_) { // Evaluate _metrics for robustness
                        if (_metrics.isEmpty) {
                          return 'You need to add at least one metric';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      builder: (FormFieldState<List<RatingMetric>> field) {
                        void notify() => field.didChange(List.from(_metrics));

                        void showAddBottomSheet() => showRatingAddAdjustmentBottomSheet(
                          context: context,
                          addAdjustmentFromPreset: (a) => _addMetricFromPreset(a, onChanged: notify),
                          addAdjustment: <T extends Adjustment>() => _addMetric<T>(onChanged: notify),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _metrics.isNotEmpty
                                ? AdjustmentEditList(
                                    adjustments: _metrics.map((m) => m.adjustment).toList(),
                                    metricWeights: {for (final m in _metrics) m.id: m.weight},
                                    initialAdjustments: widget.mode == RatingPageMode.edit
                                        ? {for (final m in widget.rating!.metrics) m.id: m.adjustment}
                                        : null,
                                    editAdjustment: (a) => _editMetric(_metrics.firstWhere((m) => m.id == a.id), onChanged: notify),
                                    duplicateAdjustment: (a) => _duplicateMetric(_metrics.firstWhere((m) => m.id == a.id), onChanged: notify),
                                    removeAdjustment: (a) => removeMetric(_metrics.firstWhere((m) => m.id == a.id), onChanged: notify),
                                    onReorderAdjustments: (oldIndex, newIndex) => _onReorderMetrics(oldIndex, newIndex, onChanged: notify),
                                  )
                                : EmptyStatePlaceholder2(
                                    title: "No metrics yet",
                                    errorTitle: field.errorText,
                                    subtitle: "Tap 'Add Metric' to define metrics to evaluate setups",
                                    errorSubtitle: "Tap here to add the first metric", 
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
                            if (field.hasError && _metrics.isNotEmpty)
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
