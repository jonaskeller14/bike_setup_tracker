import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/component.dart';
import '../../models/component_preset.dart';
import '../../repositories/component_preset_repository.dart';
import '../../utils/component_preset_search.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// What the picker (C5) returns: the chosen variant and, when the trim ships
/// with more than one damper, the damper the user selected. A single-damper (or
/// damper-less) trim returns [damper] resolved (or `null`) so the caller can
/// hand it straight to `buildApplication`.
class ComponentPresetPickerResult {
  final ComponentPresetVariant variant;
  final DamperSpec? damper;

  const ComponentPresetPickerResult(this.variant, this.damper);
}

/// Hybrid catalog picker (C5): browse brand → model → trim (→ damper), or search
/// across the whole component type from the pinned field. Add-mode only; the
/// caller gates on the feature flag and mode.
Future<ComponentPresetPickerResult?> showComponentPresetPicker({
  required BuildContext context,
  required ComponentType componentType,
}) {
  return showModalBottomSheet<ComponentPresetPickerResult>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _ComponentPresetPickerSheet(componentType: componentType),
  );
}

enum _PickerStage { brands, models, trims, damper }

class _ComponentPresetPickerSheet extends StatefulWidget {
  final ComponentType componentType;

  const _ComponentPresetPickerSheet({required this.componentType});

  @override
  State<_ComponentPresetPickerSheet> createState() => _ComponentPresetPickerSheetState();
}

class _ComponentPresetPickerSheetState extends State<_ComponentPresetPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<ComponentPresetVariant>? _variants;
  Object? _loadError;

  _PickerStage _stage = _PickerStage.brands;
  String? _brand;
  String? _model;
  ComponentPresetVariant? _variant;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repository = context.read<ComponentPresetRepository>();
      final variants = await repository.forType(widget.componentType);
      if (!mounted) return;
      setState(() => _variants = variants);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- navigation -----------------------------------------------------------

  void _goBack() {
    setState(() {
      switch (_stage) {
        case _PickerStage.damper:
          _stage = _PickerStage.trims;
          _variant = null;
        case _PickerStage.trims:
          _stage = _PickerStage.models;
          _model = null;
        case _PickerStage.models:
          _stage = _PickerStage.brands;
          _brand = null;
        case _PickerStage.brands:
          break;
      }
    });
  }

  void _openBrand(String brand) => setState(() {
        _brand = brand;
        _stage = _PickerStage.models;
      });

  void _openModel(String model) => setState(() {
        _model = model;
        _stage = _PickerStage.trims;
      });

  void _selectVariant(ComponentPresetVariant variant) {
    if (variant.dampers.length > 1) {
      setState(() {
        _variant = variant;
        _stage = _PickerStage.damper;
      });
      return;
    }
    final damper = variant.dampers.length == 1 ? variant.dampers.single : null;
    Navigator.pop(context, ComponentPresetPickerResult(variant, damper));
  }

  void _selectDamper(ComponentPresetVariant variant, DamperSpec damper) {
    Navigator.pop(context, ComponentPresetPickerResult(variant, damper));
  }

  // --- build ----------------------------------------------------------------

  bool get _searching => _stage == _PickerStage.brands && _query.length >= 2;

  String get _switchKey => [
        _stage.name,
        _searching ? 'search' : 'browse',
        _brand ?? '',
        _model ?? '',
        _variant?.presetKey ?? '',
        _variants == null ? 'loading' : 'loaded',
        _loadError != null ? 'error' : '',
      ].join('|');

  String get _title {
    switch (_stage) {
      case _PickerStage.brands:
        return 'Choose from catalog';
      case _PickerStage.models:
        return _brand ?? 'Models';
      case _PickerStage.trims:
        return '${_brand ?? ''} ${_model ?? ''}'.trim();
      case _PickerStage.damper:
        return 'Select damper';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: _title,
            onBack: _stage == _PickerStage.brands ? null : _goBack,
          ),
          const SizedBox(height: 12),
          if (_stage == _PickerStage.brands) _searchField(),
          Flexible(
            child: Padding(
              // Keep content scrollable clear of the on-screen keyboard.
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(_switchKey), child: _body()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _query = '';
                  }),
                ),
          hintText: 'Search ${widget.componentType.label.toLowerCase()}s…',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loadError != null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Could not load the catalog.'),
      );
    }
    final variants = _variants;
    if (variants == null) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      );
    }

    if (_searching) return _searchResults(variants);

    switch (_stage) {
      case _PickerStage.brands:
        return _brandList(variants);
      case _PickerStage.models:
        return _modelList(variants);
      case _PickerStage.trims:
        return _trimList(variants);
      case _PickerStage.damper:
        return _damperList();
    }
  }

  // --- stage 1: brands ------------------------------------------------------

  Widget _brandList(List<ComponentPresetVariant> variants) {
    final brands = <String>[];
    final counts = <String, int>{};
    for (final v in variants) {
      if (!counts.containsKey(v.brand)) brands.add(v.brand);
      counts[v.brand] = (counts[v.brand] ?? 0) + 1;
    }
    if (brands.isEmpty) {
      return const _EmptyHint(text: 'No catalog entries available.');
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final brand in brands)
          ListTile(
            title: Text(brand),
            subtitle: Text('${counts[brand]} variants'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openBrand(brand),
          ),
      ],
    );
  }

  // --- stage 2: models (grouped by category) --------------------------------

  Widget _modelList(List<ComponentPresetVariant> variants) {
    final forBrand = variants.where((v) => v.brand == _brand).toList();

    if (forBrand.isEmpty) {
      return const _EmptyHint(text: 'No models available for this brand.');
    }

    // Group models by category (categories and models both in first-seen order)
    // so a category that recurs later in the file stays under one header.
    final categories = <String>[];
    final modelsByCategory = <String, List<String>>{};
    final yearOf = <String, String?>{};
    final trimCount = <String, int>{};
    for (final v in forBrand) {
      final category = v.category ?? 'Other';
      if (!trimCount.containsKey(v.model)) {
        if (!modelsByCategory.containsKey(category)) {
          categories.add(category);
          modelsByCategory[category] = [];
        }
        modelsByCategory[category]!.add(v.model);
        yearOf[v.model] = v.yearRange;
      }
      trimCount[v.model] = (trimCount[v.model] ?? 0) + 1;
    }

    final children = <Widget>[];
    for (final category in categories) {
      children.add(_CategoryHeader(category));
      for (final model in modelsByCategory[category]!) {
        children.add(ListTile(
          title: Text(model),
          subtitle: _subtitleText(_modelSubtitle(yearOf[model], trimCount[model]!)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _openModel(model),
        ));
      }
    }
    return ListView(shrinkWrap: true, children: children);
  }

  String _modelSubtitle(String? yearRange, int trims) {
    final parts = <String>[];
    if (yearRange != null && yearRange.isNotEmpty) parts.add(yearRange);
    parts.add(trims == 1 ? '1 trim' : '$trims trims');
    return parts.join(' · ');
  }

  // --- stage 3: trims -------------------------------------------------------

  Widget _trimList(List<ComponentPresetVariant> variants) {
    final trims = variants.where((v) => v.brand == _brand && v.model == _model).toList();
    return ListView(
      shrinkWrap: true,
      children: [
        for (final v in trims) _variantTile(v, title: v.trim),
      ],
    );
  }

  // --- search results (flat across the type) --------------------------------

  Widget _searchResults(List<ComponentPresetVariant> variants) {
    final results = filterPresetVariants(variants, _query);
    if (results.isEmpty) {
      return _EmptyHint(text: 'No matches for "$_query".');
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final v in results)
          _variantTile(v, title: '${v.brand} ${v.model} ${v.trim}'.trim()),
      ],
    );
  }

  Widget _variantTile(ComponentPresetVariant v, {required String title}) {
    final subtitle = _variantSubtitle(v);
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : _subtitleText(subtitle),
      trailing: _trailingForVariant(v),
      onTap: () => _selectVariant(v),
    );
  }

  Widget _trailingForVariant(ComponentPresetVariant v) {
    const chevron = Icon(Icons.arrow_forward_ios, size: 16);
    if (v.yearRange == null || v.yearRange!.isEmpty) return chevron;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _YearBadge(v.yearRange!),
        const SizedBox(width: 6),
        chevron,
      ],
    );
  }

  String? _variantSubtitle(ComponentPresetVariant v) {
    final parts = <String>[];
    final damperNames = v.dampers.map((d) => d.name).where((n) => n.isNotEmpty).toList();
    if (damperNames.isNotEmpty) parts.add(damperNames.join(' / '));
    final travel = v.travelLabel;
    if (travel != null) parts.add(travel);
    if (v.stanchion != null && v.stanchion!.isNotEmpty) parts.add(v.stanchion!);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  // --- stage 4: damper ------------------------------------------------------

  Widget _damperList() {
    final variant = _variant!;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final damper in variant.dampers)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(damper.name),
              subtitle: _damperSubtitle(damper),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              isThreeLine: damper.description != null && damper.description!.isNotEmpty,
              onTap: () => _selectDamper(variant, damper),
            ),
          ),
      ],
    );
  }

  Widget? _damperSubtitle(DamperSpec damper) {
    final lines = <String>[];
    final description = damper.description;
    if (description != null && description.isNotEmpty) lines.add(description.trim());
    final summary = _damperSummary(damper);
    if (summary.isNotEmpty) lines.add(summary);
    if (lines.isEmpty) return null;
    return Text(lines.join('\n'));
  }

  String _damperSummary(DamperSpec damper) {
    final parts = <String>[];
    for (final spec in damper.adjustmentSpecs) {
      final adjustment = spec.build();
      if (adjustment is StepAdjustment) {
        parts.add('${_abbreviate(adjustment.name)} ${_rangeLabel(adjustment)}');
      }
    }
    return parts.join(' · ');
  }

  String _abbreviate(String name) {
    final words = name.split(RegExp(r'[\s\-]+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 1) return name;
    return words.map((w) => w[0].toUpperCase()).join();
  }

  String _rangeLabel(StepAdjustment step) {
    if (step.max > 0 && step.min == -step.max) return '±${step.max}';
    if (step.min == 0) return '${step.max}';
    return '${step.min}…${step.max}';
  }

  // --- shared bits ----------------------------------------------------------

  Widget _subtitleText(String text) => Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
}

class _CategoryHeader extends StatelessWidget {
  final String label;

  const _CategoryHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _YearBadge extends StatelessWidget {
  final String text;

  const _YearBadge(this.text);

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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SheetFilterEmptyHint(icon: Icons.search_off, title: text),
    );
  }
}
