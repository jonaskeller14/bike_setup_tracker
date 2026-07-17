import '../models/component_preset.dart';
import 'component_preset_application.dart';

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

/// One row of the name-field autocomplete (C2): a variant paired with the
/// specific damper the row represents. Trims with more than one damper produce
/// one suggestion per damper (there is no damper sub-step in an autocomplete);
/// single-/no-damper trims produce a single suggestion with the damper resolved
/// (or `null`), ready to hand to `buildApplication`.
class PresetSuggestion {
  final ComponentPresetVariant variant;
  final DamperSpec? damper;

  const PresetSuggestion(this.variant, this.damper);

  /// Same name the applied component gets — reused so field and result agree.
  String get displayName => presetVariantDisplayName(variant, damper);
}

/// Subtitle for a suggestion row: `damper · travel` (year is rendered as a
/// separate badge by the caller). `null` when neither part is available.
String? presetSuggestionSubtitle(PresetSuggestion suggestion) {
  final parts = <String>[];
  final damperName = suggestion.damper?.name;
  if (damperName != null && damperName.isNotEmpty) parts.add(damperName);
  final travel = suggestion.variant.travelLabel;
  if (travel != null) parts.add(travel);
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Ranks matching [variants] and expands them into at most [limit] flat
/// suggestions for the name-field autocomplete. Returns empty below
/// [minChars] characters. Ranking (best first): whole query prefixes the brand
/// → first token prefixes the brand → query prefixes the searchable text →
/// generic token match; ties keep the input (catalog) order.
List<PresetSuggestion> suggestPresets(
  List<ComponentPresetVariant> variants,
  String query, {
  int limit = 5,
  int minChars = 3,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.length < minChars) return const [];
  final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return const [];

  final matched = <ComponentPresetVariant>[];
  for (final variant in variants) {
    if (presetHaystackMatches(presetSearchHaystack(variant), normalized)) {
      matched.add(variant);
    }
  }

  // Stable sort by rank: index tiebreak preserves first-seen (catalog) order.
  final indexed = [
    for (var i = 0; i < matched.length; i++) MapEntry(i, matched[i]),
  ];
  indexed.sort((a, b) {
    final rankA = _suggestionRank(a.value, normalized, tokens.first);
    final rankB = _suggestionRank(b.value, normalized, tokens.first);
    return rankA != rankB ? rankA.compareTo(rankB) : a.key.compareTo(b.key);
  });

  final suggestions = <PresetSuggestion>[];
  for (final entry in indexed) {
    final variant = entry.value;
    if (variant.dampers.length > 1) {
      for (final damper in variant.dampers) {
        suggestions.add(PresetSuggestion(variant, damper));
        if (suggestions.length >= limit) return suggestions;
      }
    } else {
      final damper = variant.dampers.length == 1 ? variant.dampers.single : null;
      suggestions.add(PresetSuggestion(variant, damper));
      if (suggestions.length >= limit) return suggestions;
    }
  }
  return suggestions;
}

int _suggestionRank(ComponentPresetVariant variant, String query, String firstToken) {
  final brand = variant.brand.toLowerCase();
  if (brand.startsWith(query)) return 0;
  if (brand.startsWith(firstToken)) return 1;
  if (presetSearchHaystack(variant).startsWith(query)) return 2;
  return 3;
}
