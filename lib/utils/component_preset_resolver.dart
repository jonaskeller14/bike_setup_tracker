import 'package:collection/collection.dart';

import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';

const String _brandKey = 'brand';
const String _componentTypeKey = 'component_type';

/// A catalog selection as far as it is resolved: the node path, plus the option
/// values chosen on the product it ends at.
///
/// It is the one shape every step shares — a catalog entry before anything is
/// picked, a suggestion with its damper set, the picker's result, and a saved
/// `Component.preset` map read back.
class ResolvedPreset {
  final BrandCatalog catalog;

  /// From the top-level node down to the deepest one that matched; never empty.
  final List<CatalogNode> path;

  /// Axis id → chosen value, in the product's axis order. An axis with a single
  /// value is always present, so it is never asked for and is persisted anyway.
  final Map<String, OptionValue> selections;

  const ResolvedPreset._(this.catalog, this.path, this.selections);

  factory ResolvedPreset({
    required BrandCatalog catalog,
    required List<CatalogNode> path,
    Map<String, OptionValue> selections = const {},
  }) {
    final node = path.last;
    return ResolvedPreset._(catalog, path, {
      if (node is CatalogProduct)
        for (final axis in node.options.values)
          axis.id: ?(axis.values.length == 1 ? axis.values.single : selections[axis.id]),
    });
  }

  CatalogNode get node => path.last;

  /// Null when the path stops at a group: a saved map that is short or stale.
  CatalogProduct? get product => switch (path.last) {
    final CatalogProduct product => product,
    CatalogGroup() => null,
  };

  /// The node's specs, overridden by those of the chosen option values.
  Specs get effectiveSpecs => selections.values.fold(node.specs, (specs, value) => specs.mergedWith(value.specs));

  /// Every option axis of the product; empty while the path stops at a group.
  Iterable<OptionAxis> get axes => product?.options.values ?? const [];

  /// Required axes without a value yet. The adjustment list is incomplete
  /// until each of them is chosen.
  List<OptionAxis> get openRequiredAxes => [
    for (final axis in axes)
      if (axis.required && !selections.containsKey(axis.id)) axis,
  ];

  /// Axes the user may leave unset, whether or not a value is chosen.
  List<OptionAxis> get optionalAxes => [
    for (final axis in axes)
      if (!axis.required && axis.values.length > 1) axis,
  ];

  /// A copy with [value] chosen on [axis]; null clears the choice.
  ResolvedPreset select(OptionAxis axis, OptionValue? value) {
    final next = {...selections};
    if (value == null) {
      next.remove(axis.id);
    } else {
      next[axis.id] = value;
    }
    return ResolvedPreset(catalog: catalog, path: path, selections: next);
  }
}

/// Every product of [catalog] in authored order, draft ones included.
Iterable<ResolvedPreset> catalogProducts(BrandCatalog catalog) {
  Iterable<ResolvedPreset> visit(List<CatalogNode> nodes, List<CatalogNode> parents) sync* {
    for (final node in nodes) {
      final path = [...parents, node];
      switch (node) {
        case CatalogGroup(:final children):
          yield* visit(children, path);
        case CatalogProduct():
          yield ResolvedPreset(catalog: catalog, path: path);
      }
    }
  }

  return visit(catalog.nodes, const []);
}

/// Reads a persisted `Component.preset` map back against [catalogs].
///
/// Walks the tree one level per step and stops at the deepest node that still
/// matches, so a map that is short, or whose deeper entries were retired from
/// the data, resolves as far as it can. Entries that match nothing are ignored.
/// Null when not even the first level matches.
ResolvedPreset? resolvePreset(Iterable<BrandCatalog> catalogs, Map<String, Object> preset) {
  final catalog = catalogs.firstWhereOrNull(
    (catalog) => preset[_brandKey] == catalog.id && preset[_componentTypeKey] == catalog.componentType.name,
  );
  if (catalog == null) return null;

  final path = <CatalogNode>[];
  List<CatalogNode>? siblings = catalog.nodes;
  while (siblings != null) {
    final node = siblings.firstWhereOrNull((node) => preset[node.level] == node.id);
    if (node == null) break;
    path.add(node);
    siblings = node is CatalogGroup ? node.children : null;
  }
  if (path.isEmpty) return null;

  final node = path.last;
  return ResolvedPreset(
    catalog: catalog,
    path: path,
    selections: {
      if (node is CatalogProduct)
        for (final axis in node.options.values)
          axis.id: ?axis.values.firstWhereOrNull((value) => value.id == preset[axis.id]),
    },
  );
}

/// The map a component persists for [resolved]: one entry per tree level and
/// one per chosen option. An option the user skipped is absent.
Map<String, Object> toPresetMap(ResolvedPreset resolved) => {
  _brandKey: resolved.catalog.id,
  _componentTypeKey: resolved.catalog.componentType.name,
  for (final node in resolved.path) node.level: node.id,
  for (final MapEntry(key: axisId, :value) in resolved.selections.entries) axisId: value.id,
};
