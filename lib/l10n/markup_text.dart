import 'package:flutter/painting.dart';

final RegExp _markup = RegExp(r'<(b|i)>(.*?)</\1>', dotAll: true);

/// Turns a translated message into a [TextSpan], with `<b>…</b>` set bold and
/// `<i>…</i>` set italic. Translators move the markers with the words they
/// emphasize, so the emphasis survives a different word order.
///
/// [tags] adds markers of its own, like a link: each key names a marker and
/// builds the span for the text inside it.
TextSpan markupTextSpan(String message, {Map<String, TextSpan Function(String text)> tags = const {}}) {
  final pattern = tags.isEmpty ? _markup : RegExp('<(b|i|${tags.keys.join('|')})>(.*?)</\\1>', dotAll: true);
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final match in pattern.allMatches(message)) {
    if (match.start > cursor) spans.add(TextSpan(text: message.substring(cursor, match.start)));
    final tag = match.group(1)!;
    final text = match.group(2)!;
    spans.add(switch (tag) {
      'b' => TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.bold)),
      'i' => TextSpan(text: text, style: const TextStyle(fontStyle: FontStyle.italic)),
      _ => tags[tag]!(text),
    });
    cursor = match.end;
  }
  if (cursor < message.length) spans.add(TextSpan(text: message.substring(cursor)));
  return TextSpan(children: spans);
}
