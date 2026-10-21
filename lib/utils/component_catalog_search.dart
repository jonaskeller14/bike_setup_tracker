import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import 'component_preset_resolver.dart';

/// The text a product is found by: brand, every label on its path, its years
/// and the values of its required axes (the damper names).
String presetSearchHaystack(ResolvedPreset product) {
  final parts = <String>[
    product.catalog.brand,
    for (final node in product.path) node.label,
    ?product.node.years?.toString(),
    for (final axis in product.axes)
      if (axis.required)
        for (final value in axis.values) value.label,
    // The brand without its accents, so `ohlins` finds Öhlins.
    product.catalog.id,
  ];
  return parts.join(' ').toLowerCase();
}

/// The first four-digit year in [query], e.g. `2022` in `fox 36 2022`.
int? queryYear(String query) {
  final match = RegExp(r'(?<!\d)(?:19|20)\d{2}(?!\d)').firstMatch(query);
  return match == null ? null : int.parse(match[0]!);
}

/// Case-insensitive AND-of-tokens match: every whitespace-separated token in
/// [query] must appear somewhere in [haystack] (already lower-cased).
bool presetHaystackMatches(String haystack, String query) {
  final tokens = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return false;
  return tokens.every(haystack.contains);
}

/// [presetHaystackMatches] on [product], where a four-digit year token also
/// matches a product whose years span it: `2022` finds `2021-2024`.
bool presetMatches(ResolvedPreset product, String query) {
  final years = product.node.years;
  final haystack = presetSearchHaystack(product);
  final tokens = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return false;
  return tokens.every((token) {
    if (haystack.contains(token)) return true;
    return years != null && _yearToken.hasMatch(token) && years.contains(int.parse(token));
  });
}

final _yearToken = RegExp(r'^(?:19|20)\d{2}$');

/// The products matching [query], best first. One ranking for the picker search
/// and the name autocomplete: match tier (whole query prefixes the brand → first
/// token prefixes the brand → query prefixes the searchable text → any match),
/// then a product whose years span a year typed in the query, then the newest
/// years, then input (catalog) order.
List<ResolvedPreset> rankPresets(List<ResolvedPreset> products, String query) {
  final normalized = query.trim().toLowerCase();
  final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return const [];
  final year = queryYear(normalized);

  final ranked = [
    for (var i = 0; i < products.length; i++)
      if (presetMatches(products[i], normalized))
        (
          product: products[i],
          tier: _matchTier(products[i], normalized, tokens.first),
          typedYear: year != null && (products[i].node.years?.contains(year) ?? false) ? 0 : 1,
          index: i,
        ),
  ];
  ranked.sort((a, b) {
    if (a.tier != b.tier) return a.tier.compareTo(b.tier);
    if (a.typedYear != b.typedYear) return a.typedYear.compareTo(b.typedYear);
    final newest = _newestFirst(a.product, b.product);
    return newest != 0 ? newest : a.index.compareTo(b.index);
  });
  return [for (final entry in ranked) entry.product];
}

/// Later years first; a product without years after those with.
int _newestFirst(ResolvedPreset a, ResolvedPreset b) {
  final yearsA = a.node.years;
  final yearsB = b.node.years;
  if (yearsA == null || yearsB == null) return yearsA == yearsB ? 0 : (yearsA == null ? 1 : -1);
  final last = yearsB.last.compareTo(yearsA.last);
  return last != 0 ? last : yearsB.first.compareTo(yearsA.first);
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

/// Ranks matching [products] with [rankPresets] and expands them into flat
/// suggestions for the name-field autocomplete, all of them unless [limit] is
/// set: the overlay scrolls, and a cut would hide whole models behind one
/// model's variants. Returns empty below [minChars] characters.
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
  if (query.trim().length < minChars) return const [];
  final suggestions = rankPresets(products, query).expand(_requiredCombinations);
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

int _matchTier(ResolvedPreset product, String query, String firstToken) {
  final brand = product.catalog.brand.toLowerCase();
  final brandId = product.catalog.id;
  if (brand.startsWith(query) || brandId.startsWith(query)) return 0;
  if (brand.startsWith(firstToken) || brandId.startsWith(firstToken)) return 1;
  if (presetSearchHaystack(product).startsWith(query)) return 2;
  return 3;
}
