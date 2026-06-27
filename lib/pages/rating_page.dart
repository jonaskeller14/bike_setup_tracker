import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/rating_metric.dart';
import '../repositories/app_repository.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/dialogs/discard_changes.dart';
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

class _FilterFilterType {
  final String? filter;
  final FilterType filterType;

  const _FilterFilterType(this.filter, this.filterType);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FilterFilterType &&
          filter == other.filter &&
          filterType == other.filterType;

  @override
  int get hashCode => filter.hashCode ^ filterType.hashCode;
}

class _FilterFilterTypeBike extends _FilterFilterType {
  final Bike bike;
  const _FilterFilterTypeBike(super.filter, super.filterType, this.bike);
}

class _FilterFilterTypeComponent extends _FilterFilterType {
  final Component component;
  const _FilterFilterTypeComponent(super.filter, super.filterType, this.component);
}

class _FilterFilterTypeComponentType extends _FilterFilterType {
  final ComponentType componentType;
  const _FilterFilterTypeComponentType(super.filter, super.filterType, this.componentType);
}

class _FilterFilterTypePerson extends _FilterFilterType {
  final Person person;
  const _FilterFilterTypePerson(super.filter, super.filterType, this.person);
}

class _RatingPageState extends State<RatingPage> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  bool _expanded = false;

  late List<RatingMetric> _metrics;
  late List<RatingMetric> _initialMetrics;
  late _FilterFilterType _filterFilterType;
  late _FilterFilterType _initialFilterFilterType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rating?.name);
    _nameController.addListener(_changeListener);
    _metrics = widget.rating == null
        ? []
        : List.from(widget.rating!.metrics);
    _initialMetrics = List.from(_metrics);


    _initialFilterFilterType = _FilterFilterType(
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
      filter: _filterFilterType.filter,
      filterType: _filterFilterType.filterType,
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

  Widget _emptyAdjustmentsInfo({String? errorText, VoidCallback? onTap}) {
    return InkWell(
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
    );
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
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == RatingPageMode.edit && _nameController.text.trim() != widget.rating?.name,
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return 'Name is required';
        return null;
      },
    );
  }

  DropdownMenuItem<_FilterFilterType> _invalidFilterDropdownMenuItem(_FilterFilterType fft) {
    return DropdownMenuItem<_FilterFilterType>(
      value: fft,
      child: Row(
        spacing: 8,
        children: [
          Icon(
            switch (fft.filterType) {
              FilterType.bike => Bike.iconData,
              FilterType.component => ComponentType.other.getIconData(),
              FilterType.componentType => ComponentType.other.getIconData(),
              FilterType.person => Person.iconData,
              FilterType.global => Icons.error,
            }, 
            color: Theme.of(context).colorScheme.error
          ),
          Expanded(child: Text(
            switch (fft.filterType) {
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

  DropdownMenuItem<_FilterFilterType?> _dropdownMenuSection(String label) {
    return DropdownMenuItem<_FilterFilterType?>(
      enabled: false,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  DropdownMenuItem<_FilterFilterType> _dropdownMenuItemGlobal(_FilterFilterType fft) {
    return DropdownMenuItem<_FilterFilterType>(
      value: fft,
      child: const Row(
        spacing: 8,
        children: [
          Icon(Icons.circle_outlined),
          Expanded(child: Text("Apply everywhere", overflow: TextOverflow.ellipsis))
        ],
      ),
    );
  }

  DropdownMenuItem<_FilterFilterType> _dropdownMenuItemBike(_FilterFilterTypeBike fftb) {
    return DropdownMenuItem<_FilterFilterType>(
      value: fftb,
      child: Row(
        spacing: 8,
        children: [
          const Icon(Bike.iconData),
          Expanded(child: Text(fftb.bike.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  DropdownMenuItem<_FilterFilterType> _dropdownMenuItemComponentType(_FilterFilterTypeComponentType fftct) {
    return DropdownMenuItem<_FilterFilterType>(
      value: fftct,
      child: Row(
        spacing: 8,
        children: [
          Icon(fftct.componentType.getIconData()),
          Expanded(child: Text(fftct.componentType.label, overflow: TextOverflow.ellipsis))
        ],
      ),
    );
  }

  DropdownMenuItem<_FilterFilterType> _dropdownMenuItemComponent(_FilterFilterTypeComponent fftc) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;

    return DropdownMenuItem<_FilterFilterType>(
      value: fftc,
      child: Row(
        spacing: 8,
        children: [
          Flexible(
            fit: FlexFit.tight, 
            child: Row(
              spacing: 8,
              children: [
                Icon(fftc.component.componentType.getIconData()),
                Expanded(child: Text(fftc.component.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  fftc.component.bike != null ? Bike.iconData : Icons.shelves,
                  color: fftc.component.bike == null || bikes.containsKey(fftc.component.bike) 
                      ? null
                      : Theme.of(context).colorScheme.error,
                ), 
                Expanded(child: Text(
                  fftc.component.bike == null
                      ? "Not installed"
                      : bikes[fftc.component.bike]?.name ?? "BIKE NOT FOUND",
                  style: fftc.component.bike == null || bikes.containsKey(fftc.component.bike) 
                      ? null 
                      : TextStyle(color: Theme.of(context).colorScheme.error), 
                  overflow: TextOverflow.ellipsis
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<_FilterFilterType> _dropdownMenuItemPerson(_FilterFilterTypePerson fftp) {
    return DropdownMenuItem<_FilterFilterType>(
      value: fftp,
      child: Row(
        spacing: 8,
        children: [
          const Icon(Person.iconData),
          Expanded(child: Text(fftp.person.name, overflow: TextOverflow.ellipsis))
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
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == RatingPageMode.edit && _notesController.text.trim() != (widget.rating?.notes ?? ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final persons = appRepository.persons;
    final components = appRepository.components;

    final List<_FilterFilterType> filterOptions = [
      const _FilterFilterType(null, FilterType.global),
      ...bikes.values.map((b) => _FilterFilterTypeBike(b.id, FilterType.bike, b)),
      ...ComponentType.values.map((ct) => _FilterFilterTypeComponentType(ct.toString(), FilterType.componentType, ct)),
      ...(() {
        final sortedComponents = components.values.toList()
          ..sort((a, b) => (a.bike ?? "").compareTo(b.bike ?? ""));
        return sortedComponents.map((c) => _FilterFilterTypeComponent(c.id, FilterType.component, c));
      })(),
      ...persons.values.map((p) => _FilterFilterTypePerson(p.id, FilterType.person, p)),
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
                        DropdownButtonFormField<_FilterFilterType?>(
                          initialValue: _filterFilterType,
                          isExpanded: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Filter',
                            border: const OutlineInputBorder(),
                            hintText: "Choose an object which the filter should be applied for",
                            fillColor: Colors.orange.withValues(alpha: 0.08),
                            filled: widget.mode == RatingPageMode.edit && _filterFilterType.filter != widget.rating?.filter,
                          ),
                          validator: (_FilterFilterType? newValue) {
                            if (!filterOptions.contains(newValue)) return "Invalid Filter.";
                            return null;
                          },
                          items: [
                            if (!filterOptions.contains(_filterFilterType) && _filterFilterType.filterType == FilterType.global)
                              _invalidFilterDropdownMenuItem(_filterFilterType),
                            ...filterOptions.where((fo) => fo.filterType == FilterType.global).map((fft) => _dropdownMenuItemGlobal(fft)),

                            _dropdownMenuSection("Bikes"),
                            if (!filterOptions.contains(_filterFilterType) && _filterFilterType.filterType == FilterType.bike)
                              _invalidFilterDropdownMenuItem(_filterFilterType),
                            ...filterOptions.whereType<_FilterFilterTypeBike>().map((fftb) => _dropdownMenuItemBike(fftb)),

                            _dropdownMenuSection("Component Types"),
                            if (!filterOptions.contains(_filterFilterType) && _filterFilterType.filterType == FilterType.componentType)
                              _invalidFilterDropdownMenuItem(_filterFilterType),
                            ...filterOptions.whereType<_FilterFilterTypeComponentType>().map((fftct) => _dropdownMenuItemComponentType(fftct)),

                            _dropdownMenuSection("Components"),
                            if (!filterOptions.contains(_filterFilterType) && _filterFilterType.filterType == FilterType.component)
                              _invalidFilterDropdownMenuItem(_filterFilterType),
                            ...filterOptions.whereType<_FilterFilterTypeComponent>().map((fftc) => _dropdownMenuItemComponent(fftc)),

                            _dropdownMenuSection("Persons"),
                            if (!filterOptions.contains(_filterFilterType) && _filterFilterType.filterType == FilterType.person)
                              _invalidFilterDropdownMenuItem(_filterFilterType),
                            ...filterOptions.whereType<_FilterFilterTypePerson>().map((fftp) => _dropdownMenuItemPerson(fftp)),
                          ],
                          onChanged: (_FilterFilterType? newValue) {
                            setState(() => _filterFilterType = newValue ?? const _FilterFilterType(null, FilterType.global));
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
