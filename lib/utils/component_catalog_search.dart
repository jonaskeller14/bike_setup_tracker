import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import 'component_preset_resolver.dart';

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

/// Case-insensitive AND-of-tokens match: every whitespace-separated token in
/// [query] must appear somewhere in [haystack] (already lower-cased).
bool presetHaystackMatches(String haystack, String query) {
  final tokens = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return false;
  return tokens.every(haystack.contains);
}

/// Filters [products] to those matching [query], preserving input order.
List<ResolvedPreset> filterPresets(List<ResolvedPreset> products, String query) {
  return products.where((product) => presetHaystackMatches(presetSearchHaystack(product), query)).toList();
}

/// Subtitle for a suggestion row: what the product can still be had with,
/// since its name already carries the required choices; `null` when nothing
/// is left.
String? presetSuggestionSubtitle(ResolvedPreset suggestion) {
  final parts = [for (final axis in suggestion.optionalAxes) optionAxisSummary(axis)];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// `GRIP X2 / GRIP X`, `150 / 160 mm`, or `12 sizes` where listing them all
/// would not fit a row.
String optionAxisSummary(OptionAxis axis) {
  if (axis.id == PresetOptionAxes.size.id && axis.values.length > 1) return '${axis.values.length} sizes';
  final unit = axis.key.spec?.unit;
  if (unit == null) return axis.values.map((value) => value.label).join(' / ');
  // `150 / 160 mm` instead of the unit on every value. A literal value is its own id.
  final values = axis.values.map(
    (value) => switch (value.id) {
      final num number => formatSpecNumber(number),
      final id => id.toString(),
    },
  );
  return '${values.join(' / ')} $unit';
}

/// Ranks matching [products] and expands them into flat suggestions for the
/// name-field autocomplete, all of them unless [limit] is set: the overlay
/// scrolls, and a cut would hide whole models behind one model's variants. Returns empty below
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
  int? limit,
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

  final suggestions = indexed.expand((entry) => _requiredCombinations(entry.value));
  return (limit == null ? suggestions : suggestions.take(limit)).toList();
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
