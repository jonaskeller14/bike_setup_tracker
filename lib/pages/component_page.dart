import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/component_preset.dart';
import '../models/context/context_position.dart';
import '../models/installation.dart';
import '../repositories/app_repository.dart';
import '../repositories/component_preset_repository.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../utils/component_preset_application.dart';
import '../utils/component_preset_search.dart';
import '../widgets/dialogs/apply_preset_adjustments.dart';
import '../widgets/dialogs/discard_changes.dart';
import '../widgets/empty_state_placeholder2.dart';
import '../widgets/lists/adjustment_edit_list.dart';
import '../widgets/preset_catalog_card.dart';
import '../widgets/set_installation_timeline.dart';
import '../widgets/sheets/component_add_adjustment.dart';
import '../widgets/sheets/component_preset_picker.dart';
import '../widgets/text/section_title.dart';
import 'adjustment/boolean_adjustment_page.dart';
import 'adjustment/categorical_adjustment_page.dart';
import 'adjustment/duration_adjustment_page.dart';
import 'adjustment/numerical_adjustment_page.dart';
import 'adjustment/sag_adjustment_page.dart';
import 'adjustment/step_adjustment_page.dart';
import 'adjustment/text_adjustment_page.dart';

enum ComponentPageMode {
  add,
  edit,
  duplicate,
  replace,
}

class ComponentPage extends StatefulWidget {
  final Component? component;
  final ComponentPageMode mode;
  final Object? initialBike;
  final DateTime? replacementDate;

  const ComponentPage._({super.key, this.component, required this.mode, this.initialBike, this.replacementDate});

  factory ComponentPage.add({Key? key, Object? initialBike = const _Sentinel()}) => 
    ComponentPage._(key: key, mode: ComponentPageMode.add, initialBike: initialBike);

  factory ComponentPage.edit({Key? key, required Component component}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.edit);

  factory ComponentPage.duplicate({Key? key, required Component component}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.duplicate);
  
  factory ComponentPage.replace({Key? key, required Component component, required DateTime replacementDate}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.replace, replacementDate: replacementDate);

  @override
  State<ComponentPage> createState() => _ComponentPageState();
}

class _ComponentPageState extends State<ComponentPage> {
  static const _enableDurationAdjustment = false;
  final _formKey = GlobalKey<FormState>();
  bool _formHasChanges = false;
  late TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();
  late TextEditingController _notesController;
  late TextEditingController _initialDistanceController;
  late TextEditingController _initialElevationGainController;
  late TextEditingController _initialMovingTimeController;
  late TextEditingController _initialElapsedTimeController;
  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;
  final Map<String, ValueUnitConversion> _pendingConversions = {};
  late List<Installation> _installations;
  late ComponentType? _componentType;
  late ComponentType? _initialComponentType;
  late List<Installation> _initialInstallations;
  bool _expanded = false;

  List<Adjustment>? _lastPresetAdjustments;
  VoidCallback? _adjustmentsFieldNotify;

  /// Cross-type catalog index for the name-field autocomplete (C2), loaded once
  /// and cached. Null until loaded; the autocomplete simply shows nothing until
  /// then.
  List<ComponentPresetVariant>? _presetIndex;
  bool _presetIndexLoading = false;

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
    final initialBike = widget.component != null 
        ? widget.component!.bike 
        : widget.initialBike is _Sentinel
            ? appRepository.filteredBikes.keys.firstOrNull
            : widget.initialBike as String?;

    if (widget.mode == ComponentPageMode.replace) {
      _installations = [Installation(parent: initialBike, dateTimeUTC: widget.replacementDate!.toUtc(), dateTimeLocal: widget.replacementDate!.toLocal())];
    } else {
      _installations = widget.component?.installations ?? [Installation.sinceBeginning(parent: initialBike)];
    }
    _installations.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    _initialInstallations = List.from(_installations);

    _componentType = widget.component?.componentType;
    _initialComponentType = _componentType;

    _notesController = TextEditingController(text: widget.component?.notes);
    _notesController.addListener(_changeListener);

    final appSettings = context.read<AppSettings>();
    final initialDistance = AppSettings.convertDistanceFromMeters(widget.component?.initialDistance, appSettings.distanceUnit) ?? 0.0;
    _initialDistanceController = TextEditingController(text: initialDistance.toString());
    _initialDistanceController.addListener(_changeListener);
    final initialElevation = AppSettings.convertElevationFromMeters(widget.component?.initialElevationGain, appSettings.altitudeUnit) ?? 0.0;
    _initialElevationGainController = TextEditingController(text: initialElevation.toString());
    _initialElevationGainController.addListener(_changeListener);
    _initialMovingTimeController = TextEditingController(text: widget.component?.initialMovingTime.inHours.toString() ?? "0");
    _initialMovingTimeController.addListener(_changeListener);
    _initialElapsedTimeController = TextEditingController(text: widget.component?.initialElapsedTime.inHours.toString() ?? "0");
    _initialElapsedTimeController.addListener(_changeListener);

    if (widget.mode != ComponentPageMode.add) _expanded = true;

    // Preload the autocomplete index (add mode + flag on) so suggestions are
    // ready by the time the user types, without blocking page load.
    if (widget.mode == ComponentPageMode.add && appSettings.enableComponentPresets) {
      unawaited(_loadPresetIndex());
    }
  }

  Future<void> _loadPresetIndex() async {
    if (_presetIndex != null || _presetIndexLoading) return;
    _presetIndexLoading = true;
    try {
      final variants = await context.read<ComponentPresetRepository>().all();
      if (!mounted) return;
      setState(() => _presetIndex = variants);
    } catch (_) {
      // Autocomplete is an optional convenience; ignore load failures.
    } finally {
      _presetIndexLoading = false;
    }
  }

  void _changeListener() {
    final hasChanges = _nameController.text.trim() != (widget.component?.name ?? '') || 
        _notesController.text.trim() != (widget.component?.notes ?? '') ||
        _componentType != _initialComponentType ||
        !listEquals(_installations, _initialInstallations) ||
        !listEquals(_adjustments, _initialAdjustments);

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
    _nameFocusNode.dispose();
    _notesController.removeListener(_changeListener);
    _notesController.dispose();

    _initialDistanceController.removeListener(_changeListener);
    _initialDistanceController.dispose();
    _initialElevationGainController.removeListener(_changeListener);
    _initialElevationGainController.dispose();
    _initialMovingTimeController.removeListener(_changeListener);
    _initialMovingTimeController.dispose();
    _initialElapsedTimeController.removeListener(_changeListener);
    _initialElapsedTimeController.dispose();
    super.dispose();
  }

  Future<void> _addAdjustment<T extends Adjustment>({VoidCallback? onChanged}) async {
    final adjustment = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => switch(T) {
        const (BooleanAdjustment)       => BooleanAdjustmentPage.add(),
        const (CategoricalAdjustment)   => CategoricalAdjustmentPage.add(),
        const (StepAdjustment)          => StepAdjustmentPage.add(),
        const (NumericalAdjustment)     => NumericalAdjustmentPage.add(),
        const (TextAdjustment)          => TextAdjustmentPage.add(),
        const (DurationAdjustment)      => DurationAdjustmentPage.add(),
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
        final BooleanAdjustment a     => BooleanAdjustmentPage.template(adjustment: a),
        final CategoricalAdjustment a => CategoricalAdjustmentPage.template(adjustment: a),
        final StepAdjustment a        => StepAdjustmentPage.template(adjustment: a),
        final SagAdjustment a         => SagAdjustmentPage.template(adjustment: a, componentType: _componentType),
        final NumericalAdjustment a   => NumericalAdjustmentPage.template(adjustment: a),
        final TextAdjustment a        => TextAdjustmentPage.template(adjustment: a),
        final DurationAdjustment a    => DurationAdjustmentPage.template(adjustment: a),
      }),
    );
    if (newAdjustment == null) return;
    setState(() => _adjustments.add(newAdjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> _editAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment) {
        final BooleanAdjustment a     => BooleanAdjustmentPage.edit(adjustment: a),
        final CategoricalAdjustment a => CategoricalAdjustmentPage.edit(adjustment: a),
        final StepAdjustment a        => StepAdjustmentPage.edit(adjustment: a),
        final SagAdjustment a         => SagAdjustmentPage.edit(adjustment: a, componentType: _componentType),
        final NumericalAdjustment a   => NumericalAdjustmentPage.edit(adjustment: a, componentType: _componentType, enableSagConversion: true),
        final TextAdjustment a        => TextAdjustmentPage.edit(adjustment: a),
        final DurationAdjustment a    => DurationAdjustmentPage.edit(adjustment: a),
      }),
    );
    if (result == null) return;
    final Adjustment editedAdjustment;
    if (result is EditResult<Adjustment>) {
      editedAdjustment = result.value;
      for (final conversion in result.conversions) {
        _stageConversion(conversion);
      }
    } else {
      editedAdjustment = result as Adjustment;
    }
    setState(() {
      final index = _adjustments.indexOf(adjustment);
      if (index != -1) {
        _adjustments[index] = editedAdjustment;
      }
    });
    _changeListener();
    onChanged?.call();
  }

  void _stageConversion(ValueUnitConversion conversion) {
    final existing = _pendingConversions[conversion.adjustmentId];
    final composed = existing == null ? conversion : existing.composeWith(conversion);
    if (composed.isNoOp) {
      _pendingConversions.remove(conversion.adjustmentId);
    } else {
      _pendingConversions[conversion.adjustmentId] = composed;
    }
  }

  Future<void> _duplicateAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    final newAdjustment = await Navigator.push<Adjustment>(
      context,
      MaterialPageRoute(builder: (context) => switch (adjustment.deepCopy()) {
        final BooleanAdjustment a     => BooleanAdjustmentPage.duplicate(adjustment: a),
        final CategoricalAdjustment a => CategoricalAdjustmentPage.duplicate(adjustment: a),
        final StepAdjustment a        => StepAdjustmentPage.duplicate(adjustment: a),
        final SagAdjustment a         => SagAdjustmentPage.duplicate(adjustment: a, componentType: _componentType),
        final NumericalAdjustment a   => NumericalAdjustmentPage.duplicate(adjustment: a),
        final TextAdjustment a        => TextAdjustmentPage.duplicate(adjustment: a),
        final DurationAdjustment a    => DurationAdjustmentPage.duplicate(adjustment: a),
      }),
    );
    if (newAdjustment == null) return;
    setState(() => _adjustments.add(newAdjustment));
    _changeListener();
    onChanged?.call();
  }

  Future<void> removeAdjustment(Adjustment adjustment, {VoidCallback? onChanged}) async {
    setState(() => _adjustments.remove(adjustment));
    _pendingConversions.remove(adjustment.id);
    _changeListener();
    onChanged?.call();
  }

  Future<void> _openPresetPicker() async {
    final type = _componentType;
    if (type == null) return;
    final result = await showComponentPresetPicker(context: context, componentType: type);
    if (result == null || !mounted) return;
    await _applyPreset(buildApplication(result.variant, result.damper));
  }

  Future<void> _applyPreset(PresetApplication app) async {
    final untouched = _adjustments.isEmpty ||
        (_lastPresetAdjustments != null && listEquals(_adjustments, _lastPresetAdjustments));

    var append = false;
    if (!untouched) {
      final choice = await showApplyPresetAdjustmentsDialog(
        context,
        existingCount: _adjustments.length,
      );
      if (choice == null || choice == PresetAdjustmentChoice.cancel) return;
      append = choice == PresetAdjustmentChoice.keepBoth;
    }

    if (!mounted) return;
    setState(() {
      _nameController.text = app.name;
      _notesController.text = app.notes;
      _componentType ??= app.componentType;
      if (append) {
        _adjustments = [..._adjustments, ...app.adjustments];
        // The list no longer matches a single preset → next re-pick will prompt.
        _lastPresetAdjustments = null;
      } else {
        _adjustments = List.from(app.adjustments);
        _lastPresetAdjustments = List.from(app.adjustments);
      }
      if (app.notes.isNotEmpty) _expanded = true;
    });
    _adjustmentsFieldNotify?.call();
    _changeListener();
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }
    
    final appSettings = context.read<AppSettings>();
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final initialDistanceInput = double.parse(_initialDistanceController.text.trim());
    final initialElevationGainInput = double.parse(_initialElevationGainController.text.trim());
    final double initialDistance = AppSettings.convertDistanceToMeters(initialDistanceInput, appSettings.distanceUnit) ?? 0.0;
    final double initialElevationGain = ContextPosition.convertAltitudeToMeters(initialElevationGainInput, appSettings.altitudeUnit) ?? 0.0;
    final initialElapsedTime = int.parse(_initialElapsedTimeController.text.trim());
    final initialMovingTime = int.parse(_initialMovingTimeController.text.trim());
    _formHasChanges = false;

    final component = Component(
      id: widget.mode == ComponentPageMode.edit ? widget.component?.id : null,
      name: name,
      componentType: _componentType!,
      installations: _installations,
      notes: notes.isEmpty ? null : notes,
      adjustments: _adjustments,
      initialDistance: initialDistance,
      initialElevationGain: initialElevationGain,
      initialElapsedTime: Duration(hours: initialElapsedTime),
      initialMovingTime: Duration(hours: initialMovingTime),
      orderIndex: widget.component?.orderIndex ?? 0,
    );
    Navigator.pop(
      context,
      widget.mode == ComponentPageMode.edit
          ? EditResult<Component>(component, conversions: _pendingConversions.values.toList())
          : component,
    );
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_formHasChanges) return;
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  void _onReorderAdjustments(int oldIndex, int newIndex, {VoidCallback? onChanged}) {
    setState(() {
      final adjustment = _adjustments.removeAt(oldIndex);
      _adjustments.insert(newIndex, adjustment);
    });
    _changeListener();
    onChanged?.call();
  }

  Widget _nameField({required bool presetsEnabled}) {
    if (!presetsEnabled) {
      return _nameTextField(presetsEnabled: false);
    }
    return RawAutocomplete<PresetSuggestion>(
      textEditingController: _nameController,
      focusNode: _nameFocusNode,
      optionsBuilder: (TextEditingValue value) {
        final index = _presetIndex;
        if (index == null) return const Iterable<PresetSuggestion>.empty();
        return suggestPresets(index, value.text);
      },
      displayStringForOption: (suggestion) => suggestion.displayName,
      onSelected: (suggestion) {
        _nameFocusNode.unfocus();
        unawaited(_applyPreset(buildApplication(suggestion.variant, suggestion.damper)));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          _nameTextField(presetsEnabled: true, onFieldSubmitted: onFieldSubmitted),
      optionsViewBuilder: (context, onSelected, options) =>
          _suggestionsOverlay(onSelected, options.toList()),
    );
  }

  Widget _nameTextField({required bool presetsEnabled, VoidCallback? onFieldSubmitted}) {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) => setState(() {}), // see filled/fillColor
      onFieldSubmitted: (_) => onFieldSubmitted?.call(),
      decoration: InputDecoration(
        labelText: 'Component Name',
        border: const OutlineInputBorder(),
        hintText: 'Enter component name',
        helperText: presetsEnabled && _nameController.text.trim().isEmpty
            ? "Tip: type a product name — e.g. 'Fox 38'"
            : null,
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == ComponentPageMode.edit && _nameController.text.trim() != widget.component?.name,
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return 'Name is required';
        return null;
      },
    );
  }

  Widget _suggestionsOverlay(
    AutocompleteOnSelected<PresetSuggestion> onSelected,
    List<PresetSuggestion> options,
  ) {
    // Anchor the overlay to the field's left edge and match its width (the
    // field spans the page's 16px horizontal padding).
    final width = MediaQuery.of(context).size.width - 32;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final suggestion = options[i];
                final subtitle = presetSuggestionSubtitle(suggestion);
                final yearRange = suggestion.variant.yearRange;
                return ListTile(
                  dense: true,
                  title: Text(suggestion.displayName),
                  subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: yearRange == null || yearRange.isEmpty ? null : _PresetYearBadge(yearRange),
                  onTap: () => onSelected(suggestion),
                );
              },
            ),
          ),
        ),
      ),
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
        border: const OutlineInputBorder(),
        hintText: "Choose a type for this component",
        helperText: existingComponentsCount > 0
            ? Intl.plural(
                existingComponentsCount,
                one: "WARNING: There is one ${_componentType?.label}-Component already installed on this bike.",
                other: "WARNING: There are $existingComponentsCount ${_componentType?.label}-Components already installed on this bike.",
              )
            : null,
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
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
      onChanged: (value) => setState(() {}), // see filled/fillColor
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Enter brand, model, serial number, costs, ...',
        border: const OutlineInputBorder(),
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == ComponentPageMode.edit && _notesController.text.trim() != (widget.component?.notes ?? ""),
      ),
    );
  }

  Widget _initialStatsFields() {
    final appSettings = context.watch<AppSettings>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                controller: _initialDistanceController,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) => setState(() {}), // see filled/fillColor
                decoration: InputDecoration(
                  labelText: 'Initial Distance (optional)',
                  hintText: 'Enter Initial Distance',
                  border: const OutlineInputBorder(),
                  visualDensity: VisualDensity.compact,
                  suffixText: appSettings.distanceUnit,
                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                  filled: widget.mode == ComponentPageMode.edit && double.tryParse(_initialDistanceController.text.trim()) != AppSettings.convertDistanceFromMeters(widget.component!.initialDistance, appSettings.distanceUnit),
                ),
                validator: (String? newValue) {
                  if (newValue == null || newValue.isEmpty || double.tryParse(newValue) == null) {
                    return "Please enter a valid value";
                  }
                  return null;
                },
              ),
            ),
            Expanded(
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                controller: _initialElevationGainController,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) => setState(() {}), // see filled/fillColor
                decoration: InputDecoration(
                  labelText: 'Initial Elevation Gain (optional)',
                  hintText: 'Enter Initial Elevation Gain',
                  border: const OutlineInputBorder(),
                  visualDensity: VisualDensity.compact,
                  suffixText: appSettings.altitudeUnit,
                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                  filled: widget.mode == ComponentPageMode.edit && double.tryParse(_initialElevationGainController.text.trim()) != AppSettings.convertElevationFromMeters(widget.component!.initialElevationGain, appSettings.altitudeUnit),
                ),
                validator: (String? newValue) {
                  if (newValue == null || newValue.isEmpty || double.tryParse(newValue) == null) {
                    return "Please enter a valid value";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*$')),],
                controller: _initialMovingTimeController,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) => setState(() {}), // see filled/fillColor
                decoration: InputDecoration(
                  labelText: 'Initial Moving Time (optional)',
                  hintText: 'Enter Initial Moving Time',
                  border: const OutlineInputBorder(),
                  visualDensity: VisualDensity.compact,
                  suffixText: "h",
                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                  filled: widget.mode == ComponentPageMode.edit && int.tryParse(_initialMovingTimeController.text.trim()) != widget.component?.initialMovingTime.inHours,
                ),
                validator: (String? newValue) {
                  if (newValue == null || newValue.isEmpty || int.tryParse(newValue) == null) {
                    return "Please enter a valid value";
                  }
                  return null;
                },
              )
            ),
            Expanded(
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*$')),],
                controller: _initialElapsedTimeController,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) => setState(() {}), // see filled/fillColor
                decoration: InputDecoration(
                  labelText: 'Initial Elapsed Time (optional)',
                  hintText: 'Enter Initial Elapsed Time',
                  border: const OutlineInputBorder(),
                  visualDensity: VisualDensity.compact,
                  suffixText: "h",
                  fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                  filled: widget.mode == ComponentPageMode.edit && int.tryParse(_initialElapsedTimeController.text.trim()) != widget.component?.initialElapsedTime.inHours,
                ),
                validator: (String? newValue) {
                  if (newValue == null || newValue.isEmpty || int.tryParse(newValue) == null) {
                    return "Please enter a valid value";
                  }
                  return null;
                },
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _bikesDropdownField({required Map<String, Bike> bikes}) {
    final lastInstallation = _installations.lastOrNull;
    return DropdownButtonFormField<Installation?>(
      initialValue: lastInstallation,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Bike',
        border: const OutlineInputBorder(),
        hintText: "Choose a bike for this component",
        helperText: lastInstallation?.parentType == InstallationParentType.none ? "WARNING: Select Bike to install Component." : null,
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: widget.mode == ComponentPageMode.edit && lastInstallation != _initialInstallations.lastOrNull,
      ),
      validator: (Installation? newInstallation) {
        if (newInstallation is BikeInstallation && !bikes.containsKey(newInstallation.bikeId)) {
          return "Please select valid bike";
        }
        return null;
      },
      items: [
        ...bikes.values.map((b) {
          final matchingInstallation = lastInstallation is BikeInstallation && lastInstallation.bikeId == b.id
              ? lastInstallation
              : BikeInstallation(
                  bikeId: b.id,
                  dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                  dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
                );
          return DropdownMenuItem<Installation?>(
            value: matchingInstallation,
            child: Row(
              spacing: 8,
              children: [
                const Icon(Bike.iconData),
                Expanded(child: Text(b.name, overflow: TextOverflow.ellipsis))
              ],
            ),
          );
        }),
        DropdownMenuItem<Installation?>(
          value: lastInstallation is Uninstallation ? lastInstallation : Uninstallation(
            dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
          ),
          child: const Row(
            spacing: 8,
            children: [
              Icon(Icons.shelves),
              Expanded(child: Text("NOT INSTALLED", overflow: TextOverflow.ellipsis))
            ],
          ),
        ),
        if (widget.mode != ComponentPageMode.add)
          DropdownMenuItem<Installation?>(
            value: lastInstallation is Archival ? lastInstallation : Archival(
              dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0, isUtc: false),
            ),
            child: const Row(
              spacing: 8,
              children: [
                Icon(Icons.inventory_2_outlined),
                Expanded(child: Text("ARCHIVED", overflow: TextOverflow.ellipsis))
              ],
            ),
          ),
        if (lastInstallation is BikeInstallation && !bikes.containsKey(lastInstallation.bikeId))
          DropdownMenuItem<Installation?>(
            value: lastInstallation,
            child: Row(
              spacing: 8,
              children: [
                Icon(Bike.iconData, color: Theme.of(context).colorScheme.error),
                Expanded(
                  child: Text(
                    "BIKE NOT FOUND",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              ],
            ),
          ),
      ],
      onChanged: (Installation? newInstallation) {
        if (newInstallation == null) return;
        setState(() => _installations = [newInstallation.copyWith()]);
        _changeListener();
      },
    );
  }

  bool get _isComplexInstallation => _installations.length > 1 || 
      (_installations.isNotEmpty && _installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final bikes = appRepository.bikes;
    final currentBike = _installations.lastOrNull?.parent;  // _installations are sorted in init() 
    final existingComponentsCount = appRepository.components.values.where((c) => c.bike == currentBike && c.componentType == _componentType && widget.component?.id != c.id).length;

    return PopScope( 
      canPop: !_formHasChanges,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: switch (widget.mode) {
            ComponentPageMode.add || ComponentPageMode.duplicate || ComponentPageMode.replace => const Text('Add Component'),
            ComponentPageMode.edit => const Text('Edit Component'),
          },
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _saveComponent),
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
                        _componentTypeField(existingComponentsCount: existingComponentsCount),
                        if (appSettings.enableComponentPresets &&
                            widget.mode == ComponentPageMode.add &&
                            (_componentType == ComponentType.fork || _componentType == ComponentType.shock)) ...[
                          const SizedBox(height: 12),
                          PresetCatalogCard(
                            componentType: _componentType!,
                            onTap: _openPresetPicker,
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                        _nameField(
                          presetsEnabled: appSettings.enableComponentPresets &&
                              widget.mode == ComponentPageMode.add,
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
                              if (appSettings.enableStrava && subscriptionService.hasStravaEntitlement) ...[
                                const SizedBox(height: 24),
                                _initialStatsFields(),
                              ]
                            ],
                          ),
                        ),
                        if (!appSettings.enableInstallationTimeline && !_isComplexInstallation) ...[
                          const SizedBox(height: 12),
                          _bikesDropdownField(bikes: bikes),
                        ],
                      ],
                    ),
                  ),
                  if (appSettings.enableInstallationTimeline || _isComplexInstallation) ...[
                    // const Divider(height: 1),
                    SetInstallationTimeline(
                      initialInstallations: _installations,
                      originalInstallations: widget.mode == ComponentPageMode.edit ? widget.component?.installations : null,
                      onChanged: (newInstallations) {
                        setState(() => _installations = List.from(newInstallations));
                        _changeListener();
                      },
                    ),
                  ],
                  // const Divider(height: 1),
                  const SectionTitle(title: "Adjustments", infoText: "Adjustments are physical parameters on this component that can be tuned—such as dial positions, switch settings, or pressure ranges. Step 1: Define what adjustment parameters exist for this component and set their limits here. Step 2: After you save this component, create a Setup to save actual adjustment values for your bike."),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FormField<List<Adjustment>>(
                      initialValue: _adjustments,
                      builder: (FormFieldState<List<Adjustment>> field) {
                        void notify() => field.didChange(List.from(_adjustments));
                        _adjustmentsFieldNotify = notify;

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
                                    onReorderAdjustments: (int oldIndex, int newIndex) => _onReorderAdjustments(oldIndex, newIndex, onChanged: notify),
                                  )
                                : EmptyStatePlaceholder2(
                                    title: "No adjustments yet",
                                    errorTitle: field.errorText,
                                    subtitle: "Tap 'Add Adjustment' to define settings for this component",
                                    errorSubtitle: "Tap here to add the first adjustment",
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

/// Small year-range chip for autocomplete suggestion rows (mirrors the picker's
/// year badge).
class _PresetYearBadge extends StatelessWidget {
  final String text;

  const _PresetYearBadge(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
