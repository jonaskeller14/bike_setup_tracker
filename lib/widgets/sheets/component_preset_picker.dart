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

class ComponentPresetPickerResult {
  final ComponentPresetVariant variant;
  final DamperSpec? damper;

  const ComponentPresetPickerResult(this.variant, this.damper);
}

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

const Duration _stageDuration = Duration(milliseconds: 260);
const int _minQueryLength = 2;
const String _uncategorised = 'Other';

const Widget _chevron = Icon(Icons.arrow_forward_ios, size: 16);

// --- where we are ------------------------------------------------------------

sealed class _Stage {
  const _Stage();
}

class _Brands extends _Stage {
  const _Brands();
}

class _Models extends _Stage {
  const _Models(this.brand);

  final String brand;
}

class _Trims extends _Stage {
  const _Trims(this.brand, this.model);

  final String brand;
  final String model;
}

class _Dampers extends _Stage {
  const _Dampers(this.variant);

  final ComponentPresetVariant variant;
}

/// Which way the next stage transition travels.
enum _Direction {
  /// Drilling in — the new stage arrives from the trailing edge.
  forward(1),

  /// Going back — the reverse.
  backward(-1),

  /// No hierarchy change (search toggle, initial load): cross-fade in place.
  none(0);

  const _Direction(this.sign);

  final int sign;
}

// --- sheet -------------------------------------------------------------------

class _ComponentPresetPickerSheet extends StatefulWidget {
  final ComponentType componentType;

  const _ComponentPresetPickerSheet({required this.componentType});

  @override
  State<_ComponentPresetPickerSheet> createState() => _ComponentPresetPickerSheetState();
}

class _ComponentPresetPickerSheetState extends State<_ComponentPresetPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  _Catalog? _catalog;
  Object? _loadError;

  _Stage _stage = const _Brands();
  _Direction _direction = _Direction.none;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = context.read<ComponentPresetRepository>();
    try {
      final variants = await repository.forType(widget.componentType);
      if (!mounted) return;
      setState(() => _catalog = _Catalog.from(variants));
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  // --- navigation -----------------------------------------------------------

  void _goTo(_Stage stage, _Direction direction) {
    setState(() {
      _stage = stage;
      _direction = direction;
    });
  }

  void _goBack() {
    final previous = switch (_stage) {
      _Dampers(:final variant) => _Trims(variant.brand, variant.model),
      _Trims(:final brand) => _Models(brand),
      _Models() => const _Brands(),
      _Brands() => null,
    };
    if (previous != null) _goTo(previous, _Direction.backward);
  }

  void _selectVariant(ComponentPresetVariant variant) {
    // More than one damper means the buyer picked one, so ask rather than guess.
    if (variant.dampers.length > 1) {
      _goTo(_Dampers(variant), _Direction.forward);
      return;
    }
    _finish(variant, variant.dampers.length == 1 ? variant.dampers.single : null);
  }

  void _finish(ComponentPresetVariant variant, DamperSpec? damper) {
    Navigator.pop(context, ComponentPresetPickerResult(variant, damper));
  }

  // --- search ---------------------------------------------------------------

  bool get _isSearching => _stage is _Brands && _query.length >= _minQueryLength;

  /// Search isn't part of the brand → model → trim hierarchy, so crossing the
  /// threshold into (or out of) results cross-fades without sliding.
  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
      _direction = _Direction.none;
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
  }

  // --- build ----------------------------------------------------------------

  String get _title => switch (_stage) {
    _Brands() => 'Choose from catalog',
    _Models(:final brand) => brand,
    _Trims(:final brand, :final model) => '$brand $model',
    _Dampers() => 'Select damper',
  };

  /// Identity of the body on screen; the switcher animates whenever it changes.
  /// [_stage] is replaced only by navigation, so comparing stages by identity is
  /// exactly the "did we move?" test.
  Key get _bodyKey => ValueKey((_stage, _isSearching, _catalog, _loadError));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        // A modal sheet sizes itself to its content but does not animate that
        // size changing, so stages of differing height would snap without this.
        child: AnimatedSize(
          duration: _stageDuration,
          curve: Curves.easeOutCubic,
          // Pin the header while the sheet grows downward, so drilling in
          // reveals content instead of shifting everything vertically.
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: _title,
                onBack: _stage is _Brands ? null : _goBack,
              ),
              const SizedBox(height: 12),
              if (_stage is _Brands) _buildSearchField(),
              Flexible(
                child: _StageSwitcher(
                  direction: _direction,
                  child: KeyedSubtree(key: _bodyKey, child: _buildBody()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) return const _LoadFailure();

    final catalog = _catalog;
    if (catalog == null) return const _LoadingBar();
    if (_isSearching) return _buildSearchResults(catalog);

    return switch (_stage) {
      _Brands() => _BrandList(
        brands: catalog.brands,
        onSelect: (brand) => _goTo(_Models(brand), _Direction.forward),
      ),
      _Models(:final brand) => _ModelList(
        rows: catalog.modelRowsFor(brand),
        onSelect: (model) => _goTo(_Trims(brand, model), _Direction.forward),
      ),
      _Trims(:final brand, :final model) => _VariantList(
        variants: catalog.trimsFor(brand, model),
        titleOf: (variant) => variant.trim,
        onSelect: _selectVariant,
      ),
      _Dampers(:final variant) => _DamperList(
        dampers: variant.dampers,
        onSelect: (damper) => _finish(variant, damper),
      ),
    };
  }

  Widget _buildSearchResults(_Catalog catalog) {
    final results = filterPresetVariants(catalog.variants, _query);
    if (results.isEmpty) return _EmptyHint(text: 'No matches for "$_query".');
    return _VariantList(
      variants: results,
      // A flat result list has no brand/model context around it, so spell the
      // whole name out.
      titleOf: (v) => '${v.brand} ${v.model} ${v.trim}'.trim(),
      onSelect: _selectVariant,
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onQueryChanged,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: _clearQuery),
          hintText: 'Search ${widget.componentType.label.toLowerCase()}s…',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// --- stage transition --------------------------------------------------------

class _StageSwitcher extends StatelessWidget {
  const _StageSwitcher({required this.direction, required this.child});

  final _Direction direction;
  final Widget child;

  /// How far a stage travels, as a fraction of the sheet width. Material motion
  /// keeps this short — a full-width slide feels heavy inside a bottom sheet.
  static const double _travel = 0.10;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _stageDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: _layout,
      // A fresh closure every build, deliberately: AnimatedSwitcher rebuilds the
      // outgoing child's transition only when the builder's identity changes,
      // and that child has to pick up the current [direction] to travel the
      // opposite way.
      transitionBuilder: (stage, animation) => _buildTransition(stage, animation),
      child: child,
    );
  }

  /// Sizes the switcher to the *incoming* stage only. The default layout stacks
  /// both stages unpositioned, so the stack — and with it the sheet — would snap
  /// to whichever is taller for the whole transition, then snap back. Positioned
  /// children don't contribute to a stack's size, so the outgoing stage rides
  /// along at the incoming stage's height and only the height tween is visible.
  static Widget _layout(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        for (final previous in previousChildren) Positioned.fill(child: previous),
        ?currentChild,
      ],
    );
  }

  /// Both stages also cross-fade: they overlap in the stack and list tiles are
  /// transparent, so without it the outgoing list stays legible straight through
  /// the incoming one.
  Widget _buildTransition(Widget stage, Animation<double> animation) {
    final isIncoming = stage.key == child.key;
    final from = (isIncoming ? direction.sign : -direction.sign) * _travel;
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(from, 0),
          end: Offset.zero,
        ).animate(animation),
        child: stage,
      ),
    );
  }
}

// --- catalog -----------------------------------------------------------------

class _Catalog {
  factory _Catalog.from(List<ComponentPresetVariant> variants) {
    final variantsPerBrand = <String, int>{};
    final trimsByModel = <String, List<ComponentPresetVariant>>{};
    // brand → category → models. Every level keeps first-seen order, so a
    // category that recurs later in the catalog file stays under one header.
    final modelsByBrand = <String, Map<String, List<_ModelEntry>>>{};

    for (final variant in variants) {
      variantsPerBrand.update(variant.brand, (count) => count + 1, ifAbsent: () => 1);

      final trims = trimsByModel.putIfAbsent(_modelKey(variant.brand, variant.model), () => []);
      trims.add(variant);

      // First trim of a model earns it a row, which then reads its trim count
      // off the very list we keep appending to below.
      if (trims.length == 1) {
        modelsByBrand
            .putIfAbsent(variant.brand, () => {})
            .putIfAbsent(variant.category ?? _uncategorised, () => [])
            .add(_ModelEntry(
              name: variant.model,
              yearRange: variant.yearRange,
              trims: trims,
            ));
      }
    }

    return _Catalog._(
      variants: variants,
      brands: [
        for (final MapEntry(key: brand, value: count) in variantsPerBrand.entries)
          _BrandEntry(brand: brand, variantCount: count),
      ],
      modelRowsByBrand: {
        for (final MapEntry(key: brand, value: categories) in modelsByBrand.entries)
          brand: [
            for (final MapEntry(key: category, value: models) in categories.entries) ...[
              _CategoryRow(category),
              ...models,
            ],
          ],
      },
      trimsByModel: trimsByModel,
    );
  }

  const _Catalog._({
    required this.variants,
    required this.brands,
    required Map<String, List<_ModelRow>> modelRowsByBrand,
    required Map<String, List<ComponentPresetVariant>> trimsByModel,
  }) : _modelRowsByBrand = modelRowsByBrand,
       _trimsByModel = trimsByModel;

  /// Every variant of the type, in catalog order — the corpus search runs over.
  final List<ComponentPresetVariant> variants;

  /// Stage 1, in first-seen order.
  final List<_BrandEntry> brands;

  /// Stage 2, keyed by brand, with category headers already interleaved.
  final Map<String, List<_ModelRow>> _modelRowsByBrand;

  /// Stage 3, keyed by [_modelKey].
  final Map<String, List<ComponentPresetVariant>> _trimsByModel;

  List<_ModelRow> modelRowsFor(String brand) => _modelRowsByBrand[brand] ?? const [];

  List<ComponentPresetVariant> trimsFor(String brand, String model) =>
      _trimsByModel[_modelKey(brand, model)] ?? const [];
}

String _modelKey(String brand, String model) => '$brand/$model';

class _BrandEntry {
  const _BrandEntry({required this.brand, required this.variantCount});

  final String brand;
  final int variantCount;
}

/// One row of the model list: a category header or a model.
sealed class _ModelRow {
  const _ModelRow();
}

class _CategoryRow extends _ModelRow {
  const _CategoryRow(this.category);

  final String category;
}

class _ModelEntry extends _ModelRow {
  const _ModelEntry({
    required this.name,
    required this.yearRange,
    required this.trims,
  });

  final String name;
  final String? yearRange;

  /// Live reference to the model's list in [_Catalog._trimsByModel]; it is still
  /// being filled when the entry is created.
  final List<ComponentPresetVariant> trims;
}

// --- stage 1: brands ---------------------------------------------------------

class _BrandList extends StatelessWidget {
  const _BrandList({required this.brands, required this.onSelect});

  final List<_BrandEntry> brands;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return const _EmptyHint(text: 'No catalog entries available.');
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final entry = brands[index];
        return ListTile(
          title: Text(entry.brand),
          subtitle: Text('${entry.variantCount} variants'),
          trailing: _chevron,
          onTap: () => onSelect(entry.brand),
        );
      },
    );
  }
}

// --- stage 2: models, grouped by category ------------------------------------

class _ModelList extends StatelessWidget {
  const _ModelList({required this.rows, required this.onSelect});

  final List<_ModelRow> rows;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyHint(text: 'No models available for this brand.');
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _CategoryRow(:final category) => _CategoryHeader(category),
        final _ModelEntry model => ListTile(
          title: Text(model.name),
          subtitle: _SubtitleText(_modelSubtitle(model)),
          trailing: _chevron,
          onTap: () => onSelect(model.name),
        ),
      },
    );
  }
}

String _modelSubtitle(_ModelEntry model) {
  final parts = <String>[];
  final years = model.yearRange;
  if (years != null && years.isNotEmpty) parts.add(years);
  parts.add(model.trims.length == 1 ? '1 trim' : '${model.trims.length} trims');
  return parts.join(' · ');
}

// --- stage 3: trims, and the flat search results -----------------------------

class _VariantList extends StatelessWidget {
  const _VariantList({
    required this.variants,
    required this.titleOf,
    required this.onSelect,
  });

  final List<ComponentPresetVariant> variants;
  final String Function(ComponentPresetVariant) titleOf;
  final ValueChanged<ComponentPresetVariant> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        final subtitle = _variantSubtitle(variant);
        return ListTile(
          title: Text(titleOf(variant)),
          subtitle: subtitle == null ? null : _SubtitleText(subtitle),
          trailing: _VariantTrailing(variant.yearRange),
          onTap: () => onSelect(variant),
        );
      },
    );
  }
}

/// Chevron, preceded by the year badge when the catalog knows the years.
class _VariantTrailing extends StatelessWidget {
  const _VariantTrailing(this.yearRange);

  final String? yearRange;

  @override
  Widget build(BuildContext context) {
    final years = yearRange;
    if (years == null || years.isEmpty) return _chevron;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_YearBadge(years), const SizedBox(width: 6), _chevron],
    );
  }
}

String? _variantSubtitle(ComponentPresetVariant variant) {
  final parts = <String>[];
  final damperNames = variant.dampers.map((d) => d.name).where((name) => name.isNotEmpty);
  if (damperNames.isNotEmpty) parts.add(damperNames.join(' / '));
  final travel = variant.travelLabel;
  if (travel != null) parts.add(travel);
  final stanchion = variant.stanchion;
  if (stanchion != null && stanchion.isNotEmpty) parts.add(stanchion);
  return parts.isEmpty ? null : parts.join(' · ');
}

// --- stage 4: dampers --------------------------------------------------------

class _DamperList extends StatelessWidget {
  const _DamperList({required this.dampers, required this.onSelect});

  final List<DamperSpec> dampers;
  final ValueChanged<DamperSpec> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: dampers.length,
      itemBuilder: (context, index) {
        final damper = dampers[index];
        final description = damper.description;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(damper.name),
            subtitle: _damperSubtitle(damper),
            trailing: _chevron,
            isThreeLine: description != null && description.isNotEmpty,
            onTap: () => onSelect(damper),
          ),
        );
      },
    );
  }
}

/// Description above a summary of the damper's click ranges; `null` when the
/// catalog has neither.
Widget? _damperSubtitle(DamperSpec damper) {
  final lines = <String>[];
  final description = damper.description?.trim();
  if (description != null && description.isNotEmpty) lines.add(description);
  final adjustments = _damperAdjustments(damper);
  if (adjustments.isNotEmpty) lines.add(adjustments);
  return lines.isEmpty ? null : Text(lines.join('\n'));
}

/// `LSC ±7 · HSC 5` — initials and range of each stepped adjustment, so dampers
/// can be compared without opening them.
String _damperAdjustments(DamperSpec damper) {
  final parts = <String>[];
  for (final spec in damper.adjustmentSpecs) {
    final adjustment = spec.build();
    if (adjustment is StepAdjustment) {
      parts.add('${_initials(adjustment.name)} ${_rangeLabel(adjustment)}');
    }
  }
  return parts.join(' · ');
}

/// `Low Speed Compression` → `LSC`; single-word names are left alone.
String _initials(String name) {
  final words = name.split(RegExp(r'[\s\-]+')).where((word) => word.isNotEmpty).toList();
  if (words.length <= 1) return name;
  return words.map((word) => word[0].toUpperCase()).join();
}

String _rangeLabel(StepAdjustment step) {
  if (step.max > 0 && step.min == -step.max) return '±${step.max}';
  if (step.min == 0) return '${step.max}';
  return '${step.min}…${step.max}';
}

// --- shared bits -------------------------------------------------------------

class _SubtitleText extends StatelessWidget {
  const _SubtitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
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

class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    return const ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      child: LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.transparent),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Could not load the catalog.'),
    );
  }
}
