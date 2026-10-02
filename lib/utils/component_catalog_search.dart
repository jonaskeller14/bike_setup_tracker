import 'component_preset_resolver.dart';
import 'component_preset_search.dart' show presetHaystackMatches;

/// The text a product is found by: brand, every label on its path, its years
/// and the values of its required axes (the damper names).
String presetSearchHaystack(ResolvedPreset product) {
  final parts = <String>[
    product.catalog.brand,
    for (final node in product.path) node.label,
    ?product.node.years,
    for (final axis in product.axes)
      if (axis.required)
        for (final value in axis.values) value.label,
    // The brand without its accents, so `ohlins` finds Öhlins.
    product.catalog.id,
  ];
  return parts.join(' ').toLowerCase();
}

/// Filters [products] to those matching [query], preserving input order.
List<ResolvedPreset> filterPresets(List<ResolvedPreset> products, String query) {
  return products.where((product) => presetHaystackMatches(presetSearchHaystack(product), query)).toList();
}

/// Ranks matching [products] and expands them into at most [limit] flat
/// suggestions for the name-field autocomplete. Returns empty below
/// [minChars] characters. Ranking (best first): whole query prefixes the brand
/// → first token prefixes the brand → query prefixes the searchable text →
/// generic token match; ties keep the input (catalog) order.
///
/// An autocomplete has no sub-step to ask in, so a product yields one
/// suggestion per combination of required-axis values. Optional axes stay
/// unset.
List<ResolvedPreset> suggestPresets(
  List<ResolvedPreset> products,
  String query, {
  int limit = 5,
  int minChars = 3,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.length < minChars) return const [];
  final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return const [];

  final matched = filterPresets(products, normalized);

  // Stable sort by rank: index tiebreak preserves first-seen (catalog) order.
  final indexed = [
    for (var i = 0; i < matched.length; i++) MapEntry(i, matched[i]),
  ];
  indexed.sort((a, b) {
    final rankA = _suggestionRank(a.value, normalized, tokens.first);
    final rankB = _suggestionRank(b.value, normalized, tokens.first);
    return rankA != rankB ? rankA.compareTo(rankB) : a.key.compareTo(b.key);
  });

  return indexed.expand((entry) => _requiredCombinations(entry.value)).take(limit).toList();
}

Iterable<ResolvedPreset> _requiredCombinations(ResolvedPreset preset) sync* {
  final axis = preset.openRequiredAxes.firstOrNull;
  if (axis == null) {
    yield preset;
    return;
  }
  for (final value in axis.values) {
    yield* _requiredCombinations(preset.select(axis, value));
  }
}

int _suggestionRank(ResolvedPreset product, String query, String firstToken) {
  final brand = product.catalog.brand.toLowerCase();
  final brandId = product.catalog.id;
  if (brand.startsWith(query) || brandId.startsWith(query)) return 0;
  if (brand.startsWith(firstToken) || brandId.startsWith(firstToken)) return 1;
  if (presetSearchHaystack(product).startsWith(query)) return 2;
  return 3;
}
