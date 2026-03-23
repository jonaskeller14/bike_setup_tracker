import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/adjustment/adjustment.dart';
import '../repositories/app_repository.dart';
import '../widgets/set_installation_timeline.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import 'adjustment/text_adjustment_page.dart';
import 'adjustment/duration_adjustment_page.dart';
import '../widgets/adjustment_edit_list.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/sheets/component_add_adjustment.dart';
import '../widgets/dashed_border_painter.dart';

enum ComponentPageMode {
  add,
  edit,
  duplicate,
}

class ComponentPage extends StatefulWidget {
  final Component? component;
  final ComponentPageMode mode;
  final Object? initialBike;

  const ComponentPage._({super.key, this.component, required this.mode, this.initialBike});

  factory ComponentPage.add({Key? key, Object? initialBike = const _Sentinel()}) => 
    ComponentPage._(key: key, mode: ComponentPageMode.add, initialBike: initialBike);

  factory ComponentPage.edit({Key? key, required Component component}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.edit);

  factory ComponentPage.duplicate({Key? key, required Component component}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.duplicate);

  @override
  State<ComponentPage> createState() => _ComponentPageState();
}

class _ComponentPageState extends State<ComponentPage> {
  static const _enableDurationAdjustment = false;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;
  late List<Installation> _installations;
  late String? _bike;
  late String? _initialBike;
  late ComponentType? _componentType;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.component?.name);
    _nameController.addListener(_changeListener);
    _adjustments = widget.component == null 
        ? [] 
        : List.from(widget.component!.adjustments);
    _initialAdjustments = List.from(_adjustments);
    
    final appRepository = context.read<AppRepository>();
    _initialBike = widget.component != null 
        ? widget.component!.bike 
        : widget.initialBike is _Sentinel
            ? appRepository.filteredBikes.keys.firstOrNull
            : widget.initialBike as String?;    
    _bike = _initialBike;

    _installations = widget.component?.installations ?? (context.read<AppSettings>().enableInstallationTimeline ? [Installation.sinceBeginning(parent: _initialBike)] : []);

    _componentType = widget.component?.componentType;
    _notesController = TextEditingController(text: widget.component?.notes);
    _notesController.addListener(_changeListener);
    if (widget.mode != ComponentPageMode.add) _expanded = true;
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.component?.name ?? '') || 
        _notesController.text.trim() != (widget.component?.notes ?? '') ||
        _bike != _initialBike || 
        _componentType != widget.component?.componentType ||
        !listEquals(_installations, widget.component?.installations ?? []) || //FIXME
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
        const (BooleanAdjustment)       => BooleanAdjustmentPage.add(categories: {AdjustmentCategory.component}),
        const (CategoricalAdjustment)   => CategoricalAdjustmentPage.add(categories: {AdjustmentCategory.component}),
        const (StepAdjustment)          => StepAdjustmentPage.add(categories: {AdjustmentCategory.component}),
        const (NumericalAdjustment)     => NumericalAdjustmentPage.add(categories: {AdjustmentCategory.component}),
        const (TextAdjustment)          => TextAdjustmentPage.add(categories: {AdjustmentCategory.component}),
        const (DurationAdjustment)      => DurationAdjustmentPage.add(categories: {AdjustmentCategory.component}),
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
        BooleanAdjustment a     => BooleanAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.component}),
        CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.component}),
        StepAdjustment a        => StepAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.component}),
        NumericalAdjustment a   => NumericalAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.component}),
        TextAdjustment a        => TextAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.component}),
        DurationAdjustment a    => DurationAdjustmentPage.template(adjustment: a, categories: {AdjustmentCategory.component}),
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
        BooleanAdjustment a     => BooleanAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.component}),
        CategoricalAdjustment a => CategoricalAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.component}),
        StepAdjustment a        => StepAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.component}),
        NumericalAdjustment a   => NumericalAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.component}),
        TextAdjustment a        => TextAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.component}),
        DurationAdjustment a    => DurationAdjustmentPage.edit(adjustment: a, categories: {AdjustmentCategory.component}),
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
        BooleanAdjustment a     => BooleanAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.component}),
        CategoricalAdjustment a => CategoricalAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.component}),
        StepAdjustment a        => StepAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.component}),
        NumericalAdjustment a   => NumericalAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.component}),
        TextAdjustment a        => TextAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.component}),
        DurationAdjustment a    => DurationAdjustmentPage.duplicate(adjustment: a, categories: {AdjustmentCategory.component}),
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

  void _saveComponent() {
    final appSettings = context.read<AppSettings>();
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;
    
    final updatedComponent = Component(
      id: widget.mode == ComponentPageMode.edit ? widget.component?.id : null, 
      name: name,
      componentType: _componentType!,
      installations: appSettings.enableInstallationTimeline ? _installations : [Installation.sinceBeginning(parent: _bike)],
      notes: notes.isEmpty ? null : notes,
      adjustments: _adjustments,
    );

    Navigator.pop(context, updatedComponent);
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
                    errorText ?? "No adjustments yet",
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
                        ? "Tap here to add the first adjustment" 
                        : "Tap 'Add Adjustment' to define settings for this component",
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
              _buildGuideRow(NumericalAdjustment.iconData, "Numerical", "Pressure (psi/bar), Length, Angle, Weight"),
              _buildGuideRow(StepAdjustment.iconData, "Step", "Rebound/Compression Clicks, Spacers"),
              _buildGuideRow(CategoricalAdjustment.iconData, "Categorical", "Tire Compound (Soft/Hard), Model, Brand"),
              _buildGuideRow(BooleanAdjustment.iconData, "On/Off", "Lockout Lever, Climb Switch, Tire insert installed?"),
              if (context.read<AppSettings>().enableTextAdjustment)
                _buildGuideRow(TextAdjustment.iconData, "Text", "Flexible field for any other setup specifications"),
              if (_enableDurationAdjustment)
                _buildGuideRow(DurationAdjustment.iconData, "Duration", "Time span"),  //TODO: improve help text
            ],
          ),
        ),
      ],
    );
  }

  Widget _nameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: widget.mode == ComponentPageMode.add,
      onChanged: (value) => setState(() {}), // see filled/fillColor
      decoration: InputDecoration(
        labelText: 'Component Name',
        border: OutlineInputBorder(),
        hintText: 'Enter component name',
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == ComponentPageMode.edit && _nameController.text.trim() != widget.component?.name,
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return 'Name is required';
        return null;
      },
    );
  }

  Widget _componentTypeField({required int existingComponentsCount}) {
    return DropdownButtonFormField<Object?>(
      initialValue: _componentType,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      hint: const Text("Please select type"),
      decoration: InputDecoration(
        labelText: 'Type',
        border: OutlineInputBorder(),
        hintText: "Choose a type for this component",
        helperText: existingComponentsCount > 0
            ? Intl.plural(
                existingComponentsCount,
                one: "WARNING: There is one ${_componentType?.label}-Component already installed on this bike.",
                other: "WARNING: There are $existingComponentsCount ${_componentType?.label}-Components already installed on this bike.",
              )
            : null,
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == ComponentPageMode.edit && _componentType != widget.component?.componentType,
      ),
      items: () {
        final items = <DropdownMenuItem<Object?>>[];
        for (final category in ComponentTypeCategory.values) {
          items.add(
            DropdownMenuItem<Object?>(
              enabled: false,
              value: category,
              child: Text(
                category.label.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
              ),
            ),
          );
          items.addAll(
            ComponentType.values
                .where((t) => t.category == category)
                .map((componentType) {
              return DropdownMenuItem<Object?>(
                value: componentType,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Icon(componentType.getIconData()),
                    Expanded(child: Text(componentType.label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            })
          );
        }
        return items;
      }(),
      onChanged: (Object? newComponentType) {
        if (newComponentType == null || newComponentType is! ComponentType) return;
        setState(() {
          _componentType = newComponentType;
        });
        _changeListener();
      },
      validator: (Object? value) {
        if (value == null || value is! ComponentType) {
          return 'Component type cannot be empty. You can edit it later.';
        }
        return null;
      },
    );
  }

  Widget _notesField() {
    return TextFormField(
      controller: _notesController,
      minLines: 2,
      maxLines: null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Enter brand, model, serial number, costs, ...',
        border: OutlineInputBorder(),
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == ComponentPageMode.edit && _notesController.text.trim() != (widget.component?.notes ?? ""),
      ),
    );
  }

  Widget _bikesDropdownField({required Map<String, Bike> bikes}) {
    return DropdownButtonFormField<String?>(
      initialValue: _bike,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Bike',
        border: OutlineInputBorder(),
        hintText: "Choose a bike for this component",
        helperText: _bike == null ? "WARNING: Select Bike to install Component." : null,
        fillColor: Colors.orange.withValues(alpha: 0.08),
        filled: widget.mode == ComponentPageMode.edit && _bike != _initialBike,
      ),
      validator: (String? newBike) {
        if (newBike is String && !bikes.containsKey(newBike)) return "Please select valid bike";
        return null;
      },
      items: bikes.values.map((b) {
        return DropdownMenuItem<String?>(
          value: b.id,
          child: Row(
            spacing: 8,
            children: [
              const Icon(Bike.iconData),
              Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis))
            ],
          ),
        );
      }).toList() + [
        DropdownMenuItem<String?>(
          value: null,
          child: Row(
            spacing: 8,
            children: [
              const Icon(Icons.shelves),
              Expanded(child: Text("NOT INSTALLED", overflow: TextOverflow.ellipsis))
            ],
          ),
        ),
        if (_bike != null && !bikes.containsKey(_bike))
          DropdownMenuItem<String?>(
            value: _bike,
            child: Row(
              spacing: 8,
              children: [
                Icon(Bike.iconData, color: Theme.of(context).colorScheme.error),
                Expanded(child: Text("BIKE NOT FOUND", overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              ],
            ),
          ),
      ],
      onChanged: (String? newBike) {
        setState(() => _bike = newBike);
        _changeListener();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final bikes = appRepository.bikes;
    final existingComponentsCount = appRepository.components.values.where((c) => c.bike == _bike && c.componentType == _componentType && widget.component?.id != c.id).length;

    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            ComponentPageMode.add || ComponentPageMode.duplicate => const Text('Add Component'),
            ComponentPageMode.edit => const Text('Edit Component'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveComponent),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _nameField(),
                  const SizedBox(height: 12),
                  _componentTypeField(existingComponentsCount: existingComponentsCount),
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
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    _notesField(),
                  ],

                  const SizedBox(height: 12),
                  if (appSettings.enableInstallationTimeline)
                    SetInstallationTimeline(
                      initialInstallations: _installations,
                      originalInstallations: widget.mode == ComponentPageMode.edit ? widget.component?.installations : null,
                      onChanged: (newInstallations) {
                        setState(() => _installations = List.from(newInstallations));
                        _changeListener();
                      },
                    )
                  else
                    _bikesDropdownField(bikes: bikes),

                  const SizedBox(height: 12),                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text("Adjustments", style: Theme.of(context).textTheme.titleMedium),
                  ),
                  FormField<List<Adjustment>>(
                    initialValue: _adjustments,
                    validator: (_) { // Evaluate _adjustments for robustness
                      if (_adjustments.isEmpty) {
                        return 'You need to add at least one adjustment';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    builder: (FormFieldState<List<Adjustment>> field) {
                      void notify() => field.didChange(List.from(_adjustments));
  
                      void showAddBottomSheet() => showComponentAddAdjustmentBottomSheet(
                        context: context,
                        componentType: _componentType,
                        enableDurationAdjustment: _enableDurationAdjustment,
                        addAdjustmentFromPreset: (a) => _addAdjustmentFromPreset(a, onChanged: notify),
                        addAdjustment: <T extends Adjustment>() => _addAdjustment<T>(onChanged: notify),
                      );
  
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _adjustments.isNotEmpty
                              ? AdjustmentEditList(
                                  adjustments: _adjustments,
                                  initialAdjustments: widget.mode == ComponentPageMode.edit 
                                      ? Map.fromEntries(widget.component!.adjustments.map((a) => MapEntry(a.id, a))) 
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
                              label: const Text("Add Adjustment"),
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
      ),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
