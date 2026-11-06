import 'app_localizations.dart';

/// "a", "a and b", "a, b, and c": the joining words and the comma style follow the language.
String joinItems(AppLocalizations l10n, List<String> items) => switch (items.length) {
  0 => '',
  1 => items.single,
  2 => l10n.listJoinTwo(items.first, items.last),
  _ => l10n.listJoinMany(items.sublist(0, items.length - 1).join(', '), items.last),
};
