import '../models/component_preset.dart';

String presetSearchHaystack(ComponentPresetVariant variant) {
  final parts = <String>[
    variant.brand,
    variant.model,
    variant.trim,
    for (final damper in variant.dampers) damper.name,
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

/// Convenience: does [variant] match [query]?
bool presetVariantMatches(ComponentPresetVariant variant, String query) =>
    presetHaystackMatches(presetSearchHaystack(variant), query);

/// Filters [variants] to those matching [query], preserving input order.
List<ComponentPresetVariant> filterPresetVariants(
  List<ComponentPresetVariant> variants,
  String query,
) {
  return variants.where((v) => presetVariantMatches(v, query)).toList();
}
