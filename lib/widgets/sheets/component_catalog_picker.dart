import 'dart:async';

import 'package:collection/collection.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/component/component.dart';
import '../../models/component/component_catalog.dart';
import '../../models/component/preset_spec_keys.dart';
import '../../models/component/year_span.dart';
import '../../repositories/component_catalog_repository.dart';
import '../../utils/component_catalog_application.dart';
import '../../utils/component_catalog_search.dart';
import '../../utils/component_preset_resolver.dart';
import '../year_badge.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// Lets the user drill into the generic catalog of [componentType]: brand, then
/// one stage per tree level, then the required option axes one at a time, then
/// the optional axes together in a single skippable step.
///
/// With a [current] selection the sheet opens on its options, preselected, with
/// the path to it marked on the way back, so changing it is a short step.
///
/// A search without results offers [onEnterManually], called with the query
/// once the sheet has closed, and [onRequestProduct] to ask for the product.
Future<ResolvedPreset?> showComponentCatalogPicker({
  required BuildContext context,
  required ComponentType componentType,
  ResolvedPreset? current,
  ValueChanged<String>? onEnterManually,
  void Function(ComponentType type, String query) onRequestProduct = _logCatalogRequest,
}) {
  return showModalBottomSheet<ResolvedPreset>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _ComponentCatalogPickerSheet(
      componentType: componentType,
      current: current?.catalog.componentType == componentType ? current : null,
      onEnterManually: onEnterManually,
      onRequestProduct: onRequestProduct,
    ),
  );
}

/// An Analytics event rather than a Crashlytics report: requests are counted
/// per query, not grouped under one stack trace. Values are capped at 100
/// characters by Analytics.
void _logCatalogRequest(ComponentType type, String query) {
  if (kDebugMode) return;
  unawaited(FirebaseAnalytics.instance.logEvent(
    name: 'catalog_request',
    parameters: {
      'component_type': type.name,
      'query': query.length > 100 ? query.substring(0, 100) : query,
    },
  ));
}

const Duration _stageDuration = Duration(milliseconds: 260);
const int _minQueryLength = 2;
const String _uncategorised = 'Other';

const Widget _chevron = Icon(Icons.arrow_forward_ios, size: 16);

/// Trailing icon of a row whose tap completes the selection.
const Widget _check = Icon(Icons.check, size: 20);

/// Nothing is left to ask after [preset], so choosing it closes the sheet.
bool _completes(ResolvedPreset preset) => preset.openRequiredAxes.isEmpty && !preset.hasOptionalDetails;

// --- where we are ------------------------------------------------------------

sealed class _Stage {
  const _Stage();
}

class _Brands extends _Stage {
  const _Brands();
}

/// The children of [parents] within [catalog]; [parents] is empty at the
/// brand's top level.
class _Nodes extends _Stage {
  _Nodes(this.catalog, this.parents);

  final BrandCatalog catalog;
  final List<CatalogNode> parents;
}

/// The first required axis of [preset] that is still open.
class _RequiredAxis extends _Stage {
  _RequiredAxis(this.preset);

  final ResolvedPreset preset;

  OptionAxis get axis => preset.openRequiredAxes.first;
}

class _OptionalAxes extends _Stage {
  _OptionalAxes(this.preset);

  final ResolvedPreset preset;
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

class _ComponentCatalogPickerSheet extends StatefulWidget {
  final ComponentType componentType;
  final ResolvedPreset? current;
  final ValueChanged<String>? onEnterManually;
  final void Function(ComponentType type, String query) onRequestProduct;

  const _ComponentCatalogPickerSheet({
    required this.componentType,
    this.current,
    this.onEnterManually,
    required this.onRequestProduct,
  });

  @override
  State<_ComponentCatalogPickerSheet> createState() => _ComponentCatalogPickerSheetState();
}

class _ComponentCatalogPickerSheetState extends State<_ComponentCatalogPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  _Catalog? _catalog;
  Object? _loadError;

  _Stage _stage = const _Brands();

  /// Stages to return to. The tree depth differs per brand, and a search
  /// result jumps straight past it, so the way back is recorded, not derived.
  final List<_Stage> _history = [];
  _Direction _direction = _Direction.none;
  String _query = '';

  /// Queries already requested, so one search asks only once.
  final Set<String> _requested = {};

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
    final repository = context.read<ComponentCatalogRepository>();
    try {
      final products = await repository.forType(widget.componentType);
      if (!mounted) return;
      setState(() {
        final catalog = _catalog = _Catalog(products);
        _openAtCurrent(catalog);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  // --- the current selection ------------------------------------------------

  /// Opens on the current product's options, with every stage that leads there
  /// as the way back. A path that no longer fully resolves, or leads through
  /// draft nodes, opens as deep as it still reaches.
  void _openAtCurrent(_Catalog catalog) {
    final current = widget.current;
    if (current == null) return;
    final brand = catalog.brands.firstWhereOrNull((entry) => entry.catalog.id == current.catalog.id)?.catalog;
    if (brand == null) return;
    final parents = <CatalogNode>[];
    ResolvedPreset? product;
    for (final target in current.path) {
      final match = catalog.childrenOf(brand, parents).firstWhereOrNull((entry) => entry.node.id == target.id);
      if (match == null) break;
      if (match.node is CatalogProduct) {
        product = match.products.single;
        break;
      }
      parents.add(match.node);
    }
    for (var depth = 0; depth <= parents.length; depth++) {
      final shown = _collapse(catalog, brand, parents.sublist(0, depth));
      if (shown.length == depth || depth == parents.length) _enter(_Nodes(brand, shown));
    }
    if (product != null) _enterOptionsOf(product);
  }

  /// Replays the current values of [product]'s required axes, stopping on the
  /// first one the catalog no longer offers, then opens the optional axes. A
  /// product without optional axes stays on its last required one, so a single
  /// tap still changes it; one with nothing to ask stays among its siblings.
  void _enterOptionsOf(ResolvedPreset product) {
    if (_completes(product)) return;
    var preset = product;
    while (preset.openRequiredAxes.isNotEmpty) {
      final stage = _RequiredAxis(preset);
      _enter(stage);
      final id = widget.current!.selections[stage.axis.id]?.id;
      final value = stage.axis.values.firstWhereOrNull((value) => value.id == id);
      if (value == null) return;
      preset = preset.select(stage.axis, value);
      if (_completes(preset)) return;
    }
    _enter(_OptionalAxes(_withCurrentOptions(preset)));
  }

  /// Whether [nodes], from the top level down, lead along the current path.
  bool _onCurrentPath(BrandCatalog brand, List<CatalogNode> nodes) {
    final current = widget.current;
    if (current == null || current.catalog.id != brand.id || nodes.length > current.path.length) return false;
    for (var depth = 0; depth < nodes.length; depth++) {
      if (nodes[depth].id != current.path[depth].id) return false;
    }
    return true;
  }

  /// The current selection when [preset] is the same product.
  ResolvedPreset? _currentFor(ResolvedPreset preset) {
    final current = widget.current;
    if (current == null || preset.path.length != current.path.length) return null;
    return _onCurrentPath(preset.catalog, preset.path) ? current : null;
  }

  bool _isCurrent(ResolvedPreset preset) => _currentFor(preset) != null;

  /// [preset] with the optional values of the current selection chosen, when
  /// it is the same product; a value the catalog dropped stays unset. The model
  /// year falls back to one typed in the search.
  ResolvedPreset _withCurrentOptions(ResolvedPreset preset) {
    final current = _currentFor(preset);
    var result = preset.withYear(current?.year ?? queryYear(_query));
    if (current == null) return result;
    for (final axis in preset.optionalAxes) {
      final id = current.selections[axis.id]?.id;
      final value = axis.values.firstWhereOrNull((value) => value.id == id);
      if (value != null) result = result.select(axis, value);
    }
    return result;
  }

  // --- navigation -----------------------------------------------------------

  void _enter(_Stage stage) {
    _history.add(_stage);
    _stage = stage;
  }

  void _goTo(_Stage stage) {
    setState(() {
      _enter(stage);
      _direction = _Direction.forward;
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    setState(() {
      _stage = _history.removeLast();
      _direction = _Direction.backward;
    });
  }

  /// Returns to the stage at [depth] of the way taken, where the choice its
  /// breadcrumb names was made.
  void _goBackTo(int depth) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _stage = _history[depth];
      _history.removeRange(depth, _history.length);
      _direction = _Direction.backward;
    });
  }

  /// [parents] extended through every group whose only child is another group:
  /// listing that child would ask for a tap that decides nothing.
  List<CatalogNode> _collapse(_Catalog catalog, BrandCatalog brand, List<CatalogNode> parents) {
    var result = parents;
    while (true) {
      final children = catalog.childrenOf(brand, result);
      if (children.length != 1 || children.single.node is! CatalogGroup) return result;
      result = [...result, children.single.node];
    }
  }

  void _selectNode(_NodeEntry entry) {
    switch (entry.node) {
      case CatalogGroup():
        final stage = _stage as _Nodes;
        _goTo(_Nodes(stage.catalog, _collapse(_catalog!, stage.catalog, [...stage.parents, entry.node])));
      case CatalogProduct():
        _advance(entry.products.single);
    }
  }

  /// Asks for what [preset] still lacks: each open required axis in turn, then
  /// the optional axes once. Single-value axes are already resolved, so they
  /// never get a stage.
  void _advance(ResolvedPreset preset) {
    if (preset.openRequiredAxes.isNotEmpty) return _goTo(_RequiredAxis(preset));
    if (preset.hasOptionalDetails) return _goTo(_OptionalAxes(_withCurrentOptions(preset)));
    _finish(preset);
  }

  void _finish(ResolvedPreset preset) {
    unawaited(HapticFeedback.selectionClick());
    Navigator.pop(context, preset);
  }

  // --- search ---------------------------------------------------------------

  bool get _isSearching => _stage is _Brands && _query.length >= _minQueryLength;

  /// Search isn't part of the drill-down hierarchy, so crossing the threshold
  /// into (or out of) results cross-fades without sliding.
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

  void _enterManually() {
    final query = _query;
    Navigator.pop(context);
    widget.onEnterManually!(query);
  }

  void _requestProduct() {
    unawaited(HapticFeedback.lightImpact());
    widget.onRequestProduct(widget.componentType, _query);
    setState(() => _requested.add(_query.toLowerCase()));
  }

  // --- build ----------------------------------------------------------------

  String get _title => switch (_stage) {
    _Brands() => 'Choose from catalog',
    _Nodes(:final catalog, :final parents) => _nodesTitle(_catalog?.childrenOf(catalog, parents) ?? const []),
    final _RequiredAxis stage => 'Select ${stage.axis.key.label.toLowerCase()}',
    _OptionalAxes() => 'Optional details',
  };

  /// Identity of the body on screen; the switcher animates whenever it changes.
  /// [_stage] is replaced only by navigation, so comparing stages by identity is
  /// exactly the "did we move?" test.
  Key get _bodyKey => ValueKey((_stage, _isSearching, _catalog, _loadError));

  @override
  Widget build(BuildContext context) {
    // System back steps back a stage; the close button pops directly.
    return PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Padding(
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
                  onBack: _history.isEmpty ? null : _goBack,
                ),
                const SizedBox(height: 12),
                if (_stage is _Brands)
                  _buildSearchField()
                else
                  _Breadcrumb(crumbs: _crumbs([..._history, _stage]), onTap: _goBackTo),
                Flexible(
                  child: ListTileTheme.merge(
                    selectedColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: _StageSwitcher(
                      direction: _direction,
                      child: KeyedSubtree(key: _bodyKey, child: _buildBody()),
                    ),
                  ),
                ),
              ],
            ),
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
        isCurrent: (brand) => _onCurrentPath(brand.catalog, const []),
        onSelect: (brand) => _goTo(_Nodes(brand.catalog, _collapse(catalog, brand.catalog, const []))),
      ),
      _Nodes(catalog: final brand, :final parents) => _NodeList(
        rows: catalog.rowsFor(brand, parents),
        isCurrent: (entry) => _onCurrentPath(brand, [...parents, entry.node]),
        onSelect: _selectNode,
      ),
      final _RequiredAxis stage => _RequiredValueList(
        values: stage.axis.values,
        currentId: _currentFor(stage.preset)?.selections[stage.axis.id]?.id,
        completes: (value) => _completes(stage.preset.select(stage.axis, value)),
        onSelect: (value) => _advance(stage.preset.select(stage.axis, value)),
      ),
      _OptionalAxes(:final preset) => _OptionalAxesStep(preset: preset, onDone: _finish),
    };
  }

  Widget _buildSearchResults(_Catalog catalog) {
    final results = rankPresets(catalog.products, _query);
    if (results.isEmpty) {
      return _NoMatches(
        query: _query,
        onEnterManually: widget.onEnterManually == null ? null : _enterManually,
        onRequest: _requested.contains(_query.toLowerCase()) ? null : _requestProduct,
      );
    }
    return _ProductList(products: results, isCurrent: _isCurrent, onSelect: _advance);
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
          suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: _clearQuery),
          hintText: 'Search ${widget.componentType.label.toLowerCase()}s…',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// `Select trim`, from the level the listed nodes sit on.
String _nodesTitle(List<_NodeEntry> children) {
  final levels = {for (final child in children) _levelLabel(child.node.level)};
  return levels.isEmpty ? 'Select' : 'Select ${levels.join(' / ')}';
}

String _levelLabel(String level) => level.replaceAll('_', ' ');

// --- breadcrumb --------------------------------------------------------------

/// The choices that led to the last of [stages], one per stage they were made
/// on, each named after what it opened: `FOX › 36 › 2025–2026 › Factory`.
List<String> _crumbs(List<_Stage> stages) => [
  for (var i = 0; i < stages.length - 1; i++) _crumbLabel(stages[i], stages[i + 1]),
];

String _crumbLabel(_Stage from, _Stage to) => switch ((from, to)) {
  // Groups collapsed into one stage are one choice, so they share a crumb.
  (_Nodes(parents: final above), _Nodes(:final parents)) =>
    parents.skip(above.length).map((node) => node.label).join(' '),
  (_, _Nodes(:final catalog, :final parents)) => [catalog.brand, for (final node in parents) node.label].join(' '),
  (_RequiredAxis(:final axis), _RequiredAxis(:final preset) || _OptionalAxes(:final preset)) =>
    preset.selections[axis.id]!.label,
  (_Nodes(), _RequiredAxis(:final preset) || _OptionalAxes(:final preset)) => preset.node.label,
  // A search result skips the tree, so its crumb is the whole name.
  (_, _RequiredAxis(:final preset) || _OptionalAxes(:final preset)) => presetDisplayName(preset),
  (_, _Brands()) => throw StateError('No choice leads to the brand list'),
};

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.crumbs, required this.onTap});

  final List<String> crumbs;

  /// Called with the index of the tapped crumb.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(
        // Clips the crumbs' ripples to the visible strip.
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Keeps the latest choice in view when the path is wider than the sheet.
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, label) in crumbs.indexed) ...[
                  if (index > 0) Icon(Icons.chevron_right, size: 16, color: muted),
                  Semantics(
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onTap(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          label,
                          maxLines: 1,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: index == crumbs.length - 1 ? theme.colorScheme.onSurface : muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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

/// The selectable products, indexed for the drill-down. The tree is walked
/// through the products' paths rather than [BrandCatalog.nodes], so a draft
/// node and a group with nothing selectable below it never appear.
class _Catalog {
  _Catalog(this.products) {
    for (final product in products) {
      _productsByBrand.putIfAbsent(product.catalog, () => []).add(product);
    }
  }

  /// Every selectable product of the type, in catalog order — the corpus search
  /// runs over.
  final List<ResolvedPreset> products;

  final Map<BrandCatalog, List<ResolvedPreset>> _productsByBrand = {};

  /// Stage 1, in first-seen order.
  List<_BrandEntry> get brands => [
    for (final MapEntry(key: catalog, value: products) in _productsByBrand.entries)
      _BrandEntry(catalog: catalog, models: _distinctLabels(products.map((product) => product.path.first))),
  ];

  /// The nodes one level below [parents], each with the products beneath it.
  List<_NodeEntry> childrenOf(BrandCatalog catalog, List<CatalogNode> parents) {
    final depth = parents.length;
    final children = <CatalogNode, List<ResolvedPreset>>{};
    for (final product in _productsByBrand[catalog] ?? const <ResolvedPreset>[]) {
      if (product.path.length <= depth) continue;
      if (!const ListEquality<CatalogNode>(IdentityEquality()).equals(product.path.sublist(0, depth), parents)) {
        continue;
      }
      children.putIfAbsent(product.path[depth], () => []).add(product);
    }
    return [
      for (final MapEntry(key: node, value: products) in children.entries)
        _NodeEntry(node: node, products: products),
    ];
  }

  /// [childrenOf], with category headers interleaved at the brand's top level,
  /// where categories split the models. Deeper levels inherit their parent's
  /// category, so a header there would only repeat it.
  List<_NodeRow> rowsFor(BrandCatalog catalog, List<CatalogNode> parents) {
    final children = childrenOf(catalog, parents);
    if (parents.isNotEmpty || children.every((child) => child.node.category == null)) return children;
    final byCategory = groupBy(children, (child) => child.node.category ?? _uncategorised);
    return [
      for (final MapEntry(key: category, value: entries) in byCategory.entries) ...[
        _CategoryRow(category),
        ...entries,
      ],
    ];
  }
}

class _BrandEntry {
  const _BrandEntry({required this.catalog, required this.models});

  final BrandCatalog catalog;

  /// The labels of the brand's top level, in authored order.
  final List<String> models;
}

/// The distinct labels of [nodes], in first-seen order.
List<String> _distinctLabels(Iterable<CatalogNode> nodes) => [...{for (final node in nodes) node.label}];

String? _labelsSubtitle(List<String> labels) => labels.isEmpty ? null : labels.join(' · ');

/// One row of a node stage: a category header or a node.
sealed class _NodeRow {
  const _NodeRow();
}

class _CategoryRow extends _NodeRow {
  const _CategoryRow(this.category);

  final String category;
}

class _NodeEntry extends _NodeRow {
  const _NodeEntry({required this.node, required this.products});

  final CatalogNode node;

  /// The selectable products at or below [node]; the single product itself
  /// when [node] is a [CatalogProduct].
  final List<ResolvedPreset> products;
}

// --- stage 1: brands ---------------------------------------------------------

class _BrandList extends StatelessWidget {
  const _BrandList({required this.brands, required this.isCurrent, required this.onSelect});

  final List<_BrandEntry> brands;
  final bool Function(_BrandEntry) isCurrent;
  final ValueChanged<_BrandEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return const _EmptyHint(text: 'No catalog entries available.');
    }
    return _TileList(
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final entry = brands[index];
        final subtitle = _labelsSubtitle(entry.models);
        final selected = isCurrent(entry);
        return ListTile(
          title: _TileTitle(entry.catalog.brand, selected: selected),
          subtitle: subtitle == null ? null : _SubtitleText(subtitle),
          trailing: _chevron,
          selected: selected,
          onTap: () => onSelect(entry),
        );
      },
    );
  }
}

// --- stage 2: one level of the brand's tree ----------------------------------

class _NodeList extends StatelessWidget {
  const _NodeList({required this.rows, required this.isCurrent, required this.onSelect});

  final List<_NodeRow> rows;
  final bool Function(_NodeEntry) isCurrent;
  final ValueChanged<_NodeEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return _TileList(
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _CategoryRow(:final category) => _CategoryHeader(category),
        final _NodeEntry entry => switch (entry.node) {
          CatalogGroup(:final level) => ListTile(
            title: _TileTitle(entry.node.label, selected: isCurrent(entry)),
            subtitle: _groupSubtitle(entry),
            // A generation is named by its years already.
            trailing: _Trailing(level == _generationLevel ? null : _yearSpan(entry), icon: _chevron),
            selected: isCurrent(entry),
            onTap: () => onSelect(entry),
          ),
          CatalogProduct() => _ProductTile(
            product: entry.products.single,
            title: entry.node.label,
            selected: isCurrent(entry),
            onTap: () => onSelect(entry),
          ),
        },
      },
    );
  }
}

const String _generationLevel = 'generation';

/// `Factory · Performance`: the products below the group, so a row says what a
/// tap leads to. Generations are left out, as the rows below are named by them.
Widget? _groupSubtitle(_NodeEntry entry) {
  final labels = _labelsSubtitle(
    _distinctLabels(entry.products.map((product) => product.node).where((node) => node.level != _generationLevel)),
  );
  return labels == null ? null : _SubtitleText(labels);
}

/// The years a group row covers. Its products can belong to different
/// generations, so when they disagree the row shows the whole span
/// (`2018-2026`) and the per-generation years stay on the deeper rows.
YearSpan? _yearSpan(_NodeEntry entry) => YearSpan.cover(entry.products.map((product) => product.node.years).nonNulls);

// --- products, and the flat search results -----------------------------------

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, required this.isCurrent, required this.onSelect});

  final List<ResolvedPreset> products;
  final bool Function(ResolvedPreset) isCurrent;
  final ValueChanged<ResolvedPreset> onSelect;

  @override
  Widget build(BuildContext context) {
    return _TileList(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductTile(
          product: product,
          // A flat result list has no brand/model context around it, so spell
          // the whole name out.
          title: presetDisplayName(product),
          selected: isCurrent(product),
          onTap: () => onSelect(product),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.title, required this.selected, required this.onTap});

  final ResolvedPreset product;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = _productSubtitle(product);
    return ListTile(
      title: _TileTitle(title, selected: selected),
      subtitle: subtitle == null ? null : _SubtitleText(subtitle),
      trailing: _Trailing(product.node.years, icon: _completes(product) ? _check : _chevron),
      selected: selected,
      onTap: onTap,
    );
  }
}

/// [icon], preceded by the year badge when there are [years] to show.
class _Trailing extends StatelessWidget {
  const _Trailing(this.years, {required this.icon});

  final YearSpan? years;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final years = this.years;
    if (years == null) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [YearBadge(years), const SizedBox(width: 6), icon],
    );
  }
}

/// `GRIP X2 / GRIP X · 150 / 160 mm · Kashima`: what the product can be had
/// with, so siblings can be told apart before opening one.
String? _productSubtitle(ResolvedPreset product) {
  final stanchion = product.effectiveSpecs.get(PresetSpecKeys.stanchion);
  final parts = [
    for (final axis in product.axes) optionAxisSummary(axis),
    ?stanchion,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

// --- stage 3: required axes, one at a time -----------------------------------

class _RequiredValueList extends StatelessWidget {
  const _RequiredValueList({
    required this.values,
    required this.currentId,
    required this.completes,
    required this.onSelect,
  });

  final List<OptionValue> values;

  /// The value of the current selection, when this is its product.
  final Object? currentId;
  final bool Function(OptionValue) completes;
  final ValueChanged<OptionValue> onSelect;

  @override
  Widget build(BuildContext context) {
    return _TileList(
      itemCount: values.length,
      itemBuilder: (context, index) {
        final value = values[index];
        final lines = _valueSubtitleLines(value);
        final selected = value.id == currentId;
        return ListTile(
          title: _TileTitle(value.label, selected: selected),
          subtitle: lines.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final line in lines) _SubtitleText(line)],
                ),
          trailing: completes(value) ? _check : _chevron,
          selected: selected,
          isThreeLine: lines.length > 1,
          onTap: () => onSelect(value),
        );
      },
    );
  }
}

/// Description above a summary of the value's click ranges, one line each, so
/// each is cut short on its own rather than wrapping into the next.
List<String> _valueSubtitleLines(OptionValue value) {
  final lines = <String>[];
  final description = value.description?.trim();
  if (description != null && description.isNotEmpty) lines.add(description);
  final adjustments = _adjustmentSummary(value);
  if (adjustments.isNotEmpty) lines.add(adjustments);
  if (value.missingAdjustments.isNotEmpty) lines.add('Add by hand: ${value.missingAdjustments.join(', ')}');
  return lines;
}

/// `LSC ±7 · HSC 5` — initials and range of each stepped adjustment, so values
/// can be compared without opening them.
String _adjustmentSummary(OptionValue value) {
  final parts = <String>[];
  for (final spec in value.adjustments) {
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
  // A placeholder max is not a published range, so don't present it as one.
  if (step.notes?.contains(StepAdjustment.unknownMaxWarning) ?? false) return '?';
  if (step.max > 0 && step.min == -step.max) return '±${step.max}';
  if (step.min == 0) return '${step.max}';
  return '${step.min}…${step.max}';
}

// --- stage 4: optional axes, all at once -------------------------------------

class _OptionalAxesStep extends StatefulWidget {
  const _OptionalAxesStep({required this.preset, required this.onDone});

  final ResolvedPreset preset;
  final ValueChanged<ResolvedPreset> onDone;

  @override
  State<_OptionalAxesStep> createState() => _OptionalAxesStepState();
}

class _OptionalAxesStepState extends State<_OptionalAxesStep> {
  late ResolvedPreset _preset = widget.preset;

  bool get _hasChoice =>
      _preset.year != null || _preset.optionalAxes.any((axis) => _preset.selections.containsKey(axis.id));

  void _toggle(OptionAxis axis, OptionValue value) {
    unawaited(HapticFeedback.selectionClick());
    final selected = _preset.selections[axis.id] == value;
    setState(() => _preset = _preset.select(axis, selected ? null : value));
  }

  void _toggleYear(int year) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _preset = _preset.withYear(_preset.year == year ? null : year));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final axis in _preset.optionalAxes)
                  _AxisChips(
                    axis: axis,
                    selected: _preset.selections[axis.id],
                    onTap: (value) => _toggle(axis, value),
                  ),
                if (_preset.selectableYears.isNotEmpty)
                  _YearChips(years: _preset.selectableYears, selected: _preset.year, onTap: _toggleYear),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(_hasChoice ? Icons.check : Icons.arrow_forward),
            // Unset axes stay unset: nothing is guessed for what is skipped.
            onPressed: () => widget.onDone(_preset),
            label: Text(_hasChoice ? 'Apply' : 'Skip'),
          ),
        ),
      ],
    );
  }
}

class _AxisChips extends StatelessWidget {
  const _AxisChips({required this.axis, required this.selected, required this.onTap});

  final OptionAxis axis;
  final OptionValue? selected;
  final ValueChanged<OptionValue> onTap;

  @override
  Widget build(BuildContext context) {
    final groups = _chipGroups(axis);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetGroupTitle(title: axis.key.label),
        for (final MapEntry(key: heading, value: values) in groups.entries) ...[
          if (heading != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                heading,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(value.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: value == selected,
                  onSelected: (_) => onTap(value),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _YearChips extends StatelessWidget {
  const _YearChips({required this.years, required this.selected, required this.onTap});

  final List<int> years;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetGroupTitle(title: 'Model year'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final year in years)
              ChoiceChip(
                label: Text('$year'),
                selected: year == selected,
                onSelected: (_) => onTap(year),
              ),
          ],
        ),
      ],
    );
  }
}

/// Shock sizes are grouped by eye-to-eye length, since that is what a frame
/// fixes and the stroke is chosen within it. Every other axis is one group
/// without a heading, as is a size axis that lists strokes only.
Map<String?, List<OptionValue>> _chipGroups(OptionAxis axis) {
  if (axis.id != PresetOptionAxes.size.id) return {null: axis.values};
  final byLength = groupBy(axis.values, (value) => value.specs.get(PresetSpecKeys.eyeToEyeMm));
  if (byLength.keys.every((length) => length == null)) return {null: axis.values};
  return {
    for (final MapEntry(key: length, value: values) in byLength.entries)
      length == null
              ? _uncategorised
              : '${PresetSpecKeys.eyeToEyeMm.label} ${PresetSpecKeys.eyeToEyeMm.format(length)}':
          values,
  };
}

// --- shared bits -------------------------------------------------------------

class _TileList extends StatelessWidget {
  const _TileList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    // ListTile paints its tile color on the nearest Material; the sheet's own
    // sits outside the scroll view, so the color would scroll over the header.
    return Material(
      type: MaterialType.transparency,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Bold on the current row only, so the rest keep their weight below the
/// category headers.
class _TileTitle extends StatelessWidget {
  const _TileTitle(this.text, {required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: selected ? const TextStyle(fontWeight: FontWeight.w600) : null,
  );
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
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

/// A search without results, with the ways on from it.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query, required this.onEnterManually, required this.onRequest});

  final String query;
  final VoidCallback? onEnterManually;

  /// Null once [query] has been requested.
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final requested = onRequest == null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetFilterEmptyHint(
            icon: Icons.search_off,
            title: 'No matches for "$query".',
            hint: 'Check the spelling, or search for the model name only.',
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              if (onEnterManually != null)
                TextButton.icon(
                  onPressed: onEnterManually,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Enter manually'),
                ),
              TextButton.icon(
                onPressed: onRequest,
                icon: Icon(requested ? Icons.check : Icons.playlist_add),
                label: Text(requested ? 'Requested, thanks' : 'Request this product'),
              ),
            ],
          ),
        ],
      ),
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
