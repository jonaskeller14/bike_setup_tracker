import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/component_preset.dart';
import '../../models/component/installation.dart';
import '../../models/component_stats.dart';
import '../../repositories/app_repository.dart';
import '../../repositories/component_preset_repository.dart';
import '../../services/subscription_service.dart';
import '../../theme.dart';
import '../../utils/component_preset_application.dart';
import '../../utils/component_preset_search.dart';
import '../../utils/installation_timeline_validation.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/dialogs/apply_preset_adjustments.dart';
import '../../widgets/dialogs/discard_changes.dart';
import '../../widgets/empty_state_placeholder2.dart';
import '../../widgets/lists/adjustment_edit_list.dart';
import '../../widgets/preset_catalog_card.dart';
import '../../widgets/set_installation_timeline.dart';
import '../../widgets/sheets/component_add_adjustment.dart';
import '../../widgets/sheets/component_preset_picker.dart';
import '../../widgets/sheets/component_type_picker.dart';
import '../../widgets/sheets/set_initial_stats.dart';
import '../../widgets/text/section_title.dart';
import '../adjustment/boolean_adjustment_page.dart';
import '../adjustment/categorical_adjustment_page.dart';
import '../adjustment/duration_adjustment_page.dart';
import '../adjustment/numerical_adjustment_page.dart';
import '../adjustment/sag_adjustment_page.dart';
import '../adjustment/step_adjustment_page.dart';
import '../adjustment/text_adjustment_page.dart';

enum ComponentPageMode {
  add,
  edit,
  duplicate,
  replace,
}

class ComponentPage extends StatefulWidget {
  final Component? component;
  final ComponentPageMode mode;
  final List<Installation>? initialInstallations;
  final DateTime? replacementDate;
  final Installation? replacedInstallation;

  const ComponentPage._({super.key, this.component, required this.mode, this.initialInstallations, this.replacementDate, this.replacedInstallation});

  factory ComponentPage.add({Key? key, List<Installation>? initialInstallations}) =>
    ComponentPage._(key: key, mode: ComponentPageMode.add, initialInstallations: initialInstallations);

  factory ComponentPage.edit({Key? key, required Component component}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.edit);

  factory ComponentPage.duplicate({Key? key, required Component component}) => 
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.duplicate);
  
  factory ComponentPage.replace({Key? key, required Component component, required DateTime replacementDate, required Installation replacedInstallation}) =>
    ComponentPage._(key: key, component: component, mode: ComponentPageMode.replace, replacementDate: replacementDate, replacedInstallation: replacedInstallation);

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
  late List<Adjustment> _adjustments;
  late List<Adjustment> _initialAdjustments;
  final Map<String, ValueUnitConversion> _pendingConversions = {};
  late List<Installation> _installations;
  late ComponentType? _componentType;
  late ComponentType? _initialComponentType;
  late List<Installation> _initialInstallations;
  late ComponentStats _initialStats;
  bool _expanded = false;
  String? _presetKey;
  String? _presetDamperKey;
  ComponentPresetVariant? _presetVariant;
  Set<String> _presetAdjustmentIds = {};
  String? _appendedPresetNotes;

  List<Adjustment>? _lastPresetAdjustments;
  VoidCallback? _adjustmentsFieldNotify;
  VoidCallback? _componentTypeFieldNotify;

  /// Cross-type catalog index for the name-field autocomplete (C2), loaded once
  /// and cached
  List<ComponentPresetVariant>? _presetIndex;
  bool _presetIndexLoading = false;
  String? _typedName;

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
    final initialParentId = widget.component != null 
        ? widget.component!.parentId 
        : appRepository.filteredBikes.keys.firstOrNull;

    if (widget.mode == ComponentPageMode.replace) {
      final replacedInstallation = widget.replacedInstallation!;
      // Keeps the parent type, so a component on a component is replaced on that component.
      _installations = [
        replacedInstallation.samePlacementAt(
          dateTimeUTC: widget.replacementDate!.toUtc(),
          dateTimeLocal: widget.replacementDate!.toLocal(),
        ),
      ];
    } else {
      _installations = widget.component?.installations ??
          (widget.initialInstallations != null ? List.of(widget.initialInstallations!) : null) ??
          [Installation.sinceBeginning(parent: initialParentId)];
    }
    _installations.sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    _initialInstallations = List.from(_installations);

    _componentType = widget.component?.componentType;
    _initialComponentType = _componentType;

    _presetKey = widget.component?.presetKey;
    _presetDamperKey = widget.component?.presetDamperKey;

    _notesController = TextEditingController(text: widget.component?.notes);
    _notesController.addListener(_changeListener);

    final appSettings = context.read<AppSettings>();
    _initialStats = widget.component?.initialStats ?? ComponentStats.zero;

    if (widget.mode != ComponentPageMode.add) _expanded = true;

    // Preload the autocomplete index (not in edit mode + flag on) so suggestions are
    // ready by the time the user types, without blocking page load.
    if (widget.mode != ComponentPageMode.edit && appSettings.enableComponentPresets) {
      unawaited(_loadPresetIndex());
    }
    final presetKey = _presetKey;
    if (presetKey != null && appSettings.enableComponentPresets) {
      unawaited(_loadAppliedPreset(presetKey));
    }
  }

  Future<void> _loadAppliedPreset(String key) async {
    try {
      final variant = await context.read<ComponentPresetRepository>().byKey(key);
      if (!mounted || variant == null || _presetKey != key) return;
      setState(() => _presetVariant = variant);
    } catch (_) {
      // Provenance display is optional; an unresolvable key just shows nothing.
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
        !listEquals(_adjustments, _initialAdjustments) ||
        _initialStats != (widget.component?.initialStats ?? ComponentStats.zero) ||
        _presetKey != widget.component?.presetKey ||
        _presetDamperKey != widget.component?.presetDamperKey;

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

  Future<void> _setComponentType(ComponentType componentType) async {
    setState(() => _componentType = componentType);
    _componentTypeFieldNotify?.call();
    _changeListener();
  }

  Future<void> _openPresetPicker() async {
    final type = _componentType;
    if (type == null) return;
    final result = await showComponentPresetPicker(context: context, componentType: type);
    if (result == null || !mounted) return;
    await _applyPreset(result.variant, result.damper);
  }

  /// [typedName] overrides the name UNDO restores: the autocomplete has already
  /// replaced the typed query with the suggestion by the time it calls back.
  Future<void> _applyPreset(ComponentPresetVariant variant, DamperSpec? damper, {String? typedName}) async {
    final app = buildApplication(variant, damper);
    if (widget.mode == ComponentPageMode.edit) return _extendFromPreset(variant, app);
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
    final snapshot = _snapshot(name: typedName);
    setState(() {
      _nameController.text = app.name;
      _notesController.text = app.notes;
      _componentType ??= app.componentType;
      _presetKey = app.presetKey;
      _presetDamperKey = app.presetDamperKey;
      _presetVariant = variant;
      _presetAdjustmentIds = {for (final a in app.adjustments) a.id};
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
    _componentTypeFieldNotify?.call();
    _changeListener();
    _showPresetUndoSnackBar('Filled from ${app.name}', snapshot);
  }

  /// Edit mode only extends: setups store values by adjustment id, so saved
  /// adjustments are never replaced; the name stays the user's and the preset
  /// notes are appended (a re-pick swaps the block the previous pick appended).
  void _extendFromPreset(ComponentPresetVariant variant, PresetApplication app) {
    final snapshot = _snapshot();
    // Only what an earlier pick in this session added is dropped — it was never saved.
    final kept = _adjustments.where((a) => !_presetAdjustmentIds.contains(a.id)).toList();
    final keptNames = {for (final a in kept) a.name.trim().toLowerCase()};
    final added = app.adjustments.where((a) => !keptNames.contains(a.name.trim().toLowerCase())).toList();
    final previousBlock = _appendedPresetNotes;
    final keptNotes = (previousBlock == null ? _notesController.text : _notesController.text.replaceFirst(previousBlock, '')).trimRight();
    final appendNotes = app.notes.isNotEmpty && !keptNotes.contains(app.notes);
    setState(() {
      if (appendNotes) {
        _appendedPresetNotes = keptNotes.isEmpty ? app.notes : '\n\n${app.notes}';
        _notesController.text = keptNotes + _appendedPresetNotes!;
      } else {
        _appendedPresetNotes = null;
        _notesController.text = keptNotes;
      }
      _presetKey = app.presetKey;
      _presetDamperKey = app.presetDamperKey;
      _presetVariant = variant;
      _presetAdjustmentIds = {for (final a in added) a.id};
      _adjustments = [...kept, ...added];
    });
    _adjustmentsFieldNotify?.call();
    _changeListener();
    _showPresetUndoSnackBar(
      Intl.plural(
        added.length,
        zero: 'Linked to ${app.name} · all adjustments already exist',
        one: 'Linked to ${app.name} · 1 adjustment added',
        other: 'Linked to ${app.name} · ${added.length} adjustments added',
      ),
      snapshot,
    );
  }

  void _unlinkPreset() {
    final variant = _presetVariant;
    if (variant == null) return;
    final snapshot = _snapshot();
    setState(_clearPresetLink);
    _changeListener();
    _showPresetUndoSnackBar(
      'Unlinked from ${presetVariantDisplayName(variant, variant.damperByKey(snapshot.presetDamperKey))} — values kept',
      snapshot,
    );
  }

  void _clearPresetLink() {
    _presetKey = null;
    _presetDamperKey = null;
    _presetVariant = null;
    _presetAdjustmentIds = {};
    _appendedPresetNotes = null;
    // The list no longer matches a linked preset → next pick will prompt.
    _lastPresetAdjustments = null;
  }

  _PresetSnapshot _snapshot({String? name}) => _PresetSnapshot(
        name: name ?? _nameController.text,
        notes: _notesController.text,
        componentType: _componentType,
        adjustments: List.of(_adjustments),
        lastPresetAdjustments: _lastPresetAdjustments,
        presetAdjustmentIds: _presetAdjustmentIds,
        appendedPresetNotes: _appendedPresetNotes,
        presetKey: _presetKey,
        presetDamperKey: _presetDamperKey,
        presetVariant: _presetVariant,
        expanded: _expanded,
      );

  void _restoreSnapshot(_PresetSnapshot snapshot) {
    setState(() {
      _nameController.text = snapshot.name;
      _notesController.text = snapshot.notes;
      _componentType = snapshot.componentType;
      _adjustments = List.of(snapshot.adjustments);
      _lastPresetAdjustments = snapshot.lastPresetAdjustments;
      _presetAdjustmentIds = snapshot.presetAdjustmentIds;
      _appendedPresetNotes = snapshot.appendedPresetNotes;
      _presetKey = snapshot.presetKey;
      _presetDamperKey = snapshot.presetDamperKey;
      _presetVariant = snapshot.presetVariant;
      _expanded = snapshot.expanded;
    });
    _adjustmentsFieldNotify?.call();
    _componentTypeFieldNotify?.call();
    _changeListener();
  }

  void _showPresetUndoSnackBar(String message, _PresetSnapshot snapshot) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.success(
        context,
        message,
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (mounted) _restoreSnapshot(snapshot);
          },
        ),
      ));
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _expanded = true);
      return;
    }
    
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    _formHasChanges = false;

    final component = Component(
      id: widget.mode == ComponentPageMode.edit ? widget.component?.id : null,
      name: name,
      componentType: _componentType!,
      installations: _installations,
      notes: notes.isEmpty ? null : notes,
      adjustments: _adjustments,
      initialStats: _initialStats,
      orderIndex: widget.component?.orderIndex ?? 0,
      presetKey: _presetKey,
      presetDamperKey: _presetDamperKey,
    );
    // A preset UNDO would be a dead button on the previous screen.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        unawaited(_applyPreset(suggestion.variant, suggestion.damper, typedName: _typedName));
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
      onChanged: (value) => setState(() => _typedName = value), // see filled/fillColor
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
    final type = _componentType;
    final highlightBaseline = widget.mode == ComponentPageMode.edit ? widget.component?.componentType : null;
    final isChanged = highlightBaseline != null && type != highlightBaseline;
    final isOverLimit = type != null && existingComponentsCount >= type.maxCount;
    // DropdownButton's own default (see DropdownButton._textStyle).
    final dropdownTextStyle = Theme.of(context).textTheme.titleMedium!;
    return FormField<ComponentType?>(
      initialValue: _componentType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (ComponentType? value) {
        if (value == null) {
          return 'Component type cannot be empty. You can edit it later.';
        }
        return null;
      },
      builder: (FormFieldState<ComponentType?> field) {
        _componentTypeFieldNotify = () => field.didChange(_componentType);
        return InkWell(
          onTap: () => _pickComponentType(field),
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            // Never "empty": the placeholder below stands in for a value, so the
            // label keeps floating (as the dropdown's `hint` used to make it).
            isEmpty: false,
            decoration: InputDecoration(
              labelText: 'Type',
              border: const OutlineInputBorder(),
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              helperText: isOverLimit
                  ? Intl.plural(
                      type.maxCount,
                      one: "WARNING: There is already one ${type.label}-Component installed on this bike.",
                      other: "WARNING: There are already ${type.maxCount} ${type.label}-Components installed on this bike.",
                    )
                  : null,
              helperMaxLines: 2,
              fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
              filled: isChanged,
            ),
            // Same text style DropdownButton applies to its value/hint, so this
            // field reads identically to the Bike dropdown below.
            child: DefaultTextStyle(
              style: type == null
                  ? dropdownTextStyle.copyWith(
                      color: field.hasError ? Theme.of(context).colorScheme.error : Theme.of(context).hintColor,
                    )
                  : dropdownTextStyle,
              child: type == null
                  ? const Text("Please select type")
                  : Row(
                      spacing: 8,
                      children: [
                        Icon(type.getIconData()),
                        Expanded(child: Text(type.label, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickComponentType(FormFieldState<ComponentType?> field) async {
    final picked = await showComponentTypePickerSheet(
      context: context,
      selectedComponentType: _componentType,
      initialComponentType: widget.mode == ComponentPageMode.edit ? widget.component?.componentType : null,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _componentType = picked;
      // A fork preset link is meaningless on a shock; the prefilled values stay.
      if (_presetVariant != null && _presetVariant!.componentType != picked) _clearPresetLink();
    });
    field.didChange(picked);
    _changeListener();
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

  Future<void> _editInitialStats() async {
    final newStats = await showSetInitialStatsSheet(
      context: context,
      initialStats: _initialStats,
      originalStats: widget.mode == ComponentPageMode.edit ? widget.component?.initialStats : null,
    );
    if (newStats == null || !mounted) return;
    setState(() => _initialStats = newStats);
    _changeListener();
  }

  Widget _initialStatsChip() {
    final appSettings = context.watch<AppSettings>();
    final summary = initialStatsSummary(_initialStats, appSettings);
    return FilterChip(
      avatar: const Icon(Icons.start),
      showCheckmark: false,
      selected: widget.mode != ComponentPageMode.edit && _initialStats != ComponentStats.zero,
      label: Text(
        summary == null ? "Initial Stats" : "Initial: $summary",
        overflow: TextOverflow.ellipsis,
      ),
      tooltip: "Usage before this component was tracked",
      backgroundColor: widget.mode == ComponentPageMode.edit && _initialStats != widget.component!.initialStats
          ? Theme.of(context).extension<ValueHighlightColors>()!.changedFill
          : null,
      onSelected: (_) => _editInitialStats(),
    );
  }

  String? _presetAdjustmentsCaption() {
    final variant = _presetVariant;
    if (variant == null) return null;
    final fromPreset = _adjustments.where((a) => _presetAdjustmentIds.contains(a.id)).length;
    if (fromPreset == 0) return null;
    final others = _adjustments.length - fromPreset;
    final name = presetVariantDisplayName(variant, variant.damperByKey(_presetDamperKey));
    final caption = Intl.plural(
      fromPreset,
      one: '1 adjustment prefilled from $name',
      other: '$fromPreset adjustments prefilled from $name',
    );
    if (others == 0) return caption;
    return '$caption · ${Intl.plural(others, one: '1 other', other: '$others others')}';
  }

  Widget _presetCaptionRow(String caption) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        spacing: 6,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: color),
          Expanded(
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
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

  bool get _isComplexInstallation => isComplexInstallationTimeline(_installations);

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final bikes = appRepository.bikes;
    final currentBike = _installations.lastOrNull?.parent;  // _installations are sorted in init() 
    final existingComponentsCount = currentBike == null
        ? 0
        : appRepository.components.values.where((c) =>
            !c.isArchived &&
            appRepository.componentHierarchy.currentBike(c.id) == currentBike &&
            c.componentType == _componentType &&
            widget.component?.id != c.id).length;

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
                            (_componentType == ComponentType.fork || _componentType == ComponentType.shock)) ...[
                          const SizedBox(height: 12),
                          PresetCatalogCard(
                            componentType: _componentType!,
                            onTap: _openPresetPicker,
                            appliedVariant: _presetVariant,
                            appliedDamper: _presetVariant?.damperByKey(_presetDamperKey),
                            onUnlink: _unlinkPreset,
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                        _nameField(
                          // Off in edit mode: renaming shouldn't pop suggestions that overwrite name and notes.
                          presetsEnabled: appSettings.enableComponentPresets &&
                              widget.mode != ComponentPageMode.edit,
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
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _initialStatsChip(),
                                ),
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
                      componentId: widget.mode == ComponentPageMode.edit ? widget.component?.id : null,
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
                          existingAdjustments: _adjustments,
                          enableDurationAdjustment: _enableDurationAdjustment,
                          addAdjustmentFromPreset: (a) => _addAdjustmentFromPreset(a, onChanged: notify),
                          addAdjustment: <T extends Adjustment>() => _addAdjustment<T>(onChanged: notify),
                          onComponentTypeSelected: _componentType == null ? _setComponentType : null,
                        );

                        final presetCaption = _presetAdjustmentsCaption();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (presetCaption != null) _presetCaptionRow(presetCaption),
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

class _PresetSnapshot {
  final String name;
  final String notes;
  final ComponentType? componentType;
  final List<Adjustment> adjustments;
  final List<Adjustment>? lastPresetAdjustments;
  final Set<String> presetAdjustmentIds;
  final String? appendedPresetNotes;
  final String? presetKey;
  final String? presetDamperKey;
  final ComponentPresetVariant? presetVariant;
  final bool expanded;

  const _PresetSnapshot({
    required this.name,
    required this.notes,
    required this.componentType,
    required this.adjustments,
    required this.lastPresetAdjustments,
    required this.presetAdjustmentIds,
    required this.appendedPresetNotes,
    required this.presetKey,
    required this.presetDamperKey,
    required this.presetVariant,
    required this.expanded,
  });
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
