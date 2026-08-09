List<String> tokenizeSearchQuery(String query) =>
    query.trim().toLowerCase().split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();

bool searchFieldsMatch(Iterable<String?> fields, List<String> tokens) {
  if (tokens.isEmpty) return true;
  final haystack = fields.whereType<String>().join(' ').toLowerCase();
  return tokens.every(haystack.contains);
}
